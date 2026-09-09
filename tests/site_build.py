"""Build the Jekyll site into a directory, and fail loudly when it does not.

F03 AC-1. Kept as a plain function taking a source directory rather than as
logic inside a pytest fixture, so that its failure path can be proven against
throwaway fixture trees without corrupting the real checkout.

Two conditions count as a failure, and the second one is the non-obvious one:

  * Jekyll exits non-zero — e.g. malformed ``_config.yml``.
  * Jekyll exits **zero** but produced no ``index.html``. Jekyll reports
    success when handed a source directory that does not exist. An exit-code
    check alone would call that a good build and return an empty directory.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

BUILD_TIMEOUT_SECONDS = 180


class BuildError(RuntimeError):
    """Raised when a Jekyll build fails, or succeeds without producing output.

    ``output`` holds Jekyll's combined stdout and stderr, so the cause is never
    lost. The message embeds it for the same reason.
    """

    def __init__(self, message: str, output: str) -> None:
        self.output = output
        super().__init__(f"{message}\n\n--- jekyll output ---\n{output}")


class ToolchainError(RuntimeError):
    """Raised when Jekyll itself cannot be run.

    Deliberately **not** a :class:`BuildError`. A missing toolchain is not a
    failed build, and conflating the two makes the suite lie: every test that
    expects a build to fail would pass without Jekyll ever running. Keeping
    this class separate means an absent toolchain turns the whole suite red
    with an accurate reason.
    """

    def __init__(self, output: str) -> None:
        self.output = output
        super().__init__(
            "cannot run `bundle exec jekyll` — the Ruby toolchain is missing "
            "or its gems are not installed. Run `bundle install`, or set "
            "BUNDLE_PATH to an existing gem directory."
            f"\n\n--- output ---\n{output}"
        )


def _primary_checkout() -> Path | None:
    """Locate the main checkout when running from a git worktree.

    A worktree contains only tracked files, so it has no ``vendor/bundle`` of
    its own. Worktrees share a common git directory, whose parent is the
    primary checkout — which usually does have the gems.
    """
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    common_dir = Path(result.stdout.strip())
    return common_dir.parent if common_dir.name == ".git" else None


def _vendored_gem_paths() -> list[Path]:
    """Gem directories to try, in order, when a bare ``bundle exec`` fails.

    ``.bundle/config`` is empty in this project, so a bare ``bundle exec`` can
    fail with "command not found: jekyll" even though the gems are unpacked
    under ``vendor/bundle``. This is a local-checkout convenience only: CI
    installs gems through ``bundler-cache: true``, has no ``vendor/bundle``,
    and never reaches this code because its first attempt succeeds.
    """
    candidates = [REPO_ROOT / "vendor" / "bundle"]
    primary = _primary_checkout()
    if primary is not None and primary != REPO_ROOT:
        candidates.append(primary / "vendor" / "bundle")
    return [path for path in candidates if path.is_dir()]


def _is_missing_toolchain(result) -> bool:
    """True when the runner could not find bundler or jekyll at all."""
    combined = f"{result.stdout}{result.stderr}"
    return result.returncode == 127 or "command not found" in combined


def _run(source_dir: Path, dest_dir: Path, env: dict[str, str]):
    return subprocess.run(
        [
            "bundle", "exec", "jekyll", "build",
            "--source", str(source_dir),
            "--destination", str(dest_dir),
            # Matches .github/workflows/jekyll.yml: the site serves at the root
            # of a custom domain, so a non-empty baseurl breaks asset URLs.
            "--baseurl", "",
        ],
        cwd=REPO_ROOT,
        env=env,
        capture_output=True,
        text=True,
        timeout=BUILD_TIMEOUT_SECONDS,
    )


def build_site(source_dir: os.PathLike | str, dest_dir: os.PathLike | str) -> Path:
    """Build ``source_dir`` into ``dest_dir`` and return ``dest_dir``.

    Raises :class:`BuildError` on a failed build, or on a build that reports
    success while producing nothing. Never returns an empty destination.
    """
    source_dir = Path(source_dir)
    dest_dir = Path(dest_dir)
    dest_dir.mkdir(parents=True, exist_ok=True)

    env = os.environ.copy()
    result = _run(source_dir, dest_dir, env)

    # Retry with the vendored gems, but only if the caller has not already
    # chosen a BUNDLE_PATH and only if a candidate directory actually exists.
    if result.returncode != 0 and "BUNDLE_PATH" not in os.environ:
        for vendored in _vendored_gem_paths():
            env["BUNDLE_PATH"] = str(vendored)
            result = _run(source_dir, dest_dir, env)
            if result.returncode == 0:
                break

    output = f"{result.stdout}{result.stderr}"

    # Checked before BuildError: an absent toolchain is not a failed build, and
    # reporting it as one would let every "raises" test pass without Jekyll.
    if _is_missing_toolchain(result):
        raise ToolchainError(output)

    if result.returncode != 0:
        raise BuildError(
            f"jekyll build failed (exit {result.returncode}) "
            f"for source {source_dir}",
            output,
        )

    if not any(dest_dir.rglob("index.html")):
        raise BuildError(
            f"jekyll build reported success but produced no index.html "
            f"for source {source_dir}. Jekyll exits 0 when the source "
            f"directory does not exist — check that {source_dir} is real.",
            output,
        )

    return dest_dir
