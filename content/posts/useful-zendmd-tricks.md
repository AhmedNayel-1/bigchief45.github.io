---
date: '2017-02-14'
tags:
- zenoss
- zendmd
- python
- devops
- linux
title: Useful Zendmd Tricks
---

The [Zenoss Zendmd Tips Wiki](http://wiki.zenoss.org/Category:ZenDMD) page contains a few useful tricks using zendmd to perform tasks. In this post I am adding more tricks that I discover and learn along the way.

## Removing Device Classes

We can easily remove device classes within zendmd with a simple command. Assuming we want to remove the default "KVM" device class:

```python
dmd.Devices.manage_deleteOrganizer("/zport/dmd/Devices/KVM")
commit()
```

## Change Zenoss User's Password

Let's say we want to change the default *admin* user's password (`zenoss`) in the Ubuntu auto deploy:

```python
app.acl_users.userManager.updateUserPassword('admin', 'newpassword')
commit()
```

<!--more-->

## Creating Zendmd Scripts

We can create zendmd scripts that can be run in a zendmd environment when called. For example we can take one of the scripts above and place it in a file called `change_password.zendmd` (The *zendmd* extension is just good practice for identifying this script as a zendmd script):

```python
#!/usr/bin/env zendmd

app.acl_users.userManager.updateUserPassword('admin', 'newpassword')
commit()
```

Next we should give it executable permissions:

```
chmod 0755 change_password.zendmd
```

Finally we can execute the script:

```
./change_password.zendmd
```

## Obtaining zProperty Values

We can easily obtain values from zProperties added by ZenPacks:

```python
dmd.Devices.getProperty('zProp')
```

## Use zendmd as a Standalone Program

From a simple Python file, we can get access to zendmd by using the right imports. We can then work with the `dmd` object as usual:

```python
#!/usr/bin/env python
import Globals
from Products.ZenUtils.ZenScriptBase import ZenScriptBase
from transaction import commit

dmd = ZenScriptBase(connect=True).dmd
```