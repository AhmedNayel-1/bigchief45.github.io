---
date: '2017-04-03'
tags:
- cloud9
- rails
- webpack
- javascript
- web-dev
title: Using Rails With Webpack in Cloud 9
---

The [rails/webpacker](https://github.com/rails/webpacker) project allows integration of [Webpack](https://webpack.github.io/) with a Rails application. However, setting this up in a [Cloud 9](https://c9.io) development environment needs a few tweaks to be able to work correctly. This post explains how to achieve this.

## Creating the Application

We will first create a regular Rails application and then use the webpacker gem to install Webpack.

```
rails new webpack-app
```

Add the gem to `Gemfile`:

```ruby
# Gemfile

gem 'webpacker', github: 'rails/webpacker'
```

Install Webpacker

```
rails webpacker:install
```

<!--more-->

The above command will proceed to install webpack, as well as update some dependencies using some package managers such as [Yarn](https://yarnpkg.com/).

Once the installation has finished, your application will contain a new directory for JavaScript modules under `app/javascript`. Modules such as ReactJS or VueJS modules will be placed here and will be fetched from the application in a similar way to using the Rails asset pipeline.

Additionally, Webpack configuration will be created under `app/config/webpack`. In this directory there will be man y configuration files that include configuration for the Webpack dev server, which is what we are interested in for our development environment.

```
config/webpack/
├── configuration.js
├── development.js
├── development.server.js
├── development.server.yml
├── loaders
│   ├── assets.js
│   ├── babel.js
│   ├── coffee.js
│   ├── erb.js
│   ├── sass.js
│   └── vue.js
├── paths.yml
├── production.js
├── shared.js
└── test.js
```

## Adding VueJS

Webpacker greatly facilitates the integration of Rails with other front-end JavaScript frameworks such as ReactJS and VueJS. Let's proceed to install VueJS:

```
rails webpacker:install:vue
```

The command above will also create some example Vue components that can be loaded right away from the appliation once the Webpack dev server and the Rails server are running and communicating.

## Making It Work in Cloud 9

Cloud 9 has some restrictions when it comes to security, ports, and interfaces when running services. To go around this, we first need to add a mapping from the hostname used in previewing our application, to `0.0.0.0`, which is the interface used when running services.

This is done by running the following command:

```bash
echo "0.0.0.0 $C9_HOSTNAME" | sudo tee -a /etc/hosts
```

Where `$C9_HOSTNAME` is a variable already defined by Cloud 9 and it will contain the hostname used to preview the application in the browser.

Next we must modify `app/config/webpack/configuration.js` to allow Webpack's output to be served using HTTPS, which is required by Cloud 9:

```javascript
const publicPath = env.NODE_ENV !== 'production' && devServer.enabled ?
  `https://${devServer.host}:${devServer.port}/` : `/${paths.entry}/`
```

Lastly, configure the webpack dev server to run using the `$C9_HOSTNAME` address. To get the value of this address you can first run:

```bash
echo $C9_HOSTNAME
```

Then copy the value an set it in the `host` field in `app/config/webpack/development.server.yml`:

```yaml
# Restart webpack-dev-server if you make changes here
default: &default
  enabled: true
  host: '$C9_HOSTNAME value here'
  port: 8081
```

Make sure that `port` is set to `8081`.

Now try running the webpack dev server:

```
./bin/webpack-dev-server
```

## Fetching Assets in Rails

To make Rails use the Vue components located in `app/javascript`, we can use the following tags in our views:

```erb
<%= javascript_pack_tag 'application' %>
<%= javascript_pack_tag 'hello_vue' %>
```

Now run the Rails server using `$PORT` and `$IP` as port and binding. When you open your application, it should load `hello_vue`.