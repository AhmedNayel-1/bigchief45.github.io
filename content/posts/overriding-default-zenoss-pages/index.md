---
date: '2017-03-17'
tags:
- zenoss
- zope
- zenpacks
title: Overriding Default Zenoss Pages
---

While testing the [Layer 2 ZenPack](https://github.com/zenoss/ZenPacks.zenoss.Layer2), I noticed that the network map provided by the ZenPack was placed in the same page of the old default Zenoss's network map, replacing the latter which was made using Flash. After the ZenPack is installed, when you click on the *Network Map* secondary link in the Infrastructure page, you will get the new map instead.

![Network Map link](/posts/overriding-default-zenoss-pages/map_link.jpg)

This seemed pretty nice, and I was curious how they achieved this, so I started browsing around the source code. It turns out that this overriding is done in a file called `overrides.zcml`, which is placed in the ZenPack's top directory.

<!--more-->

**overrides.zcml**:

```xml
<?xml version = "1.0" encoding = "utf-8"?>
<configure
    xmlns="http://namespaces.zope.org/zope"
    xmlns:browser = "http://namespaces.zope.org/browser"
    xmlns:zcml="http://namespaces.zope.org/zcml"
    >

    <!-- Network map page -->
    <browser:page
        template="./networkMap.pt"
        name="networkMap"
        for="*"
        permission="zenoss.View"
        />
</configure>
```

In this file, they are overriding the network map page (named `networkMap`, which is a `browser:page`) to use a different template instead. This is a custom template that also resides in the ZenPack. In the case of the Layer 2 ZenPack, it is also located in the ZenPack's top directory, but you can specify a different location such as `./browser/templates/` which is very common template location in other ZenPacks.

Layer 2 ZenPack Network Map:

![Layer 2 ZenPack Network Map](https://github.com/zenoss/ZenPacks.zenoss.Layer2/blob/master/screenshots/layer2_network_map.png?raw=true)

The template is a `.pt` file that defines certain blocks in the document using TAL and METAL expressions to be filled with content, usually using JavaScript. Here is the `networkMap.pt` template used in the ZenPack:

```html
<!DOCTYPE html>

<tal:block metal:use-macro="context/page_macros/base-new">
    <tal:block metal:fill-slot="title">Network Map</tal:block>

    <tal:block metal:fill-slot="head-local">
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    </tal:block>

    <tal:block metal:fill-slot="script_afterLayout">
        <script type="text/javascript">
            Ext.onReady(function(){
                window.form_panel.render(Ext.getCmp('center_panel'));
            });
        </script>
    </tal:block>
</tal:block>
```