---
date: '2016-11-17'
tags:
- middleman
- ruby
- markdown
title: Custom Markdown in Middleman
---

[Middleman](https://middlemanapp.com/) is an excellent static site generator written in Ruby. It is extremely practical for blogging as well, and it's the framework I am currently using for this blog.

Unfortunately Middleman's [documentation](https://middlemanapp.com/basics/install/) is a bit unorganized and incomplete. I often find myself browsing through the [source code](https://github.com/middleman/middleman) to understand how to use or implement some custom features.

For example, using [redcarpet](https://github.com/vmg/redcarpet) I wanted to be able to create some re-usable "markdown components" that I could use in my blog posts. Something like bootstrap alerts, so that I could re-use them without having to add HTML or any code to my markdown.

And this post I am going to explain how to integrate this functionality into your blog using Middleman.

## Creating a Custom Renderer

Middleman comes built in with a custom Redcarpet renderer which Middleman uses to parse the links and images (and possibly other things) in your blog's markdown. To be able to implement our custom markdown we need to create our own custom renderer, which should inherit from `Redcarpet::Render::HTML`. However, the **key** thing here is to actually inherit directly from [Middleman's renderer](https://github.com/middleman/middleman/blob/master/middleman-core/lib/middleman-core/renderers/redcarpet.rb#L65) (which of course, inherits from `Redcarpet::Render::HTML`).

To begin, we will create a `lib` (if it doesn't exist) under our blog's directory and create a file named `markdown_helper.rb` inside it. The initial contents of this helper will be:

```ruby
module MarkdownHelper

  require 'middleman-core/renderers/redcarpet'

end
```

The required file above is what will allow us to inherit from Middleman's renderer.

<!--more-->

=> The reason we want to inherit from middleman's renderer instead of a blank new `Redcarpet::Render::HTML` is because this way we don't have to re-implement the parsing of images and links, and possibly other things. This will help in keeping the renderer's code as small as possible.

Now we can define and create our custom renderer:

```ruby
module MarkdownHelper

  require 'middleman-core/renderers/redcarpet'

  class MyRenderer < Middleman::Renderers::MiddlemanRedcarpetHTML
    def initialize(options={})
      super
    end
  end

end
```

Now we are adding an `initialize` method to our renderer. Calling `super` with no arguments from inside the initializer will call the parent's (`MiddlemanRedcarpetHTML`) initializer with the arguments passed to our renderer's initializer.

We are now ready to begin adding custom markdown parsing to our renderer.

### Automatically Centering Images

Another thing I needed was to automatically center and make responsive images in my blog posts. I wanted to do this **without** having to add extra CSS, but I couldn't find a way to do so until I learned about redcarpet renderers. The extra CSS then started conflicting with the Bootstrap CSS and started giving my all sorts of headaches.

This problem can very easily fixed by overriding the Middleman renderer's `image` method, inside our custom renderer:

```ruby
module MarkdownHelper

  require 'middleman-core/renderers/redcarpet'

  class MyRenderer < Middleman::Renderers::MiddlemanRedcarpetHTML
    def initialize(options={})
      super
    end
  end

  def image(link, title, alt_text)
    if !@local_options[:no_images]
      # We add bootstrap centering and responsive class here
      scope.image_tag(link, title: title, alt: alt_text, class: 'center-block img-responsive')
    else
      link_string = link.dup
      link_string << %("#{title}") if title && !title.empty? && title != alt_text
      "![#{alt_text}](#{link_string})"
    end
  end

end
```

Keep in mind that our renderer inherits from Middleman's renderer. This makes possible the use of variables like `scope` and `@local_options`.

### Automatic Bootstrap Classes in Tables

Tables generated from markdown will not have any styles applied to it, you must define these CSS styles yourself. But we want all tables automatically to use [Bootstrap 3 table styles](http://getbootstrap.com/css/#tables) instead.

To do this, we will add a `table` method overwrite in our renderer:

```ruby
# ...

def table(header, body)
  "<table class='table table-responsive table-condensed table-striped'>" \
    "<thead>#{header}</thead>" \
    "<tbody>#{body}</tbody>" \
  "</table>"
end
```

Also make sure that Redcarpet is configured to render tables using Markdown in `config.rb`:

```ruby
set :markdown, :tables => true,
```

### Creating Markdown Alerts

This is where things get more interesting.

I wanted to create components similar to Bootstrap's alerts, using CSS class keywords such as `success`, `warning`, `info`, and `danger` to convey different types of alerts. Additionally, I wanted to be able to use any type of alert from within markdown using different syntaxes. In the end I settled for the following syntaxes, inspired by [this repository](https://github.com/hashicorp/middleman-hashicorp) :

- `=>`: success
- `->`: info
- `~>`: warning
- `!>`: danger

Once we are clear on the syntax we want to use, now we need to create the methods. The first thing we have to do is override the `paragraph` method and make it call a custom method that renders the alerts, based on regular expression (according to the syntax above) parsing:

```ruby
module MarkdownHelper

  require 'middleman-core/renderers/redcarpet'

  class MyRenderer < Middleman::Renderers::MiddlemanRedcarpetHTML
    def initialize(options={})
      super
    end
  end

  def image(link, title, alt_text)
    if !@local_options[:no_images]
      scope.image_tag(link, title: title, alt: alt_text, class: 'center-block') # We add bootstrap centering class here
    else
      link_string = link.dup
      link_string << %("#{title}") if title && !title.empty? && title != alt_text
      "![#{alt_text}](#{link_string})"
    end
  end

  def paragraph(text)
    add_alerts("<p>#{text.strip}</p>\n")
  end

end
```

Now we can implement our private `add_alerts` method:

```ruby
# ...

private

def add_alerts(text)
  map = {
    "=&gt;" => "success",
    "-&gt;" => "info",
    "~&gt;" => "warning",
    "!&gt;" => "danger",
  }

  regexp = map.map { |k, _| Regexp.escape(k) }.join("|")

  if md = text.match(/^<p>(#{regexp})/)
    key = md.captures[0]
    klass = map[key]
    text.gsub!(/#{Regexp.escape(key)}\s+?/, "")

    return <<-EOH
      <div class="panel panel-default">
      <div class="panel-body">
      <div class="media">
      <div class="media-left media-middle">
      <img class="media-object" src="/images/icons/#{klass}_32.png" alt="info">
      </div>
      <div class="media-body">
      <span class="small">#{text}</span>
      </div>
      </div>
      </div>
      </div>
    EOH
  else
    return text
  end
end
```

The `EOH` is a [Ruby heredoc](http://rubyquicktips.com/post/4438542511/heredoc-and-indent), a very common structure found in Bashscript. Heredocs let us return big strings without having to escape characters.

The method above does not actually render a [Bootstrap alert](http://getbootstrap.com/components/#alerts), but a custom kind of alert I came up with using **Bootstrap 3** panel, media object, and image icon, like the one below:

~> The HTML code returned in the heredoc **must not** have any indentations. Otherwise the HTML will not be rendered.

The above is a custom warning alert, and I can simply use it with the following markdown:

```
~> The HTML code returned in the heredoc **must not** have any indentations. Otherwise the HTML will not be rendered.
```

For each different kind of syntax, the method simply renders a different icon. Nice!

### Using The Custom Renderer

The renderer is ready to be used. To do so, we simply override the default Middleman renderer in `config.rb`:

```ruby
# config.rb

# ...

require 'lib/markdown_helper'
helpers MarkdownHelper

set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true,
              :smartypants => true,
              :tables => true,
              :highlight => true,
              :superscript => true,
              :renderer => MarkdownHelper::MyRenderer
```

And that's it.


## References

1. https://github.com/hashicorp/middleman-hashicorp