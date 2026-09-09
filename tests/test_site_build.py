"""Tests for the Jekyll build helper — F03 AC-1.

Written before `site_build.py` exists. This is the red step.

The two failure tests are not symmetric, and that asymmetry is the point:

  * a malformed `_config.yml` makes Jekyll exit **non-zero**;
  * a **missing source directory** makes Jekyll exit **zero** and write nothing.

A build helper that only checked the exit code would treat the second case as a
successful build and hand back an empty directory. Every later assertion would
then fail with a confusing "file not found" rather than "the build produced
nothing". Both directions are pinned here.
"""

import subprocess
from pathlib import Path

import pytest

import site_build
from site_build import BuildError, ToolchainError, build_site

FIXTURES = Path(__file__).resolve().parent / "fixtures"


def test_build_site_produces_output(tmp_path):
    """A valid source tree builds and yields a populated destination."""
    dest = build_site(FIXTURES / "minimal_site", tmp_path / "out")

    assert (dest / "index.html").is_file()
    assert (dest / "index.html").read_text().strip(), "index.html is empty"


def test_build_site_raises_on_malformed_config(tmp_path):
    """A non-zero Jekyll exit is a build failure, never a silent pass."""
    with pytest.raises(BuildError):
        build_site(FIXTURES / "broken_config", tmp_path / "out")


def test_build_site_raises_on_missing_source(tmp_path):
    """Jekyll exits 0 here and writes nothing. That is still a failure.

    This is the test that stops `build_site` from being an exit-code check.
    """
    with pytest.raises(BuildError):
        build_site(tmp_path / "does_not_exist", tmp_path / "out")


def test_build_error_carries_jekyll_output(tmp_path):
    """The raised error must say what Jekyll said, or it hides the cause."""
    with pytest.raises(BuildError) as excinfo:
        build_site(FIXTURES / "broken_config", tmp_path / "out")

    message = str(excinfo.value)
    assert "_config.yml" in message, "Jekyll's own diagnostic was swallowed"
    assert excinfo.value.output.strip(), "captured build output is empty"


def test_missing_toolchain_is_not_a_build_error(tmp_path, monkeypatch):
    """An absent Jekyll must not masquerade as a failed build.

    This is the guard that keeps the rest of the suite honest. Without it, a
    checkout with no gems installed makes every "raises BuildError" test pass
    while Jekyll never runs once — the tests would be green and prove nothing.
    Discovered for real: a fresh git worktree holds only tracked files, so it
    has no `vendor/bundle` and `bundle exec jekyll` exits 127 there.
    """
    def fake_run(source_dir, dest_dir, env):
        return subprocess.CompletedProcess(
            args=["bundle"],
            returncode=127,
            stdout="",
            stderr="bundler: command not found: jekyll\n",
        )

    monkeypatch.setattr(site_build, "_run", fake_run)

    with pytest.raises(ToolchainError):
        build_site(FIXTURES / "minimal_site", tmp_path / "out")

    assert not issubclass(ToolchainError, BuildError)
