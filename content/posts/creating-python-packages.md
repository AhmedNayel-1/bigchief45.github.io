---
date: '2016-10-13'
tags:
- packaging
- python
- zenoss
title: Creating Python Packages
---

For a project involving Zenoss Core 4 and a HaaS solution maintained by another team, we needed a module to interact with the [Zenoss JSON API](http://wiki.zenoss.org/Working_with_the_JSON_API) to get the list of events for specific devices. Browsing around I found this [python-zenoss](https://github.com/iamseth/python-zenoss) module to work with the Zenoss JSON API. However I was experiencing some issues when installing it, so I decided to create my own Python package to provide a different way to interact with the Zenoss JSON API according to our specific needs.

The package would be installed locally using `pip`, and all its functionality should be easily accessible using `from` and `import` commands in Python.

To start working in our package we will create a base directory. The directory's name will resemble our package's name. For naming, we should following these guidelines:


- All lowercase
- Underscore-separated or no word separators at all (don’t use hyphens)


The package contents are the following:

```
my_api/
├── __init__.py
├── api.py
└── setup.py
```

<!--more-->

The `__init__.py` file tells Python that this directory should be treated as a Python package. Inside we can include some `import` statements to import the modules we need:

```python
from api import Api
```

In the above code `from api` refers to `api.py` inside our package, and `import Api` refers to the `Api` class defined in that same file. That is the class that represents the API access to the Zenoss JSON API.

Let's take a look at that class:

##### api.py

```python
class Api(object):
  def __init__(self, host=None, username='admin', password='zenoss', debug=False):
    """
    Initialize the API connection, log in, and store authentication cookie
    """
    self.__host = host

    # Use the HTTPCookieProcessor as urllib2 does not save cookies by default
    self.urlOpener = urllib2.build_opener(urllib2.HTTPCookieProcessor())
    if debug: self.urlOpener.add_handler(urllib2.HTTPHandler(debuglevel=1))
    self.reqCount = 1

    # Contruct POST params and submit login.
    loginParams = urllib.urlencode(dict(
                    __ac_name = username,
                    __ac_password = password,
                    submitted = 'true',
                    came_from = host + '/zport/dmd'))
    self.urlOpener.open(host + '/zport/acl_users/cookieAuthHelper/login',
                        loginParams)

```

Basically we are initializing an instance of `Api` by passing a hostname (which should be the `IP_ADDRESS:PORT` of your Zenoss instance), along with the Zenoss username and password. When the instance is created, it will try to authenticate with Zenoss.

If our `Api` instance authenticated successfully, we can begin calling our Python methods to query the Zenoss JSON API. As I mentioned in the beginning of this post, we wanted to get the events for specific devices, so we can add a method for that:

```python
def get_events(self, device=None, component=None, eventClass=None):
    data = dict(start=0, limit=100, dir='DESC', sort='severity')
    data['params'] = dict(severity=[5,4,3,2], eventState=[0])

    if device: data['params']['device'] = device
    if component: data['params']['component'] = component
    if eventClass: data['params']['eventClass'] = eventClass

    return self._router_request('EventsRouter', 'query', [data])['result']

```

Now the last piece of our Python package is the `setup.py` file. This file will contain the meta-data of our package, and is used by `pip` when installing the package in our system:

##### setup.py

```python
from setuptools import setup

setup(name='my_api',
    version='1.0.0',
    description='Zenoss API module',
    author='Andres Alvarez',
    author_email='myemail@email.com',
    license='MIT',
    py_modules=['pdcm',],
    zip_safe=False)

```

Once everything is ready we can proceed to install our package using `pip`:

`pip install my_api`

And once it is successfully installed, we can test that our package can be used by opening the Python interactive console (type `python` in your terminal)

```python
from my_api import Api
from pprint import pprint

api = Api(host='http://my-ip:8080', username='admin', password='zenoss')

events = api.get_events(device='HSL19023')['events']

pprint(events)
```