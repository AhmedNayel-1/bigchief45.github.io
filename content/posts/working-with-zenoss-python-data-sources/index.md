---
date: '2017-02-23'
tags:
- zenoss
- python
- monitoring
- zenpacks
- zenpacklib
title: Working With Zenoss Python Data Source Plugins
---

Using Python data source plugins in Zenoss is a great way to collect data, and probably a better way than using [command datasources](/posts/ssh-monitoring-in-zenpacks.html). Python data sources come with the introduction of the [PythonCollector ZenPack](https://www.zenoss.com/product/zenpacks/pythoncollector), so this ZenPack is required in order to start using Python data sources in our own ZenPacks.

Python data source plugins work exceptionally great in replacing data collection logic in [custom daemons](/posts/creating-zenoss-zenpack-daemons.html) written in Python. This means that the ZenPacks's code is greatly reduced because we do not have to create configuration service, and custom daemon code.

Moreover, while Python data source plugins are Python-based, we can still execute shell commands within the plugin.

## Example Scenario: BMC Power Status

For this post, I will be using an example where we will be executing an [ipmitool command](/posts/ipmi-baseboard-management-controllers.html) to check the power chassis status of a [BMC device](/posts/ipmi-baseboard-management-controllers.html).

If I run the following command from my shell:

```
ipmitool -H $BMC_IP -I lanplus -U admin -P admin power status
```

I get the following output:

```
Chassis Power is on
```

What we want is our data source plugin to periodically and continuously execute this command and obtain the value. Our ZenPack will then proceed to:

1. Map the value into a boolean property of a custon zenpacklib class.
2. Create a CRITICAL event if the power status is off or if the command fails. Create a CLEAR event if the power status is on.
3. Update the device model with the new property value.
4. [Display the property's value in the device detail bar using JavaScript](/posts/modifying-the-zenoss-device-detail-bar.html).

<!--more-->

### zenpack.yaml

To achieve the above, we will add some initial definitions to `zenpack.yaml`:

```yaml
name: ZenPacks.aalvarez.MyZenPack

zProperties:
  zBmcAddress:
    category: BMC
    type: string

  zIpmiUsername:
    category: IPMI
    type: string
    default: "admin"

  zIpmiPassword:
    category: IPMI
    type: password
    default: "admin"

classes:
    MyServer:
      base: [zenpacklib.Device]
      properties:
         power_status:
            type: boolean
            label: Power Status

```

The new zProperties will be used by the plugin when running the ipmitool command. We will add more definitions to this file later in this post.

## Creating the Plugin

When using zenpacklib, Python data source plugins are usually defined within a file called `dsplugins.py` in the ZenPack's top directory.

First, we will include the necessary imports:

```python
# Logging
import logging
log = logging.getLogger('zen.MyZenPack')

# Twisted Imports
from twisted.internet.defer import inlineCallbacks, returnValue

# PythonCollector Imports
from Products.DataCollector.plugins.DataMaps import ObjectMap
from ZenPacks.zenoss.PythonCollector.datasources.PythonDataSource import (
     PythonDataSourcePlugin,
     )

import subprocess
```

The [Twisted library](https://twistedmatrix.com/trac/) is imported so that the plugin can asynchronous requests. The `subprocess` module is imported so that we can run shell commands within Python.

Next, we will proceed to create our data source plugin class which will extend `PythonDataSourcePlugin`. Each type of datasource is defined as an object class and each class is associated with a DataSourcePlugin class. The DataSourcePlugin code includes methods for zenhub to determine what data needs passing to which collectors.

The basic skeleton is as follows:

```python
class BmcPowerStatus(PythonDataSourcePlugin):
    """BMC power status data source plugin."""

    # List of device attributes needed for collection
    proxy_attribures = (
        'zBmcAddress',
        'zIpmiUsername',
        'zIpmiPassword',
    )

    @classmethod
    def config_key(cls, datasource, context):
        # ...

    @classmethod
    def params(cls, datasource, context):
        # ...

    @inlineCallbacks
    def collect(self, config):
        # ...

    def onSuccess(self, result, config):
        # ...

    def onError(self, result, config):
        # ...

```

### Proxy Attributes

If the requirements of the data collector are simply just attributes of a device then they can be specified in a `proxy_attributes` statement of the `DataSourcePlugin` class. They are then accessed by zenhub and passed as part of the datasource configuration, to the collector.

In our case we are using the zProperties defined in `zenpack.yaml`.

### The config_key Method

The purpose of the `config_key` method is to split monitoring configuration into tasks that will be executed by the zenpython daemon. The zenpython daemon will create one task for each unique value returned from `config_key`. It should be used to optimize the way data is collected.

```python
@classmethod
def config_key(cls, datasource, context):
    return (
        context.device().id,
        datasource.getCycleTime(context),
        context.id,
        'myzenpack-powerstatus',
    )

```

The value returned by `config_key` will be used when zenpython logs. So adding something like "myzenpack-powerstatus" to the end makes it easy to see logs related to collecting alerts in the log file.

~> The `config_key` method will only be executed by zenhub. So you must restart zenhub if you make changes to the `config_key` method. This also means that if there’s an exception in the `config_key` method it will appear in the zenhub log, not zenpython.

### The params Method

Data collection may be in a remote collector which does not have direct access to the ZoDB database. If the collection daemon needs access to ZoDB data, then it has to be fetched by zenhub and included in the configuration that is passed to the collection daemon.

The purpose of the params method is to copy information from the Zenoss database into the config.datasources[*] that will be passed as an argument to the collect method. Since the collect method is run by zenpython it won’t have direct access to the database, so it relies on the params method to provide it with any information it will need to collect.

```python
@classmethod
def params(cls, datasource, context):
    return {
        'zBmcAddress': context.zBmcAddress,
        'zIpmiUsername': context.zIpmiUsername,
        'zIpmiPassword': context.zIpmiPassword,
        }

```

In our case we are also using and assigning the zProperties. These will be used by the *collect* method.

If you receive an error such as:

```
2017-02-24 09:50:03,818 ERROR zen.collector.config: Configuration for [DEVICE_NAME] unavailable -- is that the correct name?
```

This probably indicates that there is an issue with the `config_key` or `params` methods of the performance DataSourcePlugin. When making changes to the plugin, it is best to restart zenhub and zenpython and re-check the logs.

### The collect Method

This is where all the data collection logic is placed. It gets passed a config argument which for the most part has two useful properties: config.id and config.datasources. config.id will be the device’s id, and config.datasources is a list of the datasources that need to be collected.

You’ll see in the collect method that each datasource in config.datasources has some useful properties. datasource.component will be the id of the component against which the datasource is run, or blank in the case of a device-level monitoring template. datasource.params contains whatever the params method returned.

```python
@inlineCallbacks
def collect(self, config):
    log.debug("Collect for BMC Power Status ({0})".format(config.id))

    ds0 = config.datasources[0]
    results = {}

    # Collect using ipmitool
    power_status = False
    cmd_result = ''
    try:
        cmd = 'ipmitool -H {0} -I lanplus -U {1} -P {2} power status'.format(ds0.zBmcAddress, ds0.zIpmiUsername, ds0.zIpmiPassword)
        cmd_result = yield subprocess.check_output(cmd, shell=True).rstrip()
        log.info('Power Status for Device {0}: {1}'.format(ds0.zBmcAddress, cmd_result))
    except:
        log.error('Error when running ipmitool when collecting Power Status on BMC Address {0}'.format(ds0.zBmcAddress))

    if cmd_result == 'Chassis Power is on':
        power_status = True

    results['power_status'] = power_status

    returnValue(results)
```

Note how the method returns a Twisted deferred. The deferred results will be sent to *onResult* (not necessary to implement), then to either *onSuccess* or *onError* callbacks.

### The onSuccess and onError Methods

Called only on success or on error. This is where we tell the plugin what to do depending on the callback. They should return a data structure with zero or more events, values and maps. Note that `values` is a dictionary and `events` and `maps` are lists. Implementation of these methods is optional if *collect* already returns this data structure.

```python
def onSuccess(self, result, config):
    data = self.new_data()

    power_status = result['power_status']

    data['maps'].append(
        ObjectMap({
            'modname': 'ZenPacks.itri.BmcMonitor.BmcServer',
            'power_status': power_status,
            }))

    if power_status:
        data['events'].append({
            'device': config.id,
            'summary': '{0} BMC power status is now UP'.format(config.id),
            'severity': ZenEventClasses.Clear,
            'eventClassKey': 'bmcPowerStatus',
            })
    else:
        data['events'].append({
            'device': config.id,
            'summary': '{0} BMC power status is DOWN!'.format(config.id),
            'severity': ZenEventClasses.Critical,
            'eventClassKey': 'bmcPowerStatus',
            })

    data['events'].append({
        'device': config.id,
        'summary': 'BMC Power Status Collector: successful collection',
        'severity': ZenEventClasses.Clear,
        'eventKey': 'bmcPowerStatusCollectionError',
        'eventClassKey': 'bmcMonitorFailure',
        })

    return data

def onError(self, result, config):
    errmsg = 'BMC Power Status Collector: Error trying to collect.'
    log.error('{0}: {1}'.format(config.id, errmsg))

    data = self.new_data()

    data['events'].append({
        'device': config.id,
        'summary': errmsg,
        'severity': ZenEventClasses.Critical,
        'eventKey': 'bmcPowerStatusCollectionError',
        'eventClassKey': 'bmcMonitorFailure',
        })

    return data
```

Within the body of the success method we create a new data variable using `data = self.new_data()`. data is a place where we stick all of the collected events, values and maps. data looks like the following:

```python
data = {
    'events': [],
    'values': defaultdict(<type 'dict'>, {}),
    'maps': [],
}
```

Basically, it is within these methods that we can tell that plugin what to do depending on what we want to achieve. As a rule of thumb:

- When we want the plugin to generate events, we should append to `data['events']`.

- When we want the plugin to make changes to the Zenoss model (in a similar way to how a modeler plugin works), we append object maps or relationship maps to `data['maps']`.

- When we want the plugin to collect data points, we should append to `data['values']`.

~> When making changes to data source plugins, make sure to restart *zopectl*, *zenhub*, **and** *zenpython* so that Zenoss can recognize the changes.

## Creating the Monitoring Template

Now that the plugin is complete. We need to create a monitoring template that will contain the datasource that will use this data source plugin. We can easily define this new monitoring template in `zenpack.yaml`:

```yaml
device_classes:
  /BMC:
    remove: true
    zProperties:
      zPythonClass: ZenPacks.aalvarez.MyZenPack.MyServer
      zIpmiUsername: admin
      zIpmiPassword: admin
      zDeviceTemplates: [Device, BMC]
    templates:
      BMC:
        description: Monitoring BMC Devices
        targetPythonClass: ZenPacks.aalvarez.MyZenPack.MyServer
        datasources:
          powerStatus:
            type: Python
            plugin_classname: ZenPacks.aalvarez.MyZenPack.dsplugins.BmcPowerStatus
            cycletime: 30
```

With the code above we are creating a new monitoring template called BMC under a new `/BMC` device class. This template has a `powerStatus` data source with a cycle time of 30 seconds, and uses the plugin we just created which is `ZenPacks.aalvarez.MyZenPack.dsplugins.BmcPowerStatus`.

-> **What's the difference between a datasource and a datasource plugin?**
    <br /></br />
    A datasource is an instance of RRDDataSource. It’s the object that’s part of a monitoring template and stored in ZODB. A datasource plugin is not a persistent ZODB object. It’s a class that is used to perform collection of a specific subclass of RRDDataSource instance: PythonDataSource.
    <br /><br />
    Additionally, datasource plugins are a zenpython concept. So all PythonDataSources have PythonDataSourcePlugins, but other kinds of RRDDataSources do not

## Modifying the GUI

To add this new power status property to the device detail bar, you can simply refer to my [previous post](/posts/modifying-the-zenoss-device-detail-bar.html) on this very topic.

Lastly, install the ZenPack and restart Zenoss.

Now you can add a new device to the `/BMC` device class, configure the zProperties with real working values and see the data source plugin work its magic. Since the cycle time is 30 seconds, you will be able to see the power status light change very soon.

![Power status light using Python data source plugin](/posts/working-with-zenoss-python-data-sources/power_status.jpg)

## References

1. *Zenoss Data Sources through the eyes of the Python Collector ZenPack* by Jane Curry
2. [ZenPack SDK - Monitoring an HTTP API](https://zenpack-sdk.zenoss.com/en/latest/tutorial-http-api/index.html)
3. [Zenpacklib YAML Reference](https://zenpack-sdk.zenoss.com/en/latest/yaml-reference.html)
4. [ZenPackers Documentation - Datasources in Detail](http://zenpackers.readthedocs.io/en/latest/datasources.html#general-questions-and-answers)