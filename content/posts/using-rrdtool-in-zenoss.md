---
date: '2016-11-22'
tags:
- rrdtool
- zenoss
- python
- monitoring
- sysadmin
- linux
title: Using RRDTool in Zenoss
---

[rrdtool](http://oss.oetiker.ch/rrdtool/) is an awesome high performance data logging and graphing tool for time series data. Zenoss Core uses RRDTool to collect, monitor, and graph peformance data for devices.

![RRD Tool](http://oss.oetiker.ch/rrdtool/stream-pop.png)

However Zenoss Core comes with built-in helper wrappers around RRDTool that makes using it within Zenoss much easier. These source code files can be found in `$ZENHOME/Products/ZenRRD/`.

## RRDUtil

Located in `$ZENHOME/Products/ZenRRD/RRDUtil.py`, this Python module contains many wrapper methods around the rrdtool library. These methods can help us write to, create new, and read `.rrd` files using Python.

We can easily import this module into our code, using the following import statement:

```python
from Products.ZenRRD.RRDUtil import RRDUtil
```

<!--more-->

### Writing to a Device's RRD File

Performance `.rrd` files for each device are located in `$ZENHOME/perf/Devices/$DEVICE_IP/`. All the RRD files for each graph in our **custom monitoring templates** will be located here. The values contained within each file is what the graph actually represents in the Zenoss graphic user interface.

Let's assume that we have a custom monitoring template that adds, monitors, and graphs a *power usage* data point. And that the value for this data point is collected periodically through a [ZenPack daemon](/posts/creating-zenoss-zenpack-daemons.html). This value is then written to the data point's `.rrd` file, called `Power_Power.rrd` for this example.

We can then use RRDUtil in our daemon's code to write to the RRD file:

```python
def _writeRRD(self, device, rrd_file_name, value):
    try:
        from Products.ZenRRD.RRDUtil import RRDUtil

        path = 'Devices/{0}/{1}'.format(device.id, rrd_file_name)
        rrd = RRDUtil('', 300)

        rrd_save_val = rrd.save(path, value, "GAUGE", min=0, max=None)

        log.info('Wrote to {0} with value {1}'.format(rrd.performancePath(path + '.rrd'), rrd_save_val))

    except Exception as e:
        summary = "Unable to save data value into RRD file {0} - Exception: {1}".format(rrd.performancePath(path + '.rrd'), e.message)
        log.error(summary)
```

First we need to build a correct path string that points to the dev'ces RRD file we want to modify (Example: `$ZENHOME/perf/Devices/$DEVICE_IP/Power_Power.rrd`). So naturally we would pass the RRD file name (`Power_Power`) as the `rrd_file_name` parameter. We **do not** need to append the extension because the `save` method will do so when it's called.

-> RRD file names for devices are named according to the `dataSource_dataPoint` format. As shown in the monitoring template.

Since we are not creating a new file, we do not need to pass a create command to RRDUtil, hence why we pass a blank string as the first parameter.

Finally, the magic then happens in the `save` method, where we tell RRDUtil to save the value into the file, specified by the performance path. This performance path is generated using the path string we constructed before, inside the `put` (The `save` method actually makes a call to `put` in order to save the value) method's code:

```python
# $ZENHOME/Products/ZenRRD/RRDUtil.py

def put(self, path, value, rrdType, rrdCommand=None, cycleTime=None,
           min='U', max='U', useRRDDaemon=True, timestamp='N', start=None,
           allowStaleDatapoint=True):

    # ...
    filename = self.performancePath(path) + '.rrd'
```

=> After saving the value into the RRD file, the `save` method will fetch the latest value for the data point and return it. We can then use this value in our logs to confirm that the `save` method indeed saved the correct value.


## Useful Links

- https://nettikconsulting.wordpress.com/2010/09/25/modifying-the-code-where-rrd-files-are-saved/