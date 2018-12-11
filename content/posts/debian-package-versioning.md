---
date: '2017-04-13'
tags:
- linux
- debian
- ubuntu
- aptitude
- apt
title: Debian Package Versioning
---

In a previous post I talked about [managing Debian package dependencies](/posts/managing-debian-package-dependencies.html). However I did not go into detail about the structure the versioning of packages must have.

To recap, let's see how we can specify a specific package version of a dependency that our package needs:

```
Depends: erlang (>= 1.2)
```

In the example above, the required version for erlang is simply `1.2` or greater. A package's version format however, can be a bit more complex than this.

## Version Format and Components

The official format of a Debian package's version is:

```
[epoch:]upstream_version[-debian_revision]
```

Let's go into detail about each of the components in that format.

<!--more-->

### Epoch

A single positive integer. It may be omitted, in which case zero is assumed. If it is omitted then the `upstream_version` may not contain any colons.

It is provided to allow mistakes in the version numbers of older versions of a package, and also a package's previous version numbering schemes, to be left behind.

### Upstream Version

This is the main part of the version number. It is usually the version number of the original ("upstream") package from which the `.deb` file has been made, if this is applicable. Usually this will be in the same format as that specified by the upstream author(s); however, it may need to be reformatted to fit into the package management system's format and comparison scheme.

The `upstream_version` portion of the version number is mandatory.

The `upstream_version` may contain only alphanumerics and the characters <kbd>.</kbd> <kbd>+</kbd> <kbd>-</kbd> <kbd>:</kbd> <kbd>~</kbd> (full stop, plus, hyphen, colon, tilde) and should start with a digit. If there is no `debian_revision` then hyphens are not allowed; if there is no epoch then colons are not allowed.

### Debian Revision

This part of the version number specifies the version of the Debian package based on the upstream version. It may contain only alphanumerics and the characters <kbd>+</kbd> <kbd>.</kbd> <kbd>~</kbd> (plus, full stop, tilde) and is compared in the same way as the `upstream_version` is.

It is optional; if it isn't present then the upstream_version **may not** contain a hyphen. This format represents the case where a piece of software was written specifically to be a Debian package, where the Debian package source must always be identical to the pristine source and therefore no revision indication is required.

=> It is conventional to restart the `debian_revision` at 1 each time the `upstream_version` is increased.

The package management system will break the version number apart at the last hyphen in the string (if there is one) to determine the `upstream_version` and `debian_revision`. The absence of a `debian_revision` is equivalent to a `debian_revision` of 0.

## Version Comparison

When comparing two version numbers, first the *epoch* of each are compared, then the *upstream_version* if *epoch* is equal, and then *debian_revision* if *upstream_version* is also equal.

The purpose of epochs is to allow us to leave behind mistakes in version numbering, and to cope with situations where the version numbering scheme changes. It is not intended to cope with version numbers containing strings of letters which the package management system cannot interpret (such as `ALPHA` or `pre-`), or with silly orderings.

## An Example

We can use the following command to see version information of an installed package using apt-get:

```
apt-cache policy <package-name>
```

As an example, lets check the information for the erlang package:

```
erlang:
  Installed: 1:16.b.3-dfsg-1ubuntu2.1
  Candidate: 1:16.b.3-dfsg-1ubuntu2.1
  Version table:
 *** 1:16.b.3-dfsg-1ubuntu2.1 0
        500 http://archive.ubuntu.com/ubuntu/ trusty-updates/universe amd64 Packages
        100 /var/lib/dpkg/status
     1:16.b.3-dfsg-1ubuntu2 0
        500 http://archive.ubuntu.com/ubuntu/ trusty/universe amd64 Packages

```

From the output we can see that the version of the currently installed erlang is `1:16.b.3-dfsg-1ubuntu2.1`. Let's separate this long version into the three components:

| Component | Value |
| --------- | ----- |
| Epoch | `1` |
| Upstream version | `16.b.3-dfsg` |
| Debian Revision | `-1ubuntu2.1` |

## Specific Version Dependencies

Back to the topic of dependencies, a question arises: which components should we specify when needing a specific version of a package? The examples in the [Debian manual](https://www.debian.org/doc/manuals/maint-guide/dreq.en.html#control) don't really show any versions with epoch or upstream versions with letters betwen periods, or multiple hyphens.

The answer is **all of them**. We must specify the full version, like shown below:

```
Depends: erlang (= 1:16.b.3-dfsg-1ubuntu2.1)
```

## References

- https://www.debian.org/doc/debian-policy/ch-controlfields.html#s-f-Version
- [Debian Cheatsheet](https://web.archive.org/web/20121024134944/http://carlo17.home.xs4all.nl/howto/debian.html)