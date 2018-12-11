---
date: '2016-10-14'
tags:
- linux
- ubuntu
- debian
- packaging
title: Managing Debian Package Dependencies
---

In a previous post, I talked about [building a simple Debian package in Ubuntu](2016-10-11-debian-packaging-in-ubuntu.html), however I did not go into details on how to manage the dependencies that your Debian package might require. In this post I will cover exactly that.

## dpkg and Dependencies

Previously we installed our package using the <kbd>dpkg -i</kbd> command. However, the problem with `dpkg` is that by itself, it is not capable of managing repositories. Therefore, higher level tools (such as `apt-get`) are required to fetch dependencies from repositories.

> dkpg is only the core tool that installs/removes/configures packages, taking care of dependencies and other factors. apt-get and aptitude are tools that manage repositories, download data from them, and use dkpg to install/remove packages from them. This means, that apt-get and aptitude can resolve dependencies and get required packages from repository, but dpkg cannot, because it knows nothing about repositories.

<!--more-->

## Specifying Dependencies

We can specify the required dependencies of our package in our package's control file (located in `DEBIAN/control`) by listing them as a list of package names separated by commas in the `Depends` field:

```
Package: mypackage
Version: 1.0-0
Section: base
Priority: optional
Architecture: all
Depends: erlang-nox, erlang
Maintainer: Andres Alvarez <myemail@gmail.com>
Description: A new and improved C++ Compiler
```
We can see that the package depends on `erlang` and `erlang-nox`. We could also be more specific and specify an exact version of the dependency:

```
Depends: erlang (>= 1.2)
```

Additionally, we can use pipe symbols (`|`) to specify alternative package names, similar to saying "or" in conditional operations:

```
Depends: erlang-nox | erlang, maven, rrdtool
```

## Installing Dependencies

What we want is to install the package's dependencies the momment we begin to install the package, **NOT** after it has finished installing (which can be done with <kbd>apt-get -f install</kbd>)

### Introducing Gdebi

Gdebi is a tool that can install a Debian package along with its dependencies. However in newer versions of Ubuntu it is not installed by default, so you need to install it using <kbd>apt-get install gdebi-core</kbd>.

Once installed, we can install our package using the following command:

```
gdebi install my-package.deb
```

This will proceed to install to install the package as well as the dependencies listed in the `control` file.

Unfortuntely for some reason, `gdebi` does not provide a `-y` option like `apt-get` does. This makes it unappropriate for using it inside shell scripts.

### Enter apt-get

`apt-get` is a better choice if you want to install your package with its dependencies from shell scripts, since we can pass the `-y` option to the `install` command. Moreover, this approach is more optimal when you [set up and use a local apt repository](2016-10-17-configuring-a-local-apt-repository.html).

Assuming we have added our package to our local apt repository, we can proceed to install it like this:

```
apt-get install mypackage
```

apt will search our repository for the package, and once it finds it it will proceed to install the listed dependencies, and then install the package. It is worth mentioning that <kbd>apt-get install</kbd> also uses `dpkg` internally.

## References

- [http://www.debian.org/doc/manuals/maint-guide/dreq.en.html#control](http://www.debian.org/doc/manuals/maint-guide/dreq.en.html#control)