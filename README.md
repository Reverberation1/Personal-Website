# Personal Website

A minimal personal website built with [Jekyll](https://jekyllrb.com/), a static site generator written in Ruby. Features a Gruvbox color scheme with dark/light mode toggle and a clean, content-focused design.

## Features

- **Static Site Generation** with Jekyll
- **Gruvbox Theme** with dark and light mode support
- **Minimal Design** focused on content and readability
- **Responsive Layout** that works on all devices
- **GitHub Pages Ready** with automatic deployment

## Project Structure

```
Personal_Website/
├── _config.yml          # Jekyll configuration
├── _layouts/           # HTML templates
│   └── default.html    # Base layout
├── _includes/          # Reusable partials
│   └── navigation.html # Navigation menu
├── _sass/              # SCSS stylesheets
│   ├── _gruvbox.scss   # Gruvbox color variables
│   └── _main.scss      # Main stylesheet
├── assets/             # Static assets
│   ├── css/
│   │   └── main.scss   # Main stylesheet entry
│   └── js/
│       ├── theme-toggle.js # Dark mode toggle
│       └── load.js         # Content loading animation
├── pages/              # Content pages
│   ├── index.md        # Homepage
│   ├── cv.md           # CV page
│   ├── projects.md      # Projects page
│   └── contact.md      # Contact page
├── Gemfile             # Ruby dependencies
└── README.md           # This file
```

## Prerequisites

- [Ruby](https://www.ruby-lang.org/) 2.5.0 or higher
- [Bundler](https://bundler.io/) gem

Check if you have them installed:
```bash
ruby --version
bundle --version
```

If you don't have Bundler:
```bash
gem install bundler
```

## Installation

1. **Clone or download this repository**

2. **Install dependencies:**
   ```bash
   bundle install
   ```

## Local Development

### Serve Locally (with auto-reload)

Start the Jekyll development server:
```bash
bundle exec jekyll serve
```

The site will be available at `http://localhost:4000`

### Build for Production

Build the site:
```bash
bundle exec jekyll build
```

The generated site will be in the `_site/` directory.

## How Jekyll Works

Jekyll uses several key concepts:

### 1. Front Matter
YAML metadata at the top of files (between `---`):
```yaml
---
layout: default
title: My Page
permalink: /my-page/
---
```

### 2. Layouts
Templates in `_layouts/` that wrap content. The `default.html` layout includes navigation, theme toggle, and content area.

### 3. Includes
Reusable partials in `_includes/`. The `navigation.html` include creates the navigation menu.

### 4. Liquid
Template language used in Jekyll:
- `{{ variable }}` - Output a variable
- `{% tag %}` - Execute logic (loops, conditionals)

### 5. Collections
Custom content types. The `pages` collection in `_config.yml` defines our content pages.

### 6. Sass/SCSS
CSS preprocessing. Files in `_sass/` are imported and compiled to CSS.

### The Build Process

1. **Read Configuration** - Jekyll reads `_config.yml`
2. **Process Files** - Converts Markdown to HTML, applies layouts
3. **Process Assets** - Compiles SCSS to CSS, copies JS files
4. **Generate Site** - Outputs final HTML files to `_site/`

## Customization

### Adding New Pages

1. Create a new Markdown file in `pages/` directory:
   ```markdown
   ---
   layout: default
   title: My New Page
   permalink: /my-new-page/
   ---
   
   # My New Page
   
   Content goes here...
   ```

2. Add a link in `_includes/navigation.html` if desired.

### Changing Colors

Edit `_sass/_gruvbox.scss` to modify the Gruvbox color scheme. Colors are defined as CSS variables, making it easy to customize.

### Modifying Layout

- **Navigation**: Edit `_includes/navigation.html`
- **Page Structure**: Edit `_layouts/default.html`
- **Styling**: Edit `_sass/_main.scss`

## Deployment to GitHub Pages

### Automatic Deployment (Recommended)

1. **Create a GitHub repository** for your website

2. **Push your code:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/your-repo.git
   git push -u origin main
   ```

3. **Enable GitHub Pages:**
   - Go to your repository Settings → Pages
   - Under "Source", select "Deploy from a branch"
   - Choose branch: `main` (or `master`)
   - Choose folder: `/ (root)`
   - Click Save

4. **Your site will be live at:** `https://yourusername.github.io/your-repo/`

GitHub Pages automatically builds and deploys your site when you push changes!

### Manual Deployment (Alternative)

If you want to build locally and deploy the `_site` folder:

1. Build the site: `bundle exec jekyll build`
2. Copy contents of `_site/` to `docs/` folder
3. Update `_config.yml` to set `destination: docs`
4. Commit and push

## Custom Domain Setup

1. **Create CNAME file:**
   Create `CNAME` in the repository root with your domain name:
   ```
   yourdomain.com
   ```

2. **Configure DNS:**
   Add DNS records with your DNS provider:
   - **Type:** A or ALIAS
   - **Name:** @ (or your subdomain)
   - **Value:** GitHub Pages IP addresses:
     - 185.199.108.153
     - 185.199.109.153
     - 185.199.110.153
     - 185.199.111.153
   - (Optional) Add AAAA records for IPv6

3. **Enable in GitHub:**
   - Go to repository Settings → Pages
   - Enter your custom domain under "Custom domain"
   - Check "Enforce HTTPS" (recommended)

4. **Wait for DNS propagation** (can take up to 24 hours)

## Troubleshooting

### Build Errors

- **Missing dependencies:** Run `bundle install`
- **Ruby version:** Ensure you have Ruby 2.5.0+
- **Bundler:** Install with `gem install bundler`

### GitHub Pages Not Updating

- Ensure `Gemfile` and `Gemfile.lock` are committed
- Check GitHub Pages settings point to correct branch
- Wait a few minutes for GitHub to rebuild

### Theme Not Working

- Ensure `_sass/` files are properly named (start with `_`)
- Check that `assets/css/main.scss` has front matter (`---`)
- Verify SCSS imports are correct

## Resources

- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [Jekyll on GitHub Pages](https://jekyllrb.com/docs/github-pages/)
- [Liquid Template Language](https://shopify.github.io/liquid/)
- [Gruvbox Color Scheme](https://github.com/morhetz/gruvbox)

## License

MIT License - feel free to use this as a starting point for your own website!
