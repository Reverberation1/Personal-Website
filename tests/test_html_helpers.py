"""Tests for the standard-library HTML helper — F03 AC-2.

Written before `html_helpers.py` exists. This is the red step.

Every assertion here runs against one fixed HTML string. There is no site
build and no file I/O, so a failure can only mean the helper is wrong. The
fragment deliberately mirrors the real navigation markup — nested spans inside
an anchor, plus a `data-text` attribute — because that nesting is what a naive
parser gets wrong.
"""

import ast
import sys
from pathlib import Path

from html_helpers import parse

HELPER_SOURCE = Path(__file__).resolve().parent / "html_helpers.py"

SAMPLE = """
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head><title>Kester Stefan — CV</title></head>
<body>
  <nav class="nav">
    <a href="/" class="nav-link" data-text="Home"><span
       class="nav-link-bracket">[</span><span
       class="nav-link-word">Home</span><span
       class="nav-link-bracket">]</span></a>
    <span class="nav-link nav-link-current" data-text="CV" aria-current="page"><span
       class="nav-link-bracket">[</span><span
       class="nav-link-word">CV</span><span
       class="nav-link-bracket">]</span></span>
    <a href="/contact/" class="nav-link" data-text="Contact"><span
       class="nav-link-word">Contact</span></a>
  </nav>
  <main class="main">
    <h1 class="name">Kester Stefan</h1>
    <a href="https://example.com">External</a>
  </main>
</body>
</html>
"""


def test_title_extracted():
    assert parse(SAMPLE).title() == "Kester Stefan — CV"


def test_title_is_none_when_absent():
    assert parse("<html><body><p>no title</p></body></html>").title() is None


def test_links_in_document_order():
    """Order matters: the nav contract is about sequence, not membership."""
    links = parse(SAMPLE).links()

    assert [href for href, _ in links] == ["/", "/contact/", "https://example.com"]
    # "[Home]" carries its bracket spans; the Contact link in SAMPLE has only
    # the word span, which is what makes this a test of nesting and not of
    # string equality.
    assert [text for _, text in links] == ["[Home]", "Contact", "External"]


def test_select_by_tag_and_class():
    """The word spans are what the scramble animation targets."""
    words = parse(SAMPLE).select("span", "nav-link-word")

    assert [element.text for element in words] == ["Home", "CV", "Contact"]


def test_select_matches_one_class_among_several():
    """`class="nav-link nav-link-current"` must match on either name."""
    current = parse(SAMPLE).select("span", "nav-link-current")

    assert len(current) == 1
    assert current[0].attrs["data-text"] == "CV"


def test_select_returns_empty_for_no_match():
    assert parse(SAMPLE).select("span", "does-not-exist") == []


def test_no_third_party_imports():
    """AC-2 requires the helper to use the standard library only.

    Parsed with `ast` rather than matched with a regex over the source text.
    A regex would pass while broken — and this is a test about not parsing
    structured text with regexes.
    """
    tree = ast.parse(HELPER_SOURCE.read_text())
    imported: set[str] = set()

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            imported.update(alias.name.split(".")[0] for alias in node.names)
        elif isinstance(node, ast.ImportFrom):
            if node.level == 0 and node.module:
                imported.add(node.module.split(".")[0])

    non_stdlib = imported - sys.stdlib_module_names
    assert not non_stdlib, f"helper imports non-stdlib modules: {sorted(non_stdlib)}"
