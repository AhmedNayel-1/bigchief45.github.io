---
date: '2017-01-20'
tags:
- zenoss
- python
- zenpacks
- monitoring
- zenpacklib
title: Appending Modeler Plugins in ZenPacks
---

When creating ZenPacks using zenpacklib, assigning modeler plugins to device classes will cause all the device class's modeler plugins to be **replaced** by the new modeler plugins assigned by the ZenPack. Obviously most of the time this is not the behaviour we want. What we really want is that the new modeler plugins are simply *added* to the device class's list of modeler plugins.

In a previous post I explained how we can [customize the ZenPacks installation process](/posts/customizing-the-zenpack-installation-process.html) to perform additional tasks. The way to append new modeler plugins to a device class follows this concept.

Let's assume that we have the [OpenStack Infrastructure ZenPack](http://wiki.zenoss.org/ZenPack:OpenStack_(Provider_View)) installed in our Zenoss Core. This ZenPack adds some custom modeler plugins to the `/Server/SSH/Linux/NovaHost` device class. We want our custom ZenPack to add *new* modeler plugins to this device class without replacing the ones added by the OpenStack ZenPack.

This will be done upon installation (like in the previous post) inside the `__init__.py` file in the ZenPack top directory. This is how the code looks like:

<!--more-->

```python
from . import zenpacklib

zenpacklib.load_yaml()

from . import schema


class ZenPack(schema.ZenPack):
    def install(self, app):
        self._update_plugins('/Server/SSH/Linux/NovaHost')

        # Call super last to perform the rest of the installation
        super(ZenPack, self).install(app)

    def _update_plugins(self, organizer):
        try:
            # NovaHost device class
            novahost_dc = self.dmd.Devices.getOrganizer(organizer)
        except Exception:
            # Device class doesn't exist.
            pass
        else:
            # Our ZenPack's Modeler Plugins
            myPlugins = ['aalvarez.snmp.HardDisk', 'aalvarez.snmp.RaidCard']

            # Append Plugins to NovaHost's existing plugins
            zCollectorPlugins = list(novahost_dc.zCollectorPlugins) + myPlugins

            # Assign to the device class
            self.device_classes['/Server/SSH/Linux/NovaHost'].zProperties['zCollectorPlugins'] = zCollectorPlugins

```

The key concepts that we can gather from this code are:

- We can obtain a device class object using the *dmd* `getOrganizer()` method.
- We can obtain a list of modeler plugins strings of the device class using `zCollectorPlugins` property of the device class object.
- We can make use of `self.device_classes[].zProperties[]` inside `__init__.py` to set new values.

~> When appending your ZenPack's modeler plugins using this approach, it is no longer necessary for you to specify this list of modeler plugins in the `zenpack.yaml` file.

### Some Gotchas

The `self.device_classes[]` array of device classes belongs to the ZenPack instance, and if this device class is not declared in the YAML file with zProperties like this:

```yaml
device_classes:
  /Server/SSH/Linux/NovaHost:
    zProperties:
      # ...
```

It will raise a `KeyError`.

Fortunately I found a workaround for this. Instead of using `self.device_classes[]`, we will directly set the plugins into the organizer object obtained using DMD:

```python
MY_PLUGINS = ['aalvarez.Interface', 'aalvarez.snmp.HardDisk']

class ZenPack(schema.ZenPack):

    def install(self, app):
        self._update_plugins('/Server/SSH/Linux/NovaHost')

        super(ZenPack, self).install(app)

    def _update_plugins(self, organizer):
        try:
            dc = self.dmd.Devices.getOrganizer(organizer)
        except Exception as e:
            log.error(e)
        else:
            dc.setZenProperty(
                'zCollectorPlugins', dc.zCollectorPlugins + MY_PLUGINS)

```

As we can see, we use a `setZenProperty` method to do this. Since the ZenPack will be installed shortly after this, no `commit()` call is needed.

Now When the ZenPack is installed these new modeler plugins will be appended to the list, without overriding the previous plugins.

## Appending Monitoring Templates

A similar approach can be used to append monitoring templates to a specific device class as well:

```python
    def _update_templates(self, organizer):
        try:
            dc = self.dmd.Devices.getOrganizer(organizer)
        except Exception as e:
            log.error(e)
        else:
            dc.setZenProperty(
                'zDeviceTemplates', dc.zDeviceTemplates + MY_TEMPLATES)

```

## References

1. [ZenPacks.zenoss.OpenStackInfrastructure](https://github.com/zenoss/ZenPacks.zenoss.OpenStackInfrastructure)
2. [ZenPackLib Issue #151: Multiple ZenPacks affecting same device class](https://github.com/zenoss/ZenPacks.zenoss.ZenPackLib/issues/151)
3. ZenPack Developer's Guide v1.0.1 - Jane Curry, page 134