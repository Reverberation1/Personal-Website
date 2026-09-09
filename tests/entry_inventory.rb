# frozen_string_literal: true

# Derive the URLs a collection's source files will be published at — F01 AC-5.
#
# This exists to keep `test_built_site_contains_no_unexpected_pages` useful.
# That guard pins the exhaustive set of built pages, which is what stops a page
# escaping the nav assertions by losing its layout. Written as a literal list it
# would also go red every time the author writes an essay — a guard that
# punishes the site's whole purpose. So the expected set is
#
#   static pages ∪ declared redirects ∪ urls_for(_log/) ∪ urls_for(_essays/)
#
# and the guard keeps its teeth where they matter: an entry whose page fails to
# build is still red, and a page that no source file explains is still red.
#
# The rules below mirror Jekyll's own, and each one is pinned by a test:
#   * a file with no YAML front matter is a static file, not a document;
#   * `published: false` produces no page at all (confirmed by spike, not
#     assumed — see plan.md, Risks);
#   * the output path comes from the filename, per the `/log/:name/` permalink.

require "pathname"
require "yaml"

module EntryInventory
  ENTRY_EXTENSIONS = %w[.md .markdown].freeze

  module_function

  # URLs for every published entry in +directory+, prefixed with +prefix+.
  #
  # Returns [] when the directory does not exist. That is the normal state of
  # this repository rather than an error: no entry is committed, so `_log/` may
  # hold nothing but a `.gitkeep`.
  def urls_for(directory, prefix)
    directory = Pathname.new(directory)
    return [] unless directory.directory?

    directory.children.sort.filter_map do |file|
      next unless file.file?
      next unless ENTRY_EXTENSIONS.include?(file.extname)

      front_matter = front_matter_of(file)
      next if front_matter.nil?
      next if front_matter["published"] == false

      "#{prefix}#{file.basename(file.extname)}/"
    end
  end

  # The parsed YAML front matter, or nil when the file has none.
  def front_matter_of(file)
    content = file.read
    match = content.match(/\A---\s*\n(.*?\n?)^---\s*$\n?/m)
    return nil if match.nil?

    YAML.safe_load(match[1], permitted_classes: [Date, Time]) || {}
  end
end
