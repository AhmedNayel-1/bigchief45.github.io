---
date: '2017-06-27'
tags:
- zenoss
- python
- zenpacklib
- zenpacks
- zope
title: Extending Device Python Classes From Other ZenPacks
---

Recently I was struggling with trying to make two custom ZenPacks work together with device objects in the Zenoss database. My issue was that a main ZenPack (which would be installed first) would create a custom class that inherits from `Device`. This ZenPack would add a lot of properties and relationships with custom components. Then, a second optional ZenPack could be installed which would extend this same class with an additional property that would work along with a [Python data source](/posts/working-with-zenoss-python-data-sources.html).

The `zenpack.yaml` file for the first and main ZenPack would look something like this:

```yaml
# ZenPack1

classes:
  SpecialServer:
    base: [zenpacklib.Device]
    label: Special Server

  SpecialComponent:
    base: [zenpacklib.Component]
    label: Special Component
    properties:
      # ...

  AmazingComponent:
    base: [zenpacklib.Component]
    label: Amazing Component
    properties:
      # ...

class_relationships:
  - SpecialServer 1:MC SpecialComponent
  - SpecialServer 1:MC AmazingComponent
```

<!--more-->

So what I wanted was to somehow be able to extend this `SpecialServer` class and add a new property to it, all of this done from the **second** ZenPack. Initially I tried doing this using ZenPackLib, doing something along the lines of:

```yaml
# ZenPack2

classes:
  ZenPacks.aalvarez.ZenPack1.SpecialServer.SpecialServer:
    properties:
      my_new_property:
        type: boolean
        default: false
```

Hoping that zenpacklib would somehow be smart enough to just append this additional attribute. The above however did not work.

## ZenPack Monkey Patching

It turns out that the way to do this is to perform some [monkey patching](https://en.wikipedia.org/wiki/Monkey_patch) from the ZenPack. Monkey patching is the dynamic replacement of attributes at runtime.

When developing ZenPacks that perform monkey patching, there are some [guidelines](http://zenpackers.readthedocs.io/en/latest/monkeypatching.html) that can be followed for more organized code.

### ZenPack Patches Directory

First we must create a directory called `patches` in the ZenPack's main directory (where `zenpack.yaml` resides). Inside the `patches` directory, we will place a Python init file that will take the responsibility of validating that everything that will be monkey patched can be correctly imported when the ZenPack is installed:

**patches/__init__.py**:

```python
import logging
from importlib import import_module

log = logging.getLogger('zen.ZenPack2')


def optional_import(module_name, patch_module_name):
    try:
        import_module(module_name)
    except ImportError:
        pass
    else:
        try:
            import_module(
                '.{0}'.format(patch_module_name),
                'ZenPacks.aalvarez.ZenPack2.patches')
        except ImportError:
            log.exception('failed to apply %s patches', patch_module_name)


optional_import('ZenPacks.aalvarez.ZenPack1', 'ZenPack1')
```

For everything that we want to monkey patch, we will call the `optional_import` function with two arguments: The required import (in this case, the first ZenPack), and the name of the file that will contain the monkey patches (in this case `ZenPack1`). This will be created later and will reside in the same location as `__init__.py`.

=> After taking a look at official Zenoss ZenPacks that contain monkey patching, I discovered that monkey patches to the Zenoss Core source code should be placed inside a file called `platform.py`.

Since we used `ZenPack1` as the name (you can use any name), we will created a new file called `ZenPack1.py`:

**patches/ZenPack1.py**:

```python
import logging
log = logging.getLogger('zen.ZenPack2')

from Products.Zuul.infos import ProxyProperty

from ZenPacks.aalvarez.ZenPack1.SpecialServer import SpecialServer, SpecialServerInfo


# Add new property
SpecialServer.my_new_property = False
SpecialServer._properties += (
    {'id': 'my_new_property', 'type': 'boolean', 'mode': 'w'},
    )

# Make the property available through the API
SpcialServerInfo.my_new_property = ProxyProperty('my_new_property')
```

This file is directly monkeypatching the `SpecialServer` class from the ZenPack. To understand how these classes are constructed, you can take a look at the main parent class found at `$ZENHOME/Products/ZenModel/Device.py`.

Apart from the `SpecialServer` class, we are also importing its Info class to also assign the new property. This will make the property available through the API. Meaning that you can use the Zenoss JSON API to query the device information. This new property will be included in the JSON response results.

-> Info classes define a mapping between object attributes and interface classes for display in the GUI.
<br><br>
In ZenPacks, Info classes are located in `info.py` file. However when using ZenPackLib this is no longer necessary since ZenPackLib takes care of generating the necessary Info code from the YAML file.
<br><br>
The info.py file abstracts object attribute information saved in the Zope Object Database
(ZODB), that will be displayed to the user.

Lastly we need to add all this monkey patching logic to the installation process. This is done at the end of the ZenPack's main `__init__.py` file:

```python
# YAML loading here ...

# ...

# Patch last to avoid import recursion problems
from . import patches
```

And now our monkey patching is completed. When the ZenPack is installed, the new property will be added to `ZenPack1`'s `SpecialServer` class.

## References

1. [Monkey Patching in ZenPacks](http://zenpackers.readthedocs.io/en/latest/monkeypatching.html)
2. ZenPack Developer's Guide v1.0.1 - Jane Curry, page 176