# frozen_string_literal: true

# Shared setup — F03 AC-3.
#
# The site is built ONCE for the whole run, into a temporary directory. It is
# never read from the committed `_site/`: stale output would let every
# assertion pass while the real build was broken, which is exactly the failure
# this harness exists to catch.

require "minitest/autorun"
require "nokogiri"
require "pathname"
require "tmpdir"

require_relative "site_builder"

REPO_ROOT = Pathname.new(__dir__).parent
FIXTURES = Pathname.new(__dir__).join("fixtures")

module BuiltSite
  module_function

  # The built site, built at most once per run.
  def path
    @path ||= SiteBuilder.build(REPO_ROOT, Dir.mktmpdir("jekyll-test-site"))
  end

  # Every built page, parsed, keyed by its site-relative URL path.
  #
  # Keys look like "/", "/cv/", "/contact/". Keying by URL rather than by file
  # path keeps assertions readable and independent of the output layout.
  def pages
    @pages ||= Dir.glob(path.join("**", "index.html")).sort.to_h do |file|
      relative = Pathname.new(file).dirname.relative_path_from(path).to_s
      url = relative == "." ? "/" : "/#{relative}/"
      [url, Nokogiri::HTML5(File.read(file))]
    end
  end
end

# Helpers shared by the site tests.
module PageAssertions
  # The visible words of the navigation, in document order.
  #
  # Selects the `.nav-link-word` spans rather than the links, because the
  # current page renders as a <span> and would be missing from a link list.
  # That span is also what scramble.js targets, so this doubles as a guard on
  # the animation's class contract.
  def nav_words(document)
    document.css("span.nav-link-word").map { |node| node.text.strip }
  end

  def links(document)
    document.css("a[href]").map { |node| [node["href"], node.text.strip] }
  end
end
