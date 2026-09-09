# frozen_string_literal: true

# The log and essay collections — F01 AC-1 … AC-4.
#
# Every test here runs against the overlay build: the real repository with
# fixture entries added (tests/overlay_site.rb explains why).

require_relative "test_helper"

class WritingSurfacesTest < Minitest::Test
  include PageAssertions

  def pages
    OverlaySite.pages
  end

  # AC-1: a source file in _log/ produces exactly one page, carrying its body.
  #
  # The body assertion is the point. A permalink check alone passes on an empty
  # page, which is the most likely way this breaks.
  def test_log_entry_builds_at_its_permalink
    OverlaySite.entries_newest_first("_log").each do |entry|
      document = pages["/log/#{entry[:name]}/"]
      refute_nil document, "/log/#{entry[:name]}/ was not built"

      assert_includes document.css("main.main").text,
                      "The #{entry[:name]} note body sentence.",
                      "the entry body did not reach the page"
    end
  end

  # AC-1: the entry is a page of this site, not a bare Markdown dump.
  def test_log_entry_carries_the_site_layout
    document = pages["/log/alpha/"]

    assert_equal "Kester Stefan — Alpha note", document.title
    refute_empty document.css("nav.nav"), "the entry has no navigation"
  end

  # AC-3: the same two properties for essays.
  def test_essay_builds_at_its_permalink
    OverlaySite.entries_newest_first("_essays").each do |entry|
      document = pages["/essays/#{entry[:name]}/"]
      refute_nil document, "/essays/#{entry[:name]}/ was not built"

      assert_includes document.css("main.main").text,
                      "The #{entry[:name]} essay body sentence.",
                      "the essay body did not reach the page"
    end
  end

  def test_essay_carries_the_site_layout
    document = pages["/essays/echo/"]

    assert_equal "Kester Stefan — Echo essay", document.title
    refute_empty document.css("nav.nav"), "the essay has no navigation"
  end

  # AC-2: the log index lists every published entry, newest first.
  #
  # Document order is asserted, not set membership: an index that lists the
  # right three entries in the wrong order is broken. The fixture dates are
  # chosen so the expected order (bravo, alpha, charlie) is neither
  # alphabetical nor reverse-alphabetical by filename — so deleting
  # `sort: 'date'` from the template cannot pass by coincidence.
  def test_log_index_lists_entries_newest_first
    expected = OverlaySite.entries_newest_first("_log")
                          .map { |entry| "/log/#{entry[:name]}/" }

    assert_equal expected, index_hrefs("/log/")
  end

  # AC-2: an unpublished entry is absent from the index AND unbuilt.
  #
  # Both halves matter. An entry hidden from the index but live at its URL is
  # still published, and that state must fail.
  def test_unpublished_log_entry_is_absent
    refute_includes pages["/log/"].text, "Unpublished note",
                    "an unpublished entry appears in the index"
    assert_nil pages["/log/unpublished-note/"],
               "an unpublished entry was built at its URL"
  end

  # AC-4: the same ordering rule for essays.
  def test_essays_index_lists_entries_newest_first
    expected = OverlaySite.entries_newest_first("_essays")
                          .map { |entry| "/essays/#{entry[:name]}/" }

    assert_equal expected, index_hrefs("/essays/")
  end

  # AC-4: each row shows the essay's title and its date.
  def test_essays_index_row_shows_title_and_date
    rows = pages["/essays/"].css("li.entry-row")

    assert_equal 3, rows.length, "expected one row per published essay"

    OverlaySite.entries_newest_first("_essays").each_with_index do |entry, index|
      text = rows[index].text

      assert_includes text, entry[:title]
      assert_includes text, entry[:date].strftime("%Y-%m-%d")
    end
  end

  def test_unpublished_essay_is_absent
    refute_includes pages["/essays/"].text, "Unpublished essay",
                    "an unpublished essay appears in the index"
    assert_nil pages["/essays/unpublished-essay/"],
               "an unpublished essay was built at its URL"
  end

  # AC-6, the half that cannot be proven on the real build: with entries
  # present, the empty state is gone and the rows are there.
  #
  # Without this, an index that always shows "nothing published yet" would pass
  # the other half of AC-6 — the worst version of this feature.
  def test_populated_indexes_have_no_empty_state
    %w[/log/ /essays/].each do |url|
      assert_empty pages[url].css("p.empty-state"),
                   "#{url} shows the empty state while entries exist"
      assert_equal 3, pages[url].css("li.entry-row").length,
                   "#{url} does not list its three entries"
    end
  end

  # AC-5, plan decision D-2: the derived inventory agrees with what Jekyll
  # actually emits.
  #
  # The same union guards the real build, but no entry is committed there, so
  # the derivation runs over empty directories and proves nothing about its
  # permalink mapping. Here entries genuinely exist. A wrong prefix, a wrong
  # slug, or an unpublished entry counted is red.
  def test_overlay_page_inventory_matches_the_derivation
    expected = SiteInventory.expected_urls(OverlaySite.source)

    assert_equal expected.sort, pages.keys.sort,
                 "the overlay build does not match the derived inventory"
  end

  private

  # The hrefs of an index's entry links, in document order.
  def index_hrefs(url)
    pages[url].css("li.entry-row a.entry-link").map { |node| node["href"] }
  end
end
