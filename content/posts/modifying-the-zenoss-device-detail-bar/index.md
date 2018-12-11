---
date: '2016-11-08'
tags:
- zenoss
- extjs
- monitoring
- javascript
- ui
- zenpacks
- sysadmin
title: Modifying the Zenoss Device Detail Bar
---

The Zenoss Core [**ExtJS**](https://www.sencha.com/products/extjs/) graphic user interface is divided into many different components. In this post I will go over on how we can modify the device detail bar to display additional custom information for devices, by creating a custom ZenPack.

Zenoss Core 4 uses ExtJS 4 JavaScript framework to manage all the user interface components. These components can be found in `$ZENHOME/Products/ZenUI3/browser/resources/js/zenoss`, and as you would expect, the device detail bar component is also located there.

## The Device Detail Bar

This is the detail bar located on the device view page which shows the device's icon, name, events, status, production state, and priority. The JavaScript source code for this component can be found in `DeviceDetailBar.js`

![Device Detail Bar](/posts/modifying-the-zenoss-device-detail-bar/device_detail_bar.png)

However since we are going to **_extend_** this component through a ZenPack, we will not modify that source. Instead, we will add new code to use ExtJS to add our custom data displays.

## Extending The Component, Through ZenPacks

Let's assume we are starting with a freshly created ZenPack, which adds a new `power_status` integer field to certain devices, according to its `zenpack.yaml` file:

```yaml
# ...

classes:
  CustomDevice:
    base: [zenpacklib.Device]
    label: Custom Device
    properties:
      power_status:
        type: boolean

```

What we want is to display this value in the device's detail bar, similar to the device's ping status display.

<!--more-->

We will proceed to create a new directory inside the ZenPack, where UI modifications will be placed, and create a new `resources/device.js` (in this case, the `device` file name specifies that the JavaScript will be loaded for a custom device type) JavaScript file that will use ExtJS to extend the user interface:

-> If you want to have your JavaScript loaded for all Zenoss pages, put it in `resources/global.js`, and if you want it to only apply to your custom device type(s), put it in `resources/device.js`. If zenpacklib detects the presence of either of these files it will wire up the ZCML stuff for you automatically. See [this issue](https://github.com/zenoss/ZenPacks.zenoss.ZenPackLib/issues/56) on Github for more information.

**device.js**:

```javascript
Ext.onReady(function() {
  var DEVICE_DETAIL_BAR_ID = 'devdetailbar';

  Ext.ComponentMgr.onAvailable(DEVICE_DETAIL_BAR_ID, function() {
    var detailBar = Ext.getCmp(DEVICE_DETAIL_BAR_ID);

    // First, we create the new Power Status item
    var powerStatusItem = Zenoss.DeviceDetailItem.create({
        ref: 'pstatusitem',
        width: 98,
        label: _t('Power Status'),
        id: 'pstatusitem'
    });

    detailBar.addDeviceDetailBarItem(powerStatusItem, function(bar, data) {
        detailBar.pstatusitem.setText(Zenoss.render.pingStatusLarge(data.power_status));
    },
    ['power_status']);

  });
});

```

Very simple. After installing the ZenPack, restarting *zenhub* and *zopectl* services, you should be able to see the changes.

Now let's go over the code and understand what's going on.

## The DeviceDetailItem

Basically every item in the bar separated by the "|" character is actually an instance of the `Zenoss.DeviceDetailItem` class, which is also defined in `DeviceDetailBar.js`. In the code above, we are defining a new instance of this class and adding it to the detail bar. In particular, we are interested in these fields:

**ref:** The reference string for this `DeviceDetailItem`. Once set, it is possible to get this item using JavaScript in this way:

```javascript
var detailBar = Ext.getCmp('devdetailbar');
var item = detailBar.<ref>;

// Other existing items can also by obtained by their reference string,
// Available in the DeviceDetailBar.js source code:
var status = detailBar.statusitem;
```

**id:** The id of this `DeviceDetailItem` instance.

## Adding The Item

Next, we call the detail bar's `addDeviceDetailBarItem` method to add our freshly instanced item. This method will receive 3 arguments:

1. **item**: A `DeviceDetailItem` object to add to the detail bar.
2. **fn**: A function that will be called when the item is added.
3. **added_keys**: And array of *string* keys, to be added to the detail bar's `contextKeys` array.

In our case, we should simply add a new key resembling the device attribute in `zenpack.yaml`, hence why we pass an array with only one key (`power_status`) to *added_keys*.

The function parameter is where things get interesting, and what took my a bit of time and effort to understand everything that goes behind it. As you can see, I passed in a function `function(bar, data)`. I named the 1st parameter this way after extensive inspection and playing with the web console, however we don't really this parameter. The 2nd one (`data`) however, is what we will use to obtain the value of our `power_status` attribute.

Once we have this value, we are then setting it as the `DeviceDetailItem`'s text, but we are first passing it through a [Zenoss renderer](/posts/zenoss-monitoring-template-data-points.html). This what will change the display from a simple `True` or `False` value, to the UP or DOWN status with icon that you can already see with the ping status.

## Testing the Item

For quick testing, we can quickly open up a *zendmd* console as the `zenoss` user, and assign a boolean value to a device's `power_status` attribute.

```python
device = find("<hostname>")
device.power_status = False
commit()
```

The result should appear immediately after refreshing:

![Power Status](/posts/modifying-the-zenoss-device-detail-bar/detail_bar_power_down.jpg)

Don't mind the white background on the detail bar shown above, I am using a different skin in my Zenoss UI.