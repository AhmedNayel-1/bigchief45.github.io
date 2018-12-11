---
date: '2017-03-14'
tags:
- programming
- open source
- openstack
- ceilometer
- python
title: Getting Started on Contributing to OpenStack
---

![OpenStack](http://seeklogo.com/images/O/openstack-logo-4A37C6FB5B-seeklogo.com.png)

I have started to become interested in contributing to the [OpenStack](https://www.openstack.org/) project. Starting to contribute to such a massive project can seem like a daunting task, and it is. It is only by arming yourself with the proper tools and knowledge prior to contributing, that you will have a smoother process. I created this blog post to smooth that process.

## Picking a Project

OpenStack is composed of many different projects for different purposes (compute, storage, networking, telemetry, etc.). Before you start contributing, you must have an idea of which project you actually want to contribute to. In my case I have decided on the [Telemetry](https://wiki.openstack.org/wiki/Telemetry) part, more specifically on **Ceilometer**.

After you have picked a project, it is time to start reading its documentation and developer documentation to understand how it works. The [Ceilometer developer documentation](https://docs.openstack.org/developer/ceilometer/) offers good explanations and diagrams of its architecture and components.

[Here](https://wiki.openstack.org/wiki/Ceilometer/Contributing) is another nice guide on contributing to Ceilometer.

<!--more-->

![Ceilometer Architecture](https://docs.openstack.org/developer/ceilometer/_images/ceilo-arch.png)

## Understanding the Development Workflow

Development of OpenStack follows a [strict workflow](https://docs.openstack.org/infra/manual/developers.html). It is imperative that you understand and become familiar on how this process works. Before you even begin coding, there are some "paperwork" that you must do first:

1. Setup a [Launchpad](https://launchpad.net/) account. Launchpad is Canonical's software collaboration platform.
2. Join the [OpenStack Foundation](https://www.openstack.org/join/) as a Foundation Member.
3. Sign the [Individual Contributor License Agreement](https://review.openstack.org/#/settings/agreements)
  - **If you are contributing on behalf of a company, you (or someone at your company) needs to additionally sign a [Corporate Contributor License Agreement](https://secure.echosign.com/public/hostedForm?formid=56JUVGT95E78X5) providing a list of people authorized to commit to code to OpenStack.**

### Understanding Gerrit

From *[Rant about Github pull-request workflow implementation](https://julien.danjou.info/blog/2013/rant-about-github-pull-request-workflow-implementation)*:

> To send a contribution to any OpenStack project, you need to pass via Gerrit. This is way simpler than doing a pull-request on Github actually, all you have to do is do your commit(s), and type git review. That's it. Your patch will be pushed to Gerrit and available for review.

>  Gerrit allows other developers to review your patch, add comments anywhere on it, and score your patch up or down. You can build any rule you want for the score needed for a patch to be merged; OpenStack requires one positive scoring from two core developers before the patch is merged.

>  Until a patch is validated, it can be reworked and amended locally using Git, and then resent using git review again. That simple. The historic and the different version of the patches are available, with the whole comments. Gerrit doesn't lose any historic information on your workflow.

### Following Rules for Proper Commits

In order for your contributions to be accepted into OpenStack, your commits must follow certain rules. For example:

- Use smaller and more commits instead of a single big commit.
- Make a separate commit for whitespace fixes.
- Do not mix unrelated functional changes.
- Provide a brief description of the change in the 1st line.
- Insert a single blank line after the first line.
- Provide a detailed description of the change in the following lines, breaking paragraphs where needed.
- First line should be limited to 50 characters and not end with a period.

You can read the complete document [here](https://wiki.openstack.org/wiki/GitCommitMessages). If your commits do not follow these rules, your patches will be rejected.

### Providing Appropriate Tests

You must test your changes first before submitting them. Project repositories generally have several categories of tests:

- Style Checks – Check source code for style issues
- Unit Tests – Self contained in each repository
- Integration Tests – Require a running OpenStack environment

Tests are run through [tox](http://tox.testrun.org/latest/). You can see how to run Ceilometer tests [here](https://docs.openstack.org/developer/ceilometer/testing.html).

### Coding Style Guidelines

Besides following the [Python PEP8](http://www.python.org/dev/peps/pep-0008/) Guidelines. OpenStack also enforces some additional guidelines which you may read [here](https://docs.openstack.org/developer/hacking/).

## OpenStack Upstream Training

OpenStack has designed a [training program](https://docs.openstack.org/upstream-training/) to share the knowledge about the different ways you can contribute to OpenStack and getting familiar with open source. They provide a nice [Vagrant development environment](https://github.com/kmARC/openstack-training-virtual-environment/) for this training which you can install in a virtual machine.

## Reaching to the Community

Reaching to the OpenStack community in a **smart** way is important if you want your contributions to OpenStack to be noticed and accepted. Before you start trying to contribute to a specific project, I recommend you first spend some time **observing** and **learning** how the community interacts and how the project's development process occurs.

Some ways to begin interacting with the community:

- Subscribing to the OpenStack [mailing list](http://lists.openstack.org/cgi-bin/mailman/listinfo/openstack-dev)
- Join the OpenStack IRC channels for a particular project and [IRC meetings](https://wiki.openstack.org/wiki/Meetings).
- Submit and review bugs in a project's bug tracker (Launchpad).

## Further Reading

- [The bad practice in FOSS projects management](https://julien.danjou.info/blog/2016/foss-projects-management-bad-practice)
- [Rant about Github pull-request workflow implementation](https://julien.danjou.info/blog/2013/rant-about-github-pull-request-workflow-implementation)
- [How to set up your work environment to become an OpenStack developer](http://superuser.openstack.org/articles/openstack-developer-beginner-setup/)