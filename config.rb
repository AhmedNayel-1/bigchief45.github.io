###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false


# General configuration
set :avatar_url, 'https://avatars3.githubusercontent.com/u/6859247?s=460&v=4'

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

# Build-specific configuration
configure :build do
  # Minify CSS on build
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript

  # Github Pages will serve your project website from a subfolder.
  # This means that you can't reference your pages and assets with absolute URLs.
  # Tell Middleman to use relative URLs:
  activate :relative_assets
  set :relative_links, true

  activate :deploy do |deploy|
    deploy.build_before = true # runs build before deploying
    deploy.remote = 'git@github.com:BigChief45/bigchief45.github.io.git'
    deploy.deploy_method = :git
    deploy.branch = 'master'
  end


end
