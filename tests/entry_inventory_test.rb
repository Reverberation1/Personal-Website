# frozen_string_literal: true

# Tests for the entry-URL derivation — F01 AC-5, plan decision D-2.
#
# `test_built_site_contains_no_unexpected_pages` pins the exhaustive set of
# built pages. Listing collection entries there literally would turn the suite
# red every time the author writes an essay, so the expected set derives entry
# URLs from the source directories instead. That derivation is the one piece of
# the guard that is not itself checked by the guard, which is why it is a plain
# function with its own tests rather than a block of Ruby inside the assertion.

require_relative "test_helper"

class EntryInventoryTest < Minitest::Test
  LOG_FIXTURES = FIXTURES.join("writing_entries", "_log")
  ESSAY_FIXTURES = FIXTURES.join("writing_entries", "_essays")

  def test_urls_are_derived_from_filenames
    assert_equal ["/log/alpha/", "/log/bravo/", "/log/charlie/"],
                 EntryInventory.urls_for(LOG_FIXTURES, "/log/").sort
  end

  # The unpublished fixture is dated newest, so a derivation that ignores
  # `published: false` cannot hide behind an ordering coincidence.
  def test_unpublished_entries_are_excluded
    urls = EntryInventory.urls_for(LOG_FIXTURES, "/log/")

    refute_includes urls, "/log/unpublished-note/",
                    "an unpublished entry was counted as a built page"
  end

  # A missing directory is the normal state of this repository: no entry is
  # committed (plan decision D-1), so `_log/` may hold nothing but `.gitkeep`.
  # Returning [] rather than raising is what lets the guard run on the real
  # build.
  def test_missing_directory_yields_no_urls
    assert_empty EntryInventory.urls_for(FIXTURES.join("no_such_dir"), "/log/")
  end

  def test_prefix_is_honoured
    assert_equal ["/essays/delta/", "/essays/echo/", "/essays/foxtrot/"],
                 EntryInventory.urls_for(ESSAY_FIXTURES, "/essays/").sort
  end
end
