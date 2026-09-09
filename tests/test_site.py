"""Smoke tests over the real built site — F03 AC-3 and AC-4.

These run against a fresh build in a temporary directory, never the committed
`_site/`. They pin the site's shape as it is today, so a later feature that
changes that shape has to change these tests deliberately rather than by
accident. F02 will rename Projects to Made and must update
`EXPECTED_NAV_WORDS` and `EXPECTED_PAGES` here — that edit is the signal the
harness is doing its job.
"""

EXPECTED_PAGES = {
    "/": "Home",
    "/cv/": "CV",
    "/projects/": "Projects",
    "/contact/": "Contact",
}

EXPECTED_NAV_WORDS = ["Home", "CV", "Projects", "DELIBERATELY-WRONG"]

AUTHOR = "Kester Stefan"


def test_all_four_pages_build(pages):
    """Every content page exists in the build output."""
    for url in EXPECTED_PAGES:
        assert url in pages, f"{url} was not built"


def test_titles_are_author_based(pages):
    """Titles follow `{{ site.author }} — {{ page.title }}`.

    Note: the home page is **not** an exception. `_layouts/default.html` falls
    back to the author alone only when a page sets no `title`, and
    `pages/home.md` does set one. The fallback branch is therefore dead code
    today. A note in CLAUDE.md claimed the home page shows the author alone;
    this test records what the build actually produces.
    """
    for url, title in EXPECTED_PAGES.items():
        assert pages[url].title() == f"{AUTHOR} — {title}"


def test_nav_words_on_every_page(pages):
    """Every page carries the same nav, in the same order.

    Selects the `.nav-link-word` spans rather than the links, because the
    current page renders as a `<span>` and would be missing from a link list.
    That span is also what the scramble animation targets, so this assertion
    doubles as a guard on the animation's class contract.
    """
    for url, document in pages.items():
        words = [element.text for element in document.select("span", "nav-link-word")]
        assert words == EXPECTED_NAV_WORDS, f"nav differs on {url}"


def test_current_page_is_not_a_link(pages):
    """The active nav item is a `<span>`, marked `aria-current`."""
    for url in EXPECTED_PAGES:
        document = pages[url]
        current = document.select("span", "nav-link-current")

        assert len(current) == 1, f"expected exactly one current nav item on {url}"
        assert current[0].attrs.get("aria-current") == "page"
        assert url not in [href for href, _ in document.links()], (
            f"{url} links to itself in the nav"
        )


def test_every_nav_item_keeps_the_scramble_contract(pages):
    """`scramble.js` selects on `data-text` plus an inner `.nav-link-word`."""
    document = pages["/cv/"]
    items = document.select("a", "nav-link") + document.select("span", "nav-link")

    assert len(items) == len(EXPECTED_NAV_WORDS)
    for item in items:
        assert item.attrs.get("data-text"), "nav item is missing data-text"
        assert any(
            "nav-link-word" in child.classes
            for child in item.iter_descendants()
        ), "nav item is missing its .nav-link-word span"


def test_tests_dir_absent_from_build(built_site):
    """AC-4: the harness must not publish itself.

    `tests` starts with neither `_` nor `.`, and its files carry no front
    matter, so without the `exclude:` entry in `_config.yml` Jekyll copies the
    whole directory verbatim into the output.
    """
    assert not (built_site / "tests").exists(), "tests/ leaked into the build"
    assert not list(built_site.rglob("*.py")), "Python files leaked into the build"
