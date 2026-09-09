source "https://rubygems.org"

gem "jekyll", "~> 4.2"

# Generates the redirect stub for a page's old URL from `redirect_from` in its
# front matter. Usable here because the deploy workflow runs our own Gemfile,
# not the GitHub Pages whitelisted-plugin build.
gem "jekyll-redirect-from", "~> 0.16"

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

# Performance and future-proofing
gem "wdm", ">= 0.1.1", :platforms => [:mingw, :x64_mingw, :mswin]

# Lock `http_parser.rb` gem to `v0.6.x` on JRuby builds since newer versions of the gem
# do not have a Java counterpart.
gem "http_parser.rb", "~> 0.6.0", :platforms => [:jruby]

# Test harness (F03). minitest ships with Ruby but is pinned here so CI
# resolves a known version; nokogiri parses the built HTML.
group :test do
  gem "rake", "~> 13.0"
  gem "minitest", "~> 5.0"
  gem "nokogiri", "~> 1.16"
end
