# frozen_string_literal: true

# The real site, built with fixture entries added — F01 AC-1 … AC-4, AC-6.
#
# No log or essay entry is committed to this repository (plan decision D-1):
# placeholder writing on a personal site is content, and the author writes the
# real entries. But four acceptance criteria quantify over entries, so entries
# must exist somewhere for them to assert against.
#
# This helper copies the checkout into a temporary directory, drops the
# fixtures from tests/fixtures/writing_entries into `_log/` and `_essays/`, and
# builds. The real `_config.yml`, the real index pages and the real
# `_includes/navigation.html` are what run — only the entries are synthetic. A
# hand-written fixture site would have proved a copy of the configuration
# instead, and would drift from it silently.
#
# Built once per run, like BuiltSite.

require "fileutils"
require "pathname"
require "tmpdir"

module OverlaySite
  # Directories never copied into the overlay source.
  #
  # `.claude` matters more than it looks: in the main checkout it holds the
  # worktrees of features in progress, so copying it would copy a whole second
  # checkout — recursively.
  EXCLUDED = %w[vendor _site .git .jekyll-cache .bundle .claude node_modules].freeze

  # The collection directories the fixtures fill.
  OVERLAID = %w[_log _essays].freeze

  module_function

  def path
    @path ||= SiteBuilder.build(source, Dir.mktmpdir("jekyll-overlay-site"))
  end

  # Every built page, parsed, keyed by URL — the same shape as BuiltSite.pages.
  def pages
    @pages ||= Dir.glob(path.join("**", "index.html")).sort.to_h do |file|
      relative = Pathname.new(file).dirname.relative_path_from(path).to_s
      url = relative == "." ? "/" : "/#{relative}/"
      [url, Nokogiri::HTML5(File.read(file))]
    end
  end

  # The overlay's source directory: the checkout, plus the fixture entries.
  def source
    @source ||= begin
      root = Pathname.new(Dir.mktmpdir("jekyll-overlay-source"))

      REPO_ROOT.children.each do |child|
        next if EXCLUDED.include?(child.basename.to_s)

        FileUtils.cp_r(child, root)
      end

      OVERLAID.each do |collection|
        target = root.join(collection)
        target.mkpath
        FileUtils.cp_r(FIXTURES.join("writing_entries", collection).children, target)
      end

      root
    end
  end

  # The fixture entries, newest first — the order the indexes must produce.
  #
  # Read from the fixture files rather than restated here, so the expectation
  # cannot drift from the fixtures it describes. The unpublished entry is
  # excluded, and is deliberately the newest of all: an index that ignores
  # `published: false` puts it first, where it is impossible to miss.
  def entries_newest_first(collection)
    directory = FIXTURES.join("writing_entries", collection)

    directory.children.sort.filter_map do |file|
      front_matter = EntryInventory.front_matter_of(file)
      next if front_matter.nil? || front_matter["published"] == false

      { name: file.basename(file.extname).to_s,
        title: front_matter["title"],
        date: front_matter["date"] }
    end.sort_by { |entry| entry[:date] }.reverse
  end
end
