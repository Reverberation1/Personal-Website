# frozen_string_literal: true

# Tests for the Jekyll build helper — F03 AC-1.
#
# The two failure tests are not symmetric, and that asymmetry is the point:
#
#   * a malformed `_config.yml` makes Jekyll raise;
#   * a **missing source directory** makes Jekyll build an empty site quietly.
#
# A helper that only rescued exceptions would treat the second case as a
# successful build and hand back an empty directory. Every later assertion
# would then fail with a confusing "file missing" rather than "the build
# produced nothing". Both directions are pinned here.

require_relative "test_helper"

class SiteBuilderTest < Minitest::Test
  def setup
    @destination = Dir.mktmpdir("site-builder-test")
  end

  def teardown
    FileUtils.remove_entry(@destination) if File.directory?(@destination)
  end

  def test_build_produces_output
    result = SiteBuilder.build(FIXTURES.join("minimal_site"), @destination)

    index = Pathname.new(result).join("index.html")
    assert index.file?, "index.html was not written"
    refute_empty index.read.strip, "index.html is empty"
  end

  def test_build_raises_on_malformed_config
    error = assert_raises(SiteBuilder::BuildError) do
      SiteBuilder.build(FIXTURES.join("broken_config"), @destination)
    end

    assert_match(/_config\.yml/, error.message,
                 "Jekyll's own diagnostic was swallowed")
  end

  def test_build_raises_on_missing_source
    # Jekyll builds an empty site here rather than complaining. This is the
    # test that stops the helper from being a bare exception rescue.
    missing = Pathname.new(@destination).join("does_not_exist")

    error = assert_raises(SiteBuilder::BuildError) do
      SiteBuilder.build(missing, Pathname.new(@destination).join("out"))
    end

    assert_match(/produced no index\.html/, error.message)
  end
end
