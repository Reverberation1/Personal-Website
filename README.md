# kester.world

The source for my personal site — a small, text-first Jekyll site with a Gruvbox
palette, a dark/light toggle, and a letter-scramble animation on headings and
navigation.

Live at **<https://kester.world>**.

## Run it locally

Requires Ruby 3.x and Bundler.

```bash
bundle install             # once
bundle exec jekyll serve   # dev server with auto-reload at http://localhost:4000
bundle exec jekyll build   # production build into _site/
```

There is no linter and no JavaScript build step. The scripts in `assets/js/`
are plain files served as they are.

## Tests

```bash
bundle exec rake test
```

Minitest and Nokogiri, installed by `bundle install` with everything else. One
toolchain, the same one the site itself builds with.

The suite builds the site into a temporary directory and asserts against the
generated HTML. It never reads the committed `_site/`, because stale output
would let the assertions pass while the real build was broken. Jekyll runs
in-process through its own Ruby API rather than as a subprocess, so a bad
config surfaces as a real exception and the whole run takes well under a
second.

## Layout

```
_config.yml               Jekyll config: site metadata, the `pages` collection
_layouts/default.html     the only layout: <head>, header, nav, main, scripts
_includes/navigation.html hand-written nav, one block per page
pages/                    the content: home.md, cv.md, made.md, contact.md
assets/css/main.scss      the live stylesheet (self-contained)
assets/js/scramble.js     the letter-scramble effect
assets/js/theme-toggle.js dark/light toggle, persisted to localStorage
assets/js/load.js         fade-in stub; the fade itself is CSS
.github/workflows/        build and deploy to GitHub Pages
_sass/                    legacy, unused — see Styling below
```

Content lives in a `pages` collection rather than in root Markdown files.
`_config.yml` outputs the collection at `/:name/`, and `pages/home.md` overrides
its own permalink to `/`.

## Add a page

1. Create `pages/<name>.md` with front matter: `layout: default`, `title:`, and
   a `permalink:` if you want something other than `/<name>/`.
2. Add a matching block to `_includes/navigation.html`. The nav is written by
   hand, not generated. Each entry has an `{% if page.url == '/<name>/' %}`
   branch that renders the current page as a `<span>` instead of a link.
3. Keep the `data-text` attribute and the inner `.nav-link-word` span. The
   scramble animation selects on both.

To opt a heading or a line of text into the scramble effect, write raw HTML in
the Markdown with the classes the script targets: `.name`, `.scramble-text`, or
any `<h1>` directly under `.main`.

## Styling

**Edit `assets/css/main.scss`.** It is the live stylesheet and it is fully
self-contained: it inlines the Gruvbox variables and every rule, and it imports
nothing. The partials in `_sass/` are dead code that nothing references.

The file needs its leading empty `---` front matter, or Jekyll will not compile
the SCSS.

Colours are CSS custom properties on `:root`, re-declared under
`html[data-theme='light']`. `theme-toggle.js` flips the `data-theme` attribute
and writes the choice to `localStorage`. An inline script in the layout `<head>`
applies the stored theme before first paint, so the page does not flash.

## Deployment

`.github/workflows/jekyll.yml` builds the site and deploys it to GitHub Pages on
every push to `main`. Two settings in that workflow are load-bearing:

- **`--baseurl ""`** — the site serves at the root of a custom domain, so the
  build overrides the baseurl to empty. A non-empty baseurl breaks every CSS and
  JS URL.
- **`bundler: "Gemfile.lock"`** — `Gemfile.lock` was written by Bundler 4, and
  the runner's default Bundler 2 fails `bundle install` without this.

`_site/` is local build output and is not committed. The workflow rebuilds from
source.
