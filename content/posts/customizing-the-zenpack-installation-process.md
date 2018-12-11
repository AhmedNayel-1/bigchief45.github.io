---
date: '2017-01-17'
tags:
- zenoss
- zenpacks
- zenpacklib
- python
title: Customizing the ZenPack Installation Process
---

There are some circumstances where we need to perform certain tasks in our ZenPack the moment it is installed. We can achieve this using Python by placing this logic inside the ZenPack's top directory's `__init__.py` file. When creating a fresh ZenPack using **zenpacklib**, this `__init__.py` file will contain the following contents:

```python
from . import zenpacklib

CFG = zenpacklib.load_yaml()
```

To add custom functionality that gets executed when the ZenPack is installed, we need to extend the `install` method of the `ZenPack` class. Below the original code, we can proceed to do so:

```python
class ZenPack(schema.ZenPack):
    def install(self, app):
        # Our custom logic here

        super(ZenPack, self).install(app)
```

No other imports are necessary. Notice the last line of the `install` method, this is where the ZenPack gets installed.

For the purpuse of giving an example, Let's say that our ZenPack creates two new [zProperties](https://zenpack-sdk.zenoss.com/en/latest/yaml-zProperties.html), one property to store an API key, and the other one to store a URL. Moreover let's say that we obtain these values from somewhere and we want to assign them **automatically** to the properties upon the installation of the ZenPack.

These two new properties are defined in `zenpack.yaml`:

```yaml
name: ZenPacks.aalvarez.MyZenPack

zProperties:
  zMyApiUrl:
    category: MyApi
    type: string

  zMyApiKey:
    category: MyApi
    type: string
```

<!--more-->

Then we add the logic to the `__init__.py` file:

```python
class ZenPack(schema.ZenPack):
    def install(self, app):
        self._set_api_config()
        super(ZenPack, self).install(app)

    def _set_api_config(self):
        # Let's assume the values are stored in a text file
        with open('api_conf') as f:
          api_url = f.readline()
          api_key = f.readline()

          try:
              self.dmd.Devices.setZenProperty('zMyApiUrl', api_url)
              self.dmd.Devices.setZenProperty('zMyApiKey', api_key)
          except Exception as e:
              pass

          f.close()
```

When the ZenPack is installed, the above code will be executed and the zProperties will be assigned the values obtained from the text file. This is just one of the many possible tasks that you might need to perform upon installation.

Another good example is the **appending** of additional modeler plugins to certain device class. This I will try to cover in a future post.