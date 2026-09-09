# frozen_string_literal: true

# What this site is expected to publish — F01 AC-5, F02's exhaustiveness guard.
#
# These constants were constants of SiteTest until F01. They moved here because
# two builds now assert against them: the real checkout (tests/site_test.rb)
# and the overlay with fixture entries (tests/writing_surfaces_test.rb). The
# whole value of the cross-check is that both use the *same* union, so it must
# live in one place.

require "pathname"

module SiteInventory
  # Content pages: everything built from `pages/` through _layouts/default.html,
  # mapped to the page title.
  CONTENT_PAGES = {
    "/" => "Home",
    "/cv/" => "CV",
    "/made/" => "Made",
    "/essays/" => "Essays",
    "/log/" => "Log",
    "/contact/" => "Contact"
  }.freeze

  # The navigation, in order. Five items, not six: `/log/` is deliberately kept
  # out of the nav (requirements.md, decision 3) and is reached by a link from
  # `/essays/`.
  NAV_WORDS = %w[Home CV Made Essays Contact].freeze

  # Pages that must render exactly one current nav item.
  #
  # `/log/` is excluded because it has no nav item to mark current — it renders
  # the full five-word nav with none of them current. That is asserted
  # positively by test_log_has_no_nav_item_but_keeps_the_nav, so the state is
  # pinned rather than merely skipped here.
  NAV_CURRENT_PAGES = (CONTENT_PAGES.keys - ["/log/"]).freeze

  # Pages the build emits that are NOT content pages: `jekyll-redirect-from`
  # stubs, keyed by old URL with the path they point at.
  #
  # A stub is rendered from a template inside the gem, not from
  # `_layouts/default.html`, so it has no nav at all. That is why the nav
  # assertions run over CONTENT_PAGES and not over every built document — and
  # why this constant has to exist rather than the nav test simply skipping
  # pages that happen to lack a nav. A page must be *declared* a redirect to
  # escape the nav check; it cannot escape by being broken.
  REDIRECT_PAGES = { "/projects/" => "/made/" }.freeze

  # Collection source directories, mapped to their permalink prefix.
  COLLECTIONS = { "_log" => "/log/", "_essays" => "/essays/" }.freeze

  module_function

  # Every URL the site built from +source_root+ should publish.
  #
  #   static content pages ∪ declared redirects ∪ derived collection entries
  #
  # Entries are derived rather than listed so that writing an essay does not
  # turn the suite red. See tests/entry_inventory.rb for what that costs and
  # what the guard still catches.
  def expected_urls(source_root)
    root = Pathname.new(source_root)

    entries = COLLECTIONS.flat_map do |directory, prefix|
      EntryInventory.urls_for(root.join(directory), prefix)
    end

    CONTENT_PAGES.keys + REDIRECT_PAGES.keys + entries
  end
end
