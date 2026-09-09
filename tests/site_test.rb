# frozen_string_literal: true

# Smoke tests over the real built site — F03 AC-3 and AC-4.
#
# These run against a fresh build in a temporary directory, never the committed
# `_site/`. They pin the site's shape as it is today, so a later feature that
# changes that shape has to change these tests deliberately rather than by
# accident. F02 will rename Projects to Made and must update EXPECTED_PAGES and
# EXPECTED_NAV_WORDS here — that edit is the signal the harness is doing its
# job, not a regression.

require_relative "test_helper"

class SiteTest < Minitest::Test
  include PageAssertions

  EXPECTED_PAGES = {
    "/" => "Home",
    "/cv/" => "CV",
    "/made/" => "Made",
    "/contact/" => "Contact"
  }.freeze

  EXPECTED_NAV_WORDS = %w[Home CV Made Contact].freeze

  # Pages the build emits that are NOT content pages: `jekyll-redirect-from`
  # stubs, keyed by old URL with the path they point at.
  #
  # A stub is rendered from a template inside the gem, not from
  # `_layouts/default.html`, so it has no nav at all. That is why the nav
  # assertions below run over EXPECTED_PAGES and not over every built document
  # — and why this constant has to exist rather than the nav test simply
  # skipping pages that happen to lack a nav. A page must be *declared* a
  # redirect to escape the nav check; it cannot escape by being broken.
  #
  REDIRECT_PAGES = { "/projects/" => "/made/" }.freeze

  AUTHOR = "Kester Stefan"

  def pages
    BuiltSite.pages
  end

  # Nothing is built that is not either a content page or a declared redirect.
  #
  # This is the guard that keeps the rescoped nav test honest: without it, a
  # page could drop out of the nav assertions by losing its layout, and the
  # suite would stay green while the site broke.
  def test_built_site_contains_no_unexpected_pages
    expected = (EXPECTED_PAGES.keys + REDIRECT_PAGES.keys).sort

    assert_equal expected, pages.keys.sort,
                 "the built site does not match the declared page inventory"
  end

  def test_all_four_pages_build
    EXPECTED_PAGES.each_key do |url|
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
    EXPECTED_PAGES.each do |url, title|
      assert_equal "#{AUTHOR} — #{title}", pages[url].title
    end
  end

  # Every content page, not every built page — see REDIRECT_PAGES.
  def test_nav_words_on_every_page
    EXPECTED_PAGES.each_key do |url|
      assert_equal EXPECTED_NAV_WORDS, nav_words(pages[url]), "nav differs on #{url}"
    end
  end

  def test_current_page_is_not_a_link
    EXPECTED_PAGES.each_key do |url|
      document = pages[url]
      current = document.css("span.nav-link-current")

      assert_equal 1, current.length, "expected one current nav item on #{url}"
      assert_equal "page", current.first["aria-current"]
      refute_includes links(document).map(&:first), url,
                      "#{url} links to itself in the nav"
    end
  end

  # scramble.js selects on `data-text` plus an inner `.nav-link-word`.
  def test_every_nav_item_keeps_the_scramble_contract
    items = pages["/cv/"].css("nav.nav > a.nav-link, nav.nav > span.nav-link")

    assert_equal EXPECTED_NAV_WORDS.length, items.length
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
    EXPECTED_PAGES.each_key do |url|
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
end
