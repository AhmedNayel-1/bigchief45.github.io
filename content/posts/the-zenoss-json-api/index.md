---
date: '2016-11-24'
tags:
- zenoss
- json
- api
- python
- extjs
- javascript
- curl
- zope
title: The Zenoss JSON API
---

The [Zenoss JSON API](http://wiki.zenoss.org/Working_with_the_JSON_API) allows us to obtain very important information of what is going on in Zenoss, such as device information and events. This API can be queried using [cURL](https://curl.haxx.se/) or with some wrappers provided by Zenoss, available in languages such as Bashscript, Python, and Java.

The API documentation can be downloaded [here](https://www.zenoss.com/sites/default/files/documentation/Zenoss_JSON_API_r5.0.4_d28.15.180_0.zip). In the documentation you can see the available endpoints and methods that can be used to obtain the data we need.

In this post I will cover how the Zenoss back-end JSON API works, and how the Zenoss's front-end (made using [ExtJS](https://www.sencha.com/products/extjs/)) interacts with it.

~> Even though Zenoss calls its API a *JSON API* (Simply because it returns data in JSON format), the API **is not** [JSON API specification](http://jsonapi.org/) compliant.

## Querying the API

To see the API in action, we can begin by making a simple query using `cURL`. Let's say we want to obtain all the available information of a specific device:

```bash
curl -u "admin:zenoss" -X POST -H "Content-Type: application/json" -d '{"action": "DeviceRouter", "method": "getInfo", "data": [{"uid": "/zport/dmd/Devices/Server/SSH/Linux/NovaHost/devices/$DEVICE_IP"}], "tid": 1}' http://$ZENOSS_HOST:8080/zport/dmd/device_router
```

The above request will return the information of the device in JSON format, assuming that we replace `$ZENOSS_HOST` with the IP address of our Zenoss server, and `$DEVICE_IP` with the IP address of the device we want to query.

This is all fine if all we need is querying the API and nothing else. But what if we really want to know **_how_** the API back-end works? How the endpoints are created? What are routers?

This is what we are gonna learn next.

<!--more-->

## The API Back-End: Routers & Facades

If you take a look at the previous curl command you will notice that we specify something like `{"action": "DeviceRouter", "method": "getInfo"}`. This sounds pretty intuitive, but what does it exactly mean?

### Routers

Zenoss Core 4 comes with many different built-in routers. These routers act as the API endpoints for specific things within Zenoss, such as devices, events, templates, etc. In total, Zenoss comes with the following routers:

- MessagingRouter
- EventsRouter
- ProcessRouter
- ServiceRouter
- DeviceRouter
- NetworkRouter
- TemplateRouter
- DetailNavRouter
- ReportRouter
- MibRouter
- ZenPackRouter

Naturally, each router will offer many "methods" that we can query by passing the necessary parameters. Just like the `getInfo` method from the `DeviceRouter` we used previously.

In the Zenoss Core 4 source code, these routers are defined and written in Python, and can be found in `$ZENHOME/Products/Zuul/routers/`.

A quick glance at the Device Router (`$ZENHOME/Products/Zuul/routers/device.py`) reveals the following:

```python
# ...

class DeviceRouter(TreeRouter):
    """
    A JSON/ExtDirect interface to operations on devices
    """

    # ...

    def getInfo(self, uid, keys=None):
        """
        Get the properties of a device or device organizer

        @type  uid: string
        @param uid: Unique identifier of an object
        @type  keys: list
        @param keys: (optional) List of keys to include in the returned
                     dictionary. If None then all keys will be returned
                     (default: None)
        @rtype:   DirectResponse
        @return:  B{Properties}
            - data: (dictionary) Object properties
            - disabled: (bool) If current user doesn't have permission to use setInfo
        """
        facade = self._getFacade()
        process = facade.getInfo(uid)
        data = Zuul.marshal(process, keys)
        disabled = not Zuul.checkPermission('Manage DMD', self.context)
        return DirectResponse(data=data, disabled=disabled)
```

Perfect. We can see the explanation of the method and its parameters written as comments, this is probably how the documentation is generated.

Although it seems that it's pretty obvious what is happening in the method, there are a few things that aren't very clear:

```python
facade = self._getFacade()
process = facade.getInfo(uid)
data = Zuul.marshal(process, keys)
```

*Facade*? *getFacade()*? It seems that the router method is actually not the method doing the work. Instead, it is calling a method with the same name, but from a different object, a **Facade** object.

### Facades

Zuul facades are also a part of the Python API. They have two main functions:

1. Given a unique indentified (UID), retrieve a ZenModel object and return info objects representing objects related to the retrieved object.
2. Given an info object, bind its properties to a ZenModel and save it.

So at this point it seems that when we query the API, we are querying a specific router, which then calls the method from a facade. The router then returns the data as a response.

We can find facades under `$ZENHOME/Products/Zuul/facades`. And just like the device router, there is also a device facade (`$ZENHOME/Products/Zuul/facades/devicefacade.py`).


-> **Routers** and **facades** provide a mean to handle objects. A facade is code that actually modifies objects; a router provides access to the facade, supplying the correct parameters. The router can be considered as a translation layer between the browser and the facade; thus, provided the name and parameters are mantained by the router, the underlying facade code may be changed.

~> Router names, their functions and their parameters must all match up between the *routers.py* and *facades.py* entries and the JavaScript that calls the router.

## The Front-End: ExtJS

With Zenoss Core 4 having the default routers and facades in place so that the API can correctly serve data, the front-end then queries this API using JavaScript and displays it accordingly in the graphic user interface.

To understand how this works, we need to understand some ExtJS components that are designed for this purpose.

### Ext.Direct

[Ext.Direct](https://docs.sencha.com/extjs/4.1.0/#!/api/Ext.direct.Manager) aims to streamline communication between the client and server by providing a single interface that reduces the amount of common code typically required to validate data and handle returned data packets (reading data, error conditions, etc).

Remember that the Zenoss routers inherit from The `DirectRouter` class. This base class parses an `Ext.Direct` request, which contains the name of the method and any data that should be passed, and routes the data to the appropriate method. It then receives the output of that call and puts it into the data structure expected by **Ext.Direct**. This `DirectRouter` class definition can be found in `$ZENHOME/Products/ZenUtils/extdirect/router.py`.

From the Ext.Direct documentation:

> *Ext.Direct utilizes a "router" on the server to direct requests from the client to the appropriate server-side method. Because the Ext.Direct API is completely platform-agnostic, you could completely swap out a Java based server solution and replace it with one that uses C# without changing the client side JavaScript at all.*

### Zenoss Remotes

Zenoss remotes are the front-end representations of the Zenoss back-end routers. We can easily interact with them in the Developer Console of our browser:

![Zenoss Remotes](/posts/the-zenoss-json-api/zenoss_remotes.jpg)

These default remotes are defined in `$ZENHOME/Products/Zuul/routers/configure.zcml`:

```xml
<!-- ... -->
<browser:directRouter
  name="device_router"
  for="*"
  class=".device.DeviceRouter"
  namespace="Zenoss.remote"
  timeout="180000"
  />
<!-- ... -->
```

### Querying the API

We can query the API in JavaScript using the Zenoss remotes. For example, we can do the same cURL query we did at the beginning of this post, but using JavaScript to interact with ExtJS and the Zenoss back-end.

In the browser console:

```javascript
Zenoss.remote.DeviceRouter.getDevices({uid: '/zport/dmd/Devices/Server/SSH/Linux/NovaHost/'}, function(result) {
  console.log(result.devices);
});
```

The above will output an object to the console for each existing device in the device class speficied for the `uid`.

## Final Thoughts

The way the back-end and API works in Zenoss is a bit complicated. With so many components working together both in Zenoss *and* in ExtJS, it takes some time to digest and understand what does what and how. However I believe this post should give a good primer before going in to more specific and complex scenarios.

It is also possible to create new routers, facades, and remotes from our ZenPacks so that we can add new custom API endpoints to serve custom data. Everything configured from a ZenPack, without having to alter the Zenoss Core source code. I hope I can cover this topic soon.