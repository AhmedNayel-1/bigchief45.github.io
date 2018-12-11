---
date: '2016-10-11'
tags:
- linux
- ubuntu
- debian
- packaging
title: Debian Packaging in Ubuntu
---

Debian packaging is a nice way to organize our software so that it can be installed and uninstalled with more ease. In this post we will go through the basics of creating a simple Debian package in Ubuntu 14.04 LTS.

## Package Source & Structure

We will first create our working space for our package along with the necessary basic structure needed. For this example, we will create a directory for our package source, using the package title and 3 digit versioning in the directory's title:

```
mkdir mypackage-1.0.0
```

Inside our package, we will need a directory where we will hold the control files that give the Debian package the desired behavior:

```
cd mypackage-1.0.0
mkdir DEBIAN
touch DEBIAN/control
```

This `control` file will describe our package to the Debian package manager (`dpkg`). Inside, we can specify information about the package such as version, architecture, dependencies, maintainer, etc, as shown below:

```
Package: mypackage
Version: 1.0-0
Section: base
Priority: optional
Architecture: all
Depends: python2.7
Maintainer: Andres Alvarez <myemail@gmail.com>
Description: A new and improved C++ Compiler
```

With this basic setup, we now have a basic working package that can be handled by the Debian package manager, albeit, with no contents.

<!--more-->

Now here is where it gets interesting. The directory and file structure inside our package source will resemble the directory structure of our file system. This is how the Debian package manager knows where to depackage the files contained inside our Debian package. For example, let's add the following to our package:

```
mkdir -p home/ubuntu
touch home/ubuntu/hello.sh
```

When our package is depackaged and installed, the package manager will depackage `home/ubuntu/hello.sh` from our package into `home/ubuntu/hello.sh` of our file system.

### Post-Installation Script

Additionally, we can create a `postinst` script with executable permissions inside the `DEBIAN` directory that will be executed after the installation (depackaging) is finished. For example:

```bash
#!/bin/bash
echo "Hello World!"
```

!> You **cannot** run `apt-get` commands inside post/pre installation scripts, since this will create lock-conflict errors with `dpkg`. See [here](http://stackoverflow.com/questions/18599599/apt-get-commands-from-within-a-deb-postinst) and [here](http://askubuntu.com/questions/396213/can-i-call-other-dpkg-or-apt-commands-within-my-preinst-scripts)).

These lock-conflict errors look like the following:

```
E: Could not get lock /var/lib/dpkg/lock - open (11: Resource temporarily unavailable)
E: Unable to lock the administration directory (/var/lib/dpkg/), is another process using it?
```

## Building and Installing the Package

Now that our package is ready to be shipped, we can build the source using the following command:

```
dpkg-deb --build ./mypackage-1.0.0
```

This will create a `.deb` extension Debian package file that we can now distribute and others can install in their systems. To install, we simply run this command:

```
dpkg -i mypackage-1.0.0.deb
```

And like I mentioned previously, the package manager will proceed to unpack all the contained files to our file system, according to the directory structure of the package.

## Other Useful Dpkg Commands

### Inspecting Packages

We can also inspect the contents of the Debian package. The following command will print all the files and their respective locations inside the package.

```
dpkg -c my-package.deb
```

Additionally we can also print information about the package. This is the information stored inside the `DEBIAN/control` file:

```
dpkg -I my-package.deb
```

### Extracting Contents

It is also possible to unpack the contents of the package **without** installing it. This will also extract the control information files into a `DEBIAN` subdirectory:

```
dpkg-deb -R my-package.deb $TARGET_DIRECTORY
```