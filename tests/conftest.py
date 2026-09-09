"""Shared fixtures — F03 AC-3.

The site is built **once per session** into a temporary directory. It is never
read from the committed `_site/`: stale output would let every assertion pass
while the real build was broken, which is exactly the failure the harness
exists to catch.
"""

from pathlib import Path

import pytest

from html_helpers import parse
from site_build import build_site

REPO_ROOT = Path(__file__).resolve().parent.parent


@pytest.fixture(scope="session")
def built_site(tmp_path_factory) -> Path:
    """Build the real site into a temporary directory and return that path."""
    destination = tmp_path_factory.mktemp("site")
    return build_site(REPO_ROOT, destination)


@pytest.fixture(scope="session")
def pages(built_site) -> dict[str, object]:
    """Every built page, parsed, keyed by its site-relative URL path.

    Keys look like "/", "/cv/", "/contact/". Keying by URL rather than by file
    path keeps the assertions readable and independent of the output layout.
    """
    documents = {}
    for html_file in sorted(built_site.rglob("index.html")):
        relative = html_file.parent.relative_to(built_site).as_posix()
        url = "/" if relative == "." else f"/{relative}/"
        documents[url] = parse(html_file.read_text())
    return documents
