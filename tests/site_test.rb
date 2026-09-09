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
    "/projects/" => "Projects",
    "/contact/" => "Contact"
  }.freeze

  EXPECTED_NAV_WORDS = %w[Home CV Projects Contact].freeze

  AUTHOR = "Kester Stefan"

  def pages
    BuiltSite.pages
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

  def test_nav_words_on_every_page
    pages.each do |url, document|
      assert_equal EXPECTED_NAV_WORDS, nav_words(document), "nav differs on #{url}"
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
