"""A small HTML query helper built on the standard library — F03 AC-2.

`beautifulsoup4` is not installed, and installing a package needs the author's
approval. For a four-page site the ergonomic gain does not justify adding a
Python dependency to a Ruby repository, so this uses `html.parser`.

Scope is deliberately narrow: page title, links in document order, and elements
selected by tag plus CSS class. That is everything the site's acceptance
criteria assert. Resist growing this into a general-purpose DOM library — if a
future feature genuinely needs one, add the dependency instead.
"""

from __future__ import annotations

from html.parser import HTMLParser

# Tags that never have a closing tag. Without this list the parser treats the
# rest of the document as nested inside them and every ancestry test breaks.
VOID_TAGS = frozenset(
    {
        "area", "base", "br", "col", "embed", "hr", "img", "input",
        "link", "meta", "param", "source", "track", "wbr",
    }
)


class Element:
    """One HTML element, with its attributes and its descendant text."""

    def __init__(self, tag: str, attrs: dict[str, str]) -> None:
        self.tag = tag
        self.attrs = attrs
        self.children: list[Element] = []
        self._text_parts: list[str] = []

    @property
    def classes(self) -> list[str]:
        return self.attrs.get("class", "").split()

    @property
    def text(self) -> str:
        """All descendant text, whitespace-collapsed.

        Collapsing matters: the real navigation markup breaks attributes across
        lines, so raw text is full of newlines and indentation that no
        assertion should have to know about.
        """
        parts = list(self._text_parts)
        for child in self.children:
            parts.append(child.text)
        return " ".join("".join(parts).split())

    def iter_descendants(self):
        for child in self.children:
            yield child
            yield from child.iter_descendants()


class Document:
    """A parsed HTML document. Build one with :func:`parse`."""

    def __init__(self, root: Element) -> None:
        self.root = root

    def title(self) -> str | None:
        """The `<title>` text, or None when the document has no title."""
        for element in self.root.iter_descendants():
            if element.tag == "title":
                return element.text
        return None

    def links(self) -> list[tuple[str, str]]:
        """Every `<a href=...>` as `(href, text)`, in document order."""
        return [
            (element.attrs["href"], element.text)
            for element in self.root.iter_descendants()
            if element.tag == "a" and "href" in element.attrs
        ]

    def select(self, tag: str, css_class: str) -> list[Element]:
        """Elements matching a tag and carrying a CSS class, in order.

        The class check is against the split class list, not a substring of the
        attribute, so `class="nav-link nav-link-current"` matches either name
        and `nav-link` does not match `nav-link-word`.
        """
        return [
            element
            for element in self.root.iter_descendants()
            if element.tag == tag and css_class in element.classes
        ]


class _TreeBuilder(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.root = Element("#document", {})
        self._stack = [self.root]

    def handle_starttag(self, tag, attrs):
        element = Element(tag, {key: value or "" for key, value in attrs})
        self._stack[-1].children.append(element)
        if tag not in VOID_TAGS:
            self._stack.append(element)

    def handle_startendtag(self, tag, attrs):
        element = Element(tag, {key: value or "" for key, value in attrs})
        self._stack[-1].children.append(element)

    def handle_endtag(self, tag):
        # Walk back to the matching open tag. Unbalanced markup is ignored
        # rather than raising: a real page must never crash the assertions.
        for index in range(len(self._stack) - 1, 0, -1):
            if self._stack[index].tag == tag:
                del self._stack[index:]
                return

    def handle_data(self, data):
        self._stack[-1]._text_parts.append(data)


def parse(html_text: str) -> Document:
    """Parse HTML text into a queryable :class:`Document`."""
    builder = _TreeBuilder()
    builder.feed(html_text)
    builder.close()
    return Document(builder.root)
