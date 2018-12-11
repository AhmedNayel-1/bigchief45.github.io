---
date: '2016-11-10'
tags:
- zenoss
- extjs
- monitoring
- javascript
- ui
- zenpacks
- sysadmin
title: Modifying the Zenoss Infrastructure Grid
---

Continuing from my previous post, where I explained [how to modify the device detail bar from a ZenPack using ExtJS](/posts/modifying-the-zenoss-device-detail-bar.html), in this post I will explain how we can modify the device list grid shown in the infrastructure page.

## The Infrastructure Grid

This is the table in the infrastructure page that shows all devices being monitored by Zenoss. Default columns include *device name*, *device class*, *IP address*, *production state*, and *events*, as shown in the image below:

![Zenoss Infrastructure Grid](/posts/modifying-the-zenoss-infrastructure-grid/zenoss_device_grid.png)

However it would be nice to also include the power status we added to the device detail bar in the previous post, maybe even add the ping status as well (why Zenoss doesn't do this by default is beyond me).

## DevicePanels.js

The source code for the grid is found in `$ZENHOME/Products/ZenUI/browser/resources/js/zenoss/DevicePanels.js`. A quick glance at it and you will quickly find the definitions of the columns I mentioned earlier, defined in an array called `deviceColumns`.

<!--more-->

### Device Grid Panel

The grid panel object itself is an instance of a `Zenoss.DeviceGridPanel` class. Its ExtJS definition in the source code looks like this:

```javascript
/**
 * @class Zenoss.DeviceGridPanel
 * @extends Zenoss.FilterGridPanel
 * Main grid panel for displaying a device. Used on the It Infrastructure page.
 **/
Ext.define("Zenoss.DeviceGridPanel", {
  extend: "Zenoss.FilterGridPanel",
  alias: ['widget.DeviceGridPanel', 'widget.SimpleDeviceGridPanel'],
  lastHash: null,
  constructor: function(config) {
    var storeConfig = config.storeCfg || {};
    var store = Ext.create('Zenoss.DeviceStore', storeConfig);

    Ext.applyIf(config, {
        store: store,
        columns: deviceColumns
    });

    this.callParent(arguments);
    this.on('itemdblclick', this.onItemDblClick, this);
  },

  onItemDblClick: function(view, record) {
    window.location = record.get("uid");
  },
  applyOptions: function(options){
    // only request the visible columns
    var visibleColumns = Zenoss.util.filter(this.columns, function(c){
            return !c.hidden;
        }),
        keys = Ext.Array.pluck(visibleColumns, 'dataIndex');

    keys.push('ipAddressString');
    keys.push('pythonClass');
    Ext.apply(options.params, {
        keys: keys
    });
  }
});
```

The inheritance hierarchy for this class is quite a long one. Nevertheless, it is worth mentioning that the topmost parent is a `Ext.grid.Panel` class. The [documentation](https://docs.sencha.com/extjs/4.1.0/#!/api/Ext.grid.Panel) for this class is highly recommended.

Because we are now dealing with a ExtJS grid panel object, pulling and displaying data becomes a bit more complicated than the scenario where we modified the device detail bar. The reason is because this component has to deal with many other ExtJS components such as Models, Stores, and Proxies, to name a few.

## ExtJS Stores and Models

The grid panel class deals with other built-in ExtJs classes: [`Ext.data.Store`](https://docs.sencha.com/extjs/4.1.0/#!/api/Ext.data.Store) and [`Ext.data.Model`](https://docs.sencha.com/extjs/4.1.0/#!/api/Ext.data.Model).

A [**model**](https://docs.sencha.com/extjs/4.1.0/#!/api/Ext.data.Model) basically represents some object that your application manages. For example, one might define a Model for Users, Products, Cars, or any other real-world object that we want to model in the system. They are registered via the model manager, and are used by **stores**, which are in turn used by many of the data-bound components in Ext.

We can see the definition of the Zenoss device model:

```javascript
Ext.define('Zenoss.device.DeviceModel',{
  extend: 'Ext.data.Model',
  fields: [
    {name: 'uid', type: 'string'},
    {name: 'name', type: 'string'},
    {name: 'ipAddress', type: 'int'},
    {name: 'ipAddressString', type: 'string'},
    {name: 'productionState', type: 'string'},
    {name: 'serialNumber', type: 'string'},
    {name: 'tagNumber', type: 'string'},
    {name: 'hwManufacturer', type: 'object'},
    {name: 'hwModel', type: 'object'},
    {name: 'osManufacturer', type: 'object'},
    {name: 'osModel', type: 'object'},
    {name: 'collector', type: 'string'},
    {name: 'priority', type: 'string'},
    {name: 'systems', type: 'object'},
    {name: 'groups', type: 'object'},
    {name: 'location', type: 'object'},
    {name: 'events', type: 'object'},
    {name: 'availability', type: 'float'},
    {name: 'pythonClass', type: 'string'}
  ],
  idProperty: 'uid'
});

```

On the other hand, the [**Store**](https://docs.sencha.com/extjs/4.1.0/#!/api/Ext.data.Store) class encapsulates a client side cache of Model objects. Stores load data via a Proxy, and also provide functions for sorting, filtering and querying the model instances contained within it.

A Store is just a collection of Model instances - usually loaded from a server somewhere. Store can also maintain a set of added, updated and removed Model instances to be synchronized with the server via the Proxy.

We can also see the device store defined by Zenoss:

```javascript
Ext.define("Zenoss.DeviceStore", {
  alias: ['widget.DeviceStore'],
  extend: "Zenoss.DirectStore",
  constructor: function(config) {
    config = config || {};
    Ext.applyIf(config, {
      autoLoad: false,
      pageSize: Zenoss.settings.deviceGridBufferSize,
      model: 'Zenoss.device.DeviceModel',
      initialSortColumn: "name",
      directFn: Zenoss.remote.DeviceRouter.getDevices,
      root: 'devices'
    });
    this.callParent(arguments);
  }
});
```

If you look closely, you will notice that the store extends `Zenoss.DirectStore`. This is store acts as a base store parent class that Zenoss stores inherit from, somewhere up the hierarchy tree there will be a parent Zenoss store class that will end up extending `Ext.data.Store`.

Another important thing worth mentioning is the `model` field in the store. In this case, Zenoss is assigning the `Zenoss.device.DeviceModel` (previously shown) to this store.

Looking back at the defined model, we see that there is a big list of fields. However, the ping status is nowhere to be seen, and our power status is obviously not defined there either. This is the first hint as to what we should do first: **Add our fields to this model definition, from our ZenPack**.

## Modifying the Grid

We will handle the grid additions in a separate `resources/global.js` (In this case, `global` indicates that the JavaScript will be loaded for **all** Zenoss pages) file. In order to achieve what we want, this is the approach I took:

1. Obtain the grid and its `Store` object.
2. Add the two new  `Field`s to the `Zenoss.device.DeviceModel`.
3. Create two new and fresh `Ext.grid.column.Column` objects, each making reference to the new fields.
4. Iterate through the store's records (the devices shown in the grid) and for each record:
  - Query the Zenoss backend using `Zenoss.remote.DeviceRouter.getInfo` method to obtain the `status` and `power_status`.
  - Assign the obtained values to the model.
5. Insert both columns into the grid.
6. Refresh the grid.

The code that accomplishes the above is the following:

```javascript
Ext.onReady(function() {
  var DEVICE_GRID_ID = 'device_grid';

  Ext.ComponentMgr.onAvailable(DEVICE_GRID_ID, function() {
    var grid = Ext.getCmp(DEVICE_GRID_ID);
    var store = grid.getStore();

    // Add 'status' and 'power_status' fields to the Zenoss.device.DeviceModel model
    Zenoss.device.DeviceModel.prototype.fields.add(new Ext.data.Field({name: 'status', type: 'boolean'}));
    Zenoss.device.DeviceModel.prototype.fields.add(new Ext.data.Field({name: 'power_status', type: 'boolean'}));

    // Create the 'status' column
    var status_column = Ext.create('Ext.grid.column.Column', {
      id: 'status',
      width: 70,
      dataIndex: 'status',
      header: _t('Status'),
      renderer: Zenoss.render.pingStatus
    });

    var power_status_column = Ext.create('Ext.grid.column.Column', {
      id: 'power_status',
      width: 70,
      dataIndex: 'power_status',
      header: _t('Power Status'),
      renderer: Zenoss.render.pingStatus
    });

    // Obtain the Ping Status for each record in the store and assign it to the model
    store.each(function(record){
      Zenoss.remote.DeviceRouter.getInfo({uid: record.data.uid}, function(result){
        record.data.status = result.data.status;
        record.data.power_status = result.data.power_status;

        grid.getView().refresh();
      });
    });

    // Insert the status column into the device grid
    grid.headerCt.insert(1, status_column);
    grid.headerCt.insert(2, power_status_column);

    grid.getView().refresh();

  });
});

```

I want to mention that this is **NOT** the approach I wanted to implement initially. In fact, I am not a fan of even iterating through the store's records, but I could not make other approaches work at all. If I find a better solution to this, I will make a new post about it.

The good thing is that apparently the grid autorefreshes itself every few seconds without any extra configuration needed. One drawback however, is that the columns are not being inserted according to the index parameter passed to the `insert()` method. However, when I try it in the browser console it works perfectly. Very strange.

Anyways, this is the end result:

![Modified IT grid](/posts/modifying-the-zenoss-infrastructure-grid/modified_it_grid.jpg)