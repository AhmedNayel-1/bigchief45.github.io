---
date: '2017-03-22'
tags:
- openstack
- devstack
- ceilometer
- python
- ubuntu
- linux
title: Setting Up an OpenStack Dev Environment
---

Before beginning to [contribute to OpenStack](/posts/getting-started-on-contributing-to-openstack.html), it is necessary that we setup an ideal development environment for a smoother workflow.

In this post I will cover how to setup a Devstack development environment in a **Ubuntu 16.04** virtual machine using [VMware Player](http://www.vmware.com/).

## Setting Up the Ubuntu Virtual Machine

Make sure you have [VMware Player](http://download.cnet.com/VMware-Player/3000-2094_4-10470784.html) installed in your system. Then we need to choose an appropriate Ubuntu ISO image for our virtual machine. In my case I am using a [Ubuntu Desktop 16.04.2 LTS (Xenial Xerus)](http://releases.ubuntu.com/xenial/) for **32-bit PC i836**.

In VMware Player, create a new virtual machine using the wizard. Assign your preferred amount of memory and storage space. Now start the machine, and select the Ubuntu `.iso` image file when prompted. Proceed with the installation and select the *Erase Disk and Install Ubuntu* option when prompted.

~> I tried using [VirtualBox](https://www.virtualbox.org/) for virtualization but I could not successfully install Devstack with it. Probably due to issues on using the correct network adapter. I also tried using Ubuntu 14.04 without success as well. This is why I recommend **Ubuntu 16.04**.

Once the installation is finished, restart the virtual machine.

<!--more-->

### Preliminary Setup

Before anything, let's go ahead and make sure that aptitude is up to date:

```
sudo apt-get update
```

Then let's make sure that `pip` is installed and up to date:

```
sudo apt-get install python-pip
sudo pip install --upgrade pip
```

## Setting Up the Stack User

We need to create a special user to work with Devstack. Devstack is a series of extensible scripts used to quickly bring up a complete OpenStack environment based on the latest versions of everything from git master. It is used interactively as a development environment and as the basis for much of the OpenStack project's functional testing.

Devstack should be run as a non-root user with sudo enabled. Since this user will be making many changes to your system, it will need to have sudo privileges.

Create the group `stack` and add the user `stack` in it:

```bash
sudo groupadd stack
sudo useradd -g stack -s /bin/bash -d /opt/stack -m stack
```

Grant super user permissions to the `stack` user:

```bash
sudo su
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
```

Logout from `root` by pressing <kbd>Ctrl + D</kbd>

Create a password for the `stack` user:

```bash
sudo passwd stack
```

Now to login as the stack user and go to the home directory of the stack user:

```bash
su stack
cd ~
```

Check that the present working directory is `/opt/stack` by using the `pwd` command.

## Setting Up Git

We will be using [git](https://git-scm.com/) for version control. Let's install it using apt-get:

```bash
sudo apt-get install git
```

Now let's configure our credentials:

```bash
git config --global user.name "YOUR_FIRSTNAME YOUR_LASTNAME"
git config --global user.email YOUR_EMAIL@EMAIL_ADDRESS.com
```

We can check and confirm our git configuration using the `git config --list` command.

## Setting Up DevStack

![Devstack](https://docs.openstack.org/developer/devstack/_images/logo-blue.png)

Now we are ready to download Devstack from OpenStack's git repository by cloning the repository:

```bash
git clone https://git.openstack.org/openstack-dev/devstack
```

Now let's enter the `devstack` directory (`cd devstack`) and copy a sample configuration into the devstack directory:

```bash
cp samples/local.conf .
```

### Configuring DevStack

The `local.conf` file allows us to specify the preferred configuration for devstack before deploying it. In this file we can configure passwords, logging, projects we want to download (such as Ceilometer), etc.

We can add some simple password configuration for a few services:

```
ADMIN_PASSWORD=openstack
DATABASE_PASSWORD=openstack
RABBIT_PASSWORD=openstack
SERVICE_PASSWORD=openstack
```

For my case, I also want to include Ceilometer in the devstack deployment, so I add the following to `local.conf`:

```
# Enable the Ceilometer devstack plugin
enable_plugin ceilometer https://git.openstack.org/openstack/ceilometer.git
```

Once everything is configured, we can run the `script.sh` file to begin the installation, this should take around 30-60 minutes. Once Devstack is installed. You should get a message like the following:

```
This is your host IP address: 182.168.21.133
This is your host IPv6 address: ::1
Horizon is now available at http://192.168.21.133/dashboard
Keystone is serving at http://192.168.21.133/identity
The default users are: admin and demo
The password: openstack
```

Obviously the values might be different for your case.

## Setting Up SSH Keys

Let's create a new SSH key, using the provided email as a label. We can save the key in the default prompted location, we can also leave the secure passphrase blank.

```bash
ssh-keygen -t rsa -C "YOUR_EMAIL@EMAIL_ADDRESS.com"
```

Start the ssh-agent in the background:

```
eval "$(ssh-agent -s)"
```

-> In shell terminology, `eval` is a built-in, not a function. It will take an argument and construct a command of it, which will be executed by the shell.

Add the SSH key to ssh-agent:

```bash
ssh-add ~/.ssh/id_rsa
```

Let's download and install xclip. This is a utility for copying content to a clipboard in Linux. At the same time let's copy the contents of the SSH key (`id_rsa.pub`):

```
sudo apt-get install xclip
sudo xclip -sel clip < ~/.ssh/id_rsa.pub
```

Now you can login into your [Github](www.github.com) account, go to *Settings*, click *SSH and GPG keys* then select *new SSH key*. Write a description in “Title” and paste your key into the “Key” field. Finally press *Add SSH Key*.

Let's test the connection using SSH:

```bash
ssh -T git@github.com
```

## Setting Up Gerrit

[Gerrit](https://www.gerritcodereview.com/) is the code review system used in OpenStack development.

Before setting up Gerrit, make sure that you have followed the [preliminary steps](/posts/getting-started-on-contributing-to-openstack.html) for preparing to contribute to OpenStack.

Let's copy our SSH again using xclip:

```bash
sudo xclip -sel clip < ~/.ssh/id_rsa.pub
```

Now sign in to [https://review.openstack.org/](https://review.openstack.org/) using your Launchpad ID. Click on *Settings* then select *SSH Public Keys* and press *Add Key*. Press <kbd>Ctrl+V</kbd> to paste the key and then click *Add*.

Now let's proceed to install git review. Git-review tool is a git subcommand that handles all the details of working with Gerrit.

```bash
sudo apt-get install git-review
```

Check if git review works inside Keystone (or any other project) directory of OpenStack:

```bash
cd keystone

git review -s
```

You will be prompted for your gerrit username, which can be configured in the OpenStack gerrit settings. A remote will now be set up and will match to the project's git repository.

=> OpenStack has a sandbox repository for learning and testing purposes. This is a great repository to begin your OpenStack learning. It allows you to experiment with the workflow and try different options so you can learn what they do. Read more about it [here](https://docs.openstack.org/infra/manual/sandbox.html#sandbox).

## Running Tox

[Tox](https://tox.readthedocs.io/en/latest/) is a generic virtualenv management and test command line tool.

Each project like Keystone, Nova, Cinder etc. has a `tox.ini` file defined in it. It defines the tox environment and the commands to run for each environment. Subsequent runs of tox will be faster because everything fetched will be in `.tox` already.

-> There are two types of OpenStack tests: the OpenStack integration test suite, called Tempest, and unit tests in each particular project (Nova, Neutron, Swift and so forth).

Install tox and pbr:

```bash
sudo apt-get install python-tox
sudo pip install pbr
```

Update and upgrade:

```bash
sudo apt-get update
sudo apt-get upgrade
```

Go inside any project directory like Keystone, Cinder or Nova and run tox:

```bash
cd ceilometer
tox -e py27,pep8
```
You can run a single test or let tox run the full suite. At the end of the test, you’ll get a nice printout of what exactly was run. Note that you don’t have to specify the full file path.

~> Depending on the project, you might need to install additional dependencies to be able to run the tests. Consult the developer documentation for a specific project on how to run its tests.<br><br>
For Ceilometer, it is necessary to install `mongodb` and `libmysqlclient-dev`.

If you get the following output on the terminal after entering the command, then tox has installed successfully:

```
======
Totals
======
Ran: 1019 tests in 90.0000 sec.
 - Passed: 1018
 - Skipped: 1
 - Expected Fail: 0
 - Unexpected Success: 0
 - Failed: 0
Sum of execute time for each test: 79.0575 sec.
```

At this point your OpenStack development is ready and you can begin to contribute. Happy coding!