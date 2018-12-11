---
date: '2016-12-14'
tags:
- ssh
- zenoss
- monitoring
- zenpacks
- python
- bash
title: SSH Monitoring in ZenPacks
---

Zenoss usually monitors and collects information using **SNMP** and **SSH** methods. A good example of is the [linux monitor ZenPack](http://wiki.zenoss.org/ZenPack:Linux_Monitor) which can collect information such as hard disks, interfaces, and file systems using **both** methods.

SNMP works by installing and configuring an SNMP agent on the machine we want to monitor. This agent will poll the machine for data, and this data can be retrieved by Zenoss using **[net-snmp](http://www.net-snmp.org/)**.

On the other hand, SSH works by configuring a username and password or a path to an SSH key zProperties. This will allow Zenoss to remotely access the host using SSH and execute the corresponding commands and return the corresponding information.

When developing ZenPacks, data collection using SNMP is a relatively common practice. There is even a very good tutorial on [SNMP monitoring using zenpacklib](https://zenpacklib.zenoss.com/en/latest/tutorial-snmp-device/index.html). When using SNMP, the modeler plugins are `SnmpPlugin` plugins that typically work using a set of [OIDs](http://www.dpstele.com/snmp/what-does-oid-network-elements.php) to determine exactly which data is to be modeled.

## SSH in Modeler Plugins

In order to make a modeler plugin utilize SSH as it's polling method we need to use a different type of plugin, the `CommandPlugin` plugin. The structure of this type of plugin is very similar to the `SnmpPlugin`, however there is one critical variable that must be implemented.

<!--more-->

A variable named `command` must be initialized and it must contain a string that exactly represents the command to be executed in a remote host Bash shell. The output will then be processed into a `results` variable that can be processed in the `process` method.

Let's take a look at a basic skeleton of this kind of plugin:

```python
"""Modeler plugin's description"""

from Products.DataCollector.plugins.CollectorPlugin import CommandPlugin
from Products.DataCollector.plugins.DataMaps import ObjectMap, RelationshipMap
from Products.ZenUtils.Utils import prepId

import json

class MyPlugin(CommandPlugin):
    command = 'sudo ceph -s -f json'

    def process(self, device, results, log):
        results = json.loads(results)

        log.info('Modeler {0} processing data for device {1}'.format(self.name(), device.id))

        return None
```

Notice where the `CommandPlugin` class is imported from. Other types of plugins can also be imported from nearby locations.

The importing of `ObjectMap` and `RelationshipMap` is for returning the processed results. These are objects that Zenoss can understand when modeling devices. They represent the corresponding attributes of devices and components, and the corresponding relationships between them. For example, a *linux device* has many *network interfaces*.

As mentioned before, the `command` variable is what tells the plugin which command should be executed through SSH. In this case I am using a command that returns some status data for [Ceph](http://ceph.com/) in JSON. I can then process this JSON data inside the `process` method, and finally return an `ObjectMap` or `RelationshipMap`, instead of returning `None`.

If the data is mapped correctly and all relationships are correctly defined (in `zenpack.yaml` if you are using zenpacklib), we should be able to see it in the user interface once we model the device:

![Ceph Monitors](/posts/ssh-monitoring-in-zenpacks/ceph_monitors.jpg)