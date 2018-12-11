---
date: '2016-10-17'
tags:
- linux
- apt
- aptitude
- repository
title: Configuring a local apt repository
---

Setting up a local apt repository can allow you to use `apt-get install` command to install your own packages. This is a better approach than using `dpkg -i` because apt will fetch and install the required dependencies (which should also be located in your local repository) in an **offline** fashion.

## Add Local Repository to Sources

First we need to add our local repository to `apt`'s list of source repositories, this can be found in `/etc/apt/sources.list`. To add our local repository, we add the following line at the top of the file:

```
/path/to/local-deb-repo/ ./
```

Where *local-deb-repo* is the name of our local repository directory.

## Add Debian Packages

Now we create local repository's directory just like we specified it in the previous step:

```
mkdir /path/to/local-deb-repo/
```

Once we've done that, we can proceed to put the Debian package files (`.deb`) and their dependencies inside the directory.

<!--more-->

## Create Package Index Files

```
cd /path/to/local-deb-repo/
sudo bash -c 'dpkg-scanpackages . | gzip > ./Packages.gz'
```

## Update Repository Source

Finally we update our repository with:

```
sudo apt-get update
```

We can now proceed to install the packages located inside our local repository using `sudo apt-get install <package-name>` command. Aptitude will proceed to install the package's dependencies listed in its control file. Check my post on [managing Debian package dependencies](2016-10-14-managing-debian-package-dependencies.html) to learn how to add and specify dependencies to your Debian package.

If you want to add new packages to your repository, simply place the Debian package files into the directory and re-create the package index files and update `apt` again.