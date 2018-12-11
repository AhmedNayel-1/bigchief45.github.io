---
date: '2016-12-21'
tags:
- zenoss
- zope
- zenpacks
- javascript
- xml
- ui
title: Extending Zenoss Navigation Bars
---

It is possible to extend the functionality of Zenoss's navigations from within our custom ZenPacks. This means that we can add or remove links to the navigation bars we frequently use to access the infrastructure page or event console.

## configure.zcml

Zenoss ZenPacks can contain a file in the ZenPack top directory called `configure.zcml`. I've mentioned and talked about this particular file in previous posts. This file basically acts as a configuration glue between back-end functions and front-end components.

It is in this file where we will declare and create new navigational links from our ZenPack.

~> In this post we assume that the ZenPack is created using [zenpacklib](https://zenpacklib.zenoss.com/en/latest/), which is a Python library that makes creating ZenPacks much easier. Zenpacklib also makes the integration between the back-end and front-end much easier as well.

Usually this file begins with some required boilerplate code:

**configure.zcml**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configure
  xmlns="http://namespaces.zope.org/zope"
  xmlns:browser="http://namespaces.zope.org/browser"
  xmlns:zcml="http://namespaces.zope.org/zcml">

  <!-- Our custom code here -->
  <include package=".browser" />
</configure>
```

<!--more-->

In the code above we are simply including a new directory (which will also contain a different `configure.zcml` file) in the configuration. It is in this new `configure.zcml` file that we will be creating the new navigation links, therefore we proceed and create the directory and the file:

```
mkdir browser
touch browser/configure.zcml
```

The `browser/configure.zcml` file should also contain the initial boiler plate code shown above, minus the package inclusion statement.

## Zenoss Primary Navigation Bar

The primary navigation bar in Zenoss is the navigation bar that allows us to access Zenoss's most important pages. These are the dashboard, events, infrastructure, reports, and advanced settings.

We can easily add a new link to this navigation bar by adding the following code to `browser/configure.zcml`:

```xml
<browser:viewlet
  name="New Page"
  url="/zport/dmd/newpage"
  weight="15"
  manager="Products.ZenUI3.navigation.interfaces.IPrimaryNavigationMenu"
  class="Products.ZenUI3.navigation.menuitem.PrimaryNavigationMenuItem"
  permission="zope2.Public"
/>
```

The *weight* attribute here specifies the index that this new item will have in regards to the items already contained in the navbar.

After installing the ZenPack and restarting Zenoss. We can see our new **NEW PAGE** navigation link:

![Primary Nav](/posts/extending-zenoss-navigations/zenoss_primary_nav.jpg)

## Zenoss Secondary Navigation Bar

Besides the primary navigation bar, Zenoss also has a secondary navigation bar that appears below the primary navigation bar. However, **each** item (link) from the primary navigation bar will have a secondary navigation bar of its own. We can see this easily because *EVENTS* will have secondary links such as *Event Console* and *Event Classes* while *INFRASTRUCTURE* will have its own links such as *Devices*, *Network Map* and *Processes*.

Let's say we want to add a new item to the secondary navigation bar in INFRASTRUCTURE. We can easily do this by adding the following to `browser/configure.zcml`:

```xml
<browser:viewlet
  name="Secondary Link"
  url="/zport/dmd/secondaryPage"
  weight="8"
  parentItem="Infrastructure"
  manager="Products.ZenUI3.navigation.interfaces.ISecondaryNavigationMenu"
  class="Products.ZenUI3.navigation.menuitem.SecondaryNavigationMenuItem"
  permission="zenoss.View"
  layer="Products.ZenUI3.navigation.interfaces.IZenossNav"
  />
```

**url** represents the URL where this link leads to. Primary navigation links also have this field. **parentItem** specifies *which* link from the **primary** navigation bar will this secondary navigation link will belong to.

If we restart *zopectl*, we can immediately see the changes:

![Secondary Nav](/posts/extending-zenoss-navigations/zenoss_secondary_nav.jpg)

## The Actual Pages

We have created different types of links that lead to new pages where we would display new custom content. But how do we create these new pages? This is a whole topic in itself and it's why I will go over it in a future post.

_**UPDATE**_: Check out how to create custom pages in Zenoss in [this post](/posts/custom-pages-in-zenoss.html).