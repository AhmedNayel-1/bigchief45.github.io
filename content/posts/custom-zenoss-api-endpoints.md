---
date: '2016-12-20'
tags:
- api
- zenoss
- zenpacks
- zope
- python
- javascript
title: Custom Zenoss API Endpoints
---

In a [previous post](/posts/the-zenoss-json-api.html) I went over the Zenoss JSON API and how it works inside the Zenoss Core. In this post we will apply the concepts learned in that post in order to create custom API endpoints within Zenoss, which can be accessed by the JavaScript front-end, *curl*, API clients, etc. All this new functionality added from a basic ZenPack.

## Creating an Endpoint

Assuming that we are starting with a new and fresh ZenPack created with [zenpacklib](https://zenpacklib.zenoss.com/en/latest/), we will proceed to create a simple endpoint.

Let's go ahead and create a file named `api.py` (can be any name) under the ZenPack's top directory. In this file we will import necessary modules, implement interfaces, and define our **routers** and **facades**. If you still don't know what routers and facades are and what they do, I suggest you first take a look at [The Zenoss JSON API](/posts/the-zenoss-json-api.html) post.

First, let's take a quick look at the imports:

```python
import os.path
from urlparse import urlparse
import subprocess

from zope.event import notify
from zope.interface import implements
from ZODB.transact import transact

from Products.ZenUtils.Ext import DirectRouter, DirectResponse
from Products import Zuul
from Products.Zuul.catalog.events import IndexingEvent
from Products.Zuul.facades import ZuulFacade
from Products.Zuul.interfaces import IFacade
from Products.Zuul.utils import ZuulMessageFactory as _t
from Products.ZenUtils.Utils import zenPath
```

Some imports are probably not needed, but the ones that are of our interest are imports such as `DirectRouter` and `DirectResponse`, which you might remember from the previous post. Additionally we are also importing the necessary facade, events, and interfaces imports.

<!--more-->

### Defining Routers and Facades

The router and the facade is what will make the endpoint do something once it's reached. Basically, the router will receive a request, it will then call the corresponding facade and obtain its results and result status, and then finally the router will pass this information as a response.

Before defining any router or facade we need to first define an interface for our facade:

```python
class IMyApiFacade(IFacade):
    def myAction(self, device_ip):
        """A test endpoint."""
```

Simple. The interface will inherit from `IFacade`, and its naming should follow this convention: `I<name>Facade`.

Now we proceed to define the facade that will implement this interface:

```python
class MyApiFacade(ZuulFacade):
    implements(IMyApiFacade)

    def myAction(self, device_ip):
        log.info('Performing MY ACTION on device {0}'.format(device_ip))

        try:
            pass
        except Exception as e:
            pass

        return True, 'Device {0} was processed'.format(device_ip)
```

Notice that we are implementing the interface, and we are now defining what the method declared in the interface will actually do. In this case we are just logging a log message and then returning the necessary values to the Router. The returned values must be a *boolean* result status and a *string* result message.

Finally we can define the router that will call this facade:

```python
class MyApiRouter(DirectRouter):
    def _getFacade(self):
        return Zuul.getFacade('myapi', self.context)

    def myAction(self, device_ip):
        facade = self._getFacade()
        success, message = facade.myAction(device_ip)

        if success:
            return DirectResponse.succeed(jobId=message)
        else:
            return DirectResponse.fail(message)
```

Pretty straight forward.

-> It is also common to see some ZenPacks define their routers inside a `routers.py` file and their facades in a `facades.py` file in the ZenPack's top directory.

### Gluing the Endpoint into Zenoss

Once the necessary classes and methods have been implemented, we now need to configure this implemenation into Zenoss. We do this by specifying some configurations inside the `configure.zcml` file in the ZenPack's top directory.

```xml
<?xml version="1.0" encoding="utf-8"?>
<configure
  xmlns="http://namespaces.zope.org/zope"
  xmlns:browser="http://namespaces.zope.org/browser"
  xmlns:zcml="http://namespaces.zope.org/zcml"
  >

  <!-- API Routers -->
  <include package="Products.ZenUtils.extdirect.zope" file="meta.zcml" />

  <browser:directRouter
    name="myapi_router"
    for="*"
    class=".api.MyApiRouter"
    namespace="Zenoss.remote"
    permission="zenoss.View"
    />

  <!-- API Facades -->
  <adapter
    name="myapi"
    provides=".api.IMyApiFacade"
    for="*"
    factory=".api.MyApiFacade"
    />
</configure>
```

If you take a look at the values for fields such as `class`, `provides`, and `factory` you will notice that these names and namespaces correspond to the implemenation we did previously. If these values do not match correctly, the endpoint won't be successfully attached to Zenoss.

Finally, install the ZenPack and restart Zenoss.

## Testing it Out

We can easily test this new endpoint by opening up a JavaScript developer console in Chrome or Firefox. We can reach the newly created endpoint like this:

```javascript
Zenoss.remote.MyApi.myAction({device_ip: ''}, function(result){
  console.log(result);
});
```

Other methods such as *curl* and POSTMAN can also be used. Here is an example using curl:

```bash
curl -u "admin:zenoss" -X POST -H "Content-Type: application/json" -d '{"action": "MyApiRouter", "method": "myAction", "data": [{"device_ip": "$DEVICE_IP"}], "tid": 1}' http://$ZENOSS_IP:8080/zport/dmd/myapi_router
```