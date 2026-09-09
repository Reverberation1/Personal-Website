# frozen_string_literal: true

# Build the Jekyll site into a directory, and fail loudly when it does not.
#
# F03 AC-1. Kept as a plain module method taking a source directory rather than
# as logic inside a test fixture, so its failure path can be proven against
# throwaway fixture trees without corrupting the real checkout.
#
# Jekyll is driven through its own Ruby API rather than by shelling out to the
# `jekyll` binary. The tests already run under `bundle exec`, so the library is
# loaded anyway; going in-process removes a subprocess, removes the question of
# whether the executable is on PATH, and turns a broken config into an
# exception with a real backtrace instead of a captured string.

require "jekyll"
require "pathname"

module SiteBuilder
  # Raised when a build fails, or reports success while producing nothing.
  class BuildError < StandardError; end

  module_function

  # Build +source+ into +destination+ and return the destination Pathname.
  #
  # Raises BuildError if Jekyll itself fails, and also if the build completes
  # without writing an index.html. That second guard is not defensive padding:
  # pointed at a source directory that does not exist, Jekyll happily produces
  # an empty site rather than complaining. Without the guard, every later
  # assertion would fail with a confusing "file missing" rather than "the build
  # produced nothing".
  def build(source, destination)
    source = Pathname.new(source)
    destination = Pathname.new(destination)
    destination.mkpath

    begin
      config = Jekyll.configuration(
        "source" => source.to_s,
        "destination" => destination.to_s,
        # Matches .github/workflows/jekyll.yml: the site serves at the root of a
        # custom domain, so a non-empty baseurl breaks every asset URL.
        "baseurl" => "",
        "quiet" => true
      )
      Jekyll::Site.new(config).process
    rescue StandardError => e
      raise BuildError, "jekyll build failed for source #{source}: " \
                        "#{e.class}: #{e.message}"
    end

    if Dir.glob(destination.join("**", "index.html")).empty?
      raise BuildError, "jekyll build reported success but produced no " \
                        "index.html for source #{source}. Jekyll builds an " \
                        "empty site when the source directory does not exist " \
                        "— check that #{source} is real."
    end

    destination
  end
end
