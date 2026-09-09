# frozen_string_literal: true

# Smoke tests over the real built site — F03 AC-3 and AC-4, F02, F01 AC-5/AC-6.
#
# These run against a fresh build in a temporary directory, never the committed
# `_site/`. They pin the site's shape as it is today, so a later feature that
# changes that shape has to change these tests deliberately rather than by
# accident.
#
# The page inventory and the nav contract moved to tests/site_inventory.rb in
# F01, because the overlay build asserts against the same union — see
# tests/writing_surfaces_test.rb.
#
# This file builds the repository **as committed**, which carries no log or
# essay entries (plan decision D-1). That is what makes it the right place for
# the empty-state assertions.

require_relative "test_helper"

class SiteTest < Minitest::Test
  include PageAssertions

  CONTENT_PAGES = SiteInventory::CONTENT_PAGES
  NAV_CURRENT_PAGES = SiteInventory::NAV_CURRENT_PAGES
  NAV_WORDS = SiteInventory::NAV_WORDS

  AUTHOR = "Kester Stefan"

  def pages
    BuiltSite.pages
  end

  # Nothing is built that is not either a content page, a declared redirect, or
  # a published collection entry.
  #
  # This is the guard that keeps the rescoped nav test honest: without it, a
  # page could drop out of the nav assertions by losing its layout, and the
  # suite would stay green while the site broke.
  #
  # F01 changed the entry half of that union from a literal list to a
  # derivation over `_log/` and `_essays/`, so writing an essay does not turn
  # the suite red. What the guard still catches, and what it gives up, is
  # argued in tests/entry_inventory.rb.
  def test_built_site_contains_no_unexpected_pages
    expected = SiteInventory.expected_urls(REPO_ROOT).sort

    assert_equal expected, pages.keys.sort,
                 "the built site does not match the declared page inventory"
  end

  def test_every_content_page_builds
    CONTENT_PAGES.each_key do |url|
      assert pages.key?(url), "#{url} was not built"
    end
  end

  # Titles follow `{{ site.author }} — {{ page.title }}`.
  #
  # The home page is NOT an exception. _layouts/default.html falls back to the
  # author alone only when a page sets no `title`, and pages/home.md does set
  # one, so that branch is dead code today. A note in CLAUDE.md claimed the home
  # page shows the author alone; this test records what the build produces.
  def test_titles_are_author_based
    CONTENT_PAGES.each do |url, title|
      assert_equal "#{AUTHOR} — #{title}", pages[url].title
    end
  end

  # Every content page, not every built page — see SiteInventory::REDIRECT_PAGES.
  def test_nav_words_on_every_page
    CONTENT_PAGES.each_key do |url|
      assert_equal NAV_WORDS, nav_words(pages[url]), "nav differs on #{url}"
    end
  end

  # Scoped to NAV_CURRENT_PAGES, which excludes `/log/`.
  #
  # `/log/` has no nav item to mark current (requirements.md, decision 3), so it
  # renders zero of them and would fail a count of exactly one. That zero is not
  # skipped: test_log_has_no_nav_item_but_keeps_the_nav asserts it.
  def test_current_page_is_not_a_link
    NAV_CURRENT_PAGES.each do |url|
      document = pages[url]
      current = document.css("span.nav-link-current")

      assert_equal 1, current.length, "expected one current nav item on #{url}"
      assert_equal "page", current.first["aria-current"]
      refute_includes nav_links(document).map(&:first), url,
                      "#{url} links to itself in the nav"
    end
  end

  # F01 AC-5: the Essays item marks itself current, and does not also link.
  #
  # Asserting the span alone would pass on a page that rendered both a span and
  # a link, so the absence of the self-link is asserted too.
  def test_essays_is_current_on_the_essays_page
    document = pages["/essays/"]
    current = document.css("span.nav-link.nav-link-current")

    assert_equal 1, current.length
    assert_equal "Essays", current.first.css("span.nav-link-word").text.strip
    assert_equal "page", current.first["aria-current"]
    refute_includes nav_links(document).map(&:first), "/essays/",
                    "/essays/ links to itself in the nav"
  end

  # F01 AC-5: `/log/` is deliberately absent from the nav — and keeps the nav.
  #
  # This is the test that makes decision 3 falsifiable in both directions. It
  # fails if `/log/` gains a nav item, and it fails if `/log/` loses the nav bar
  # altogether, which is the other way "not in the nav" could be implemented.
  def test_log_has_no_nav_item_but_keeps_the_nav
    document = pages["/log/"]

    assert_equal NAV_WORDS, nav_words(document), "/log/ lost the navigation"
    assert_empty document.css("span.nav-link-current"),
                 "/log/ has a current nav item, but it has no nav item at all"
    refute_includes nav_links(document).map(&:first), "/log/",
                    "/log/ has gained a nav link"
  end

  # F01 AC-5: `/log/` is reachable, because `/essays/` links to it.
  #
  # Scoped outside the nav on purpose: a link in the nav would satisfy a naive
  # "contains /log/" check while breaking the five-item nav the author chose.
  def test_essays_index_links_to_log
    hrefs = pages["/essays/"].css("main.main a[href]").map { |node| node["href"] }

    assert_includes hrefs, "/log/", "/essays/ does not link to the log"
  end

  # F01 AC-6: with no entries committed, each index says so.
  #
  # The other half of this criterion — that the message disappears once entries
  # exist — cannot be proven here, because this build has no entries. It is
  # asserted on the overlay by test_populated_indexes_have_no_empty_state.
  def test_empty_log_index_shows_the_empty_state
    assert_empty_index pages["/log/"]
  end

  def test_empty_essays_index_shows_the_empty_state
    assert_empty_index pages["/essays/"]
  end

  # scramble.js selects on `data-text` plus an inner `.nav-link-word`.
  def test_every_nav_item_keeps_the_scramble_contract
    items = pages["/cv/"].css("nav.nav > a.nav-link, nav.nav > span.nav-link")

    assert_equal NAV_WORDS.length, items.length
    items.each do |item|
      refute_nil item["data-text"], "nav item is missing data-text"
      refute_empty item.css("span.nav-link-word"),
                   "nav item is missing its .nav-link-word span"
    end
  end

  # F02 AC-1: the page moved to /made/, and it took its content with it.
  #
  # The content assertions are the point. A rename that produced an empty
  # /made/ would satisfy a URL check and lose the page.
  def test_made_page_is_served_at_made
    document = pages["/made/"]
    refute_nil document, "/made/ was not built"

    assert_equal "#{AUTHOR} — Made", document.title
    assert_equal "Made", document.css("main.main > h1").first.text.strip

    highlights = document.css(".quote-highlight").map { |node| node.text }
    assert highlights.any? { |text| text.include?("Paperless") },
           "the Paperless entry did not survive the move"
    assert highlights.any? { |text| text.include?("Resonate") },
           "the Resonate entry did not survive the move"
    refute_empty document.css(".cv-date"), "the .cv-date markup was lost"
  end

  # F02 AC-2: the old URL still resolves, and resolves to the right place.
  #
  # Asserting only that /projects/ exists would pass on a stub pointing
  # anywhere at all, so the target is what is asserted. "Ends with" rather than
  # equality because jekyll-redirect-from composes an absolute URL from
  # site.url — verified during the T-2a spike as
  # `https://kester.world/made/`, not a root-relative path.
  def test_projects_redirects_to_made
    document = pages["/projects/"]
    refute_nil document, "/projects/ was not built"

    refresh = document.css('meta[http-equiv="refresh"]').first
    refute_nil refresh, "the redirect stub has no meta refresh"
    target = refresh["content"].to_s.split("url=", 2).last.to_s.strip
    assert target.end_with?("/made/"),
           "refresh target #{target.inspect} does not end in /made/"

    canonical = document.css('link[rel="canonical"]').first
    refute_nil canonical, "the redirect stub has no canonical link"
    assert canonical["href"].to_s.end_with?("/made/"),
           "canonical #{canonical['href'].inspect} does not end in /made/"
  end

  # F02 AC-3: no nav item points at the old URL.
  #
  # Scoped to the nav on purpose. The redirect stub names /projects/ in its own
  # canonical href, legitimately, so a site-wide string check would fail on the
  # feature working.
  def test_no_content_page_links_to_projects
    CONTENT_PAGES.each_key do |url|
      hrefs = pages[url].css("nav.nav a[href]").map { |node| node["href"] }
      refute hrefs.any? { |href| href.end_with?("/projects/") },
             "#{url} still has a nav link to /projects/"
    end
  end

  # AC-4: the harness must not publish itself.
  #
  # `tests` starts with neither `_` nor `.`, and its files carry no front
  # matter, so without the `exclude:` entry in _config.yml Jekyll copies the
  # whole directory verbatim into the output.
  def test_harness_files_absent_from_build
    refute BuiltSite.path.join("tests").exist?, "tests/ leaked into the build"
    assert_empty Dir.glob(BuiltSite.path.join("**", "*.rb")),
                 "Ruby files leaked into the build"
    # The Rakefile has no extension and no front matter, so it is copied
    # verbatim unless excluded. It did leak, before the exclude entry existed.
    refute BuiltSite.path.join("Rakefile").exist?, "Rakefile leaked into the build"
  end

  private

  def assert_empty_index(document)
    empty_state = document.css("p.empty-state")

    assert_equal 1, empty_state.length, "expected one empty-state message"
    refute_empty empty_state.text.strip, "the empty-state message has no text"
    assert_empty document.css("li.entry-row"),
                 "an index with no entries listed rows"
  end
end
