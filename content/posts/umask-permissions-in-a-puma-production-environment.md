---
date: '2017-10-18'
tags:
- ruby
- sinatra
- web dev
title: Umask Permissions in a Puma Production Environment
---

Recently I was having an issue with a Sinatra application deployed in a staging
server. The application was deployed with Puma and Nginx in the following location:

```
/var/www/
```

This web service would then try to access some files in another directory on the server,
mounted as an SFTP directory. The Sinatra app would open these files and generate some
new files from them, depending on the HTTP request received.

The problem was that the operation would fail due to a permissions issue. I was baffled
since I had set **read** and **write** permissions to the directory and the files in it.

## Umask: The Problem and Solution

It took around two days to find the culprit: **umask**. In Linux, [umask](https://askubuntu.com/questions/44542/what-is-umask-and-how-does-it-work)
acts as another set of permissions for **processes** and cannot be set for directories,
basically speaking.

I realized that this probably meant that the process running the Puma application server had
a umask configuration that was not allowing the generation of new files.

I decided to test this if this was the case. In the [Puma](https://github.com/puma/puma)
documentation, I found an option to change the permissions of the UNIX socket using
umask:

<!--more-->

```
puma -b 'unix:///var/run/puma.sock?umask=0111'
```

Since I am using [Capistrano](https://github.com/capistrano/capistrano) for
deployment, I added it to the Capistrano Puma configuration in `deploy.rb`:

```ruby
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock?umask=0664"
```

Using `0664` permissions does the following:

- Sets **owner** permissions to **read** and **write**.
- Sets **group** permissions to **read** and **write**.
- Sets **other** permissions to **read**.

After re-deploying, I found out this was indeed the issue. With this fix, my Sinatra
application was now generating the files as intended.

## References

1. https://askubuntu.com/questions/44542/what-is-umask-and-how-does-it-work