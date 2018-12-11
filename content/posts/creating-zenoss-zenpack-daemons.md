---
date: '2016-11-07'
tags:
- zenoss
- zenpacks
- daemons
- monitoring
- python
- devops
- linux
- zenpacklib
title: Creating Zenoss ZenPack Daemons
---

ZenPacks are powerful custom add-ons that can help us extend Zenoss's functionality. In this post I will go over on how to create a ZenPack that adds a custom daemon to the existing Zenoss daemons and runs on a configured cycle time to perform custom tasks. We will achieve this by creating the ZenPack using [**zenpacklib**](http://zenpacklib.zenoss.com/en/latest/index.html), but it is also possible to create it from the Zenoss user interface.

## About zenpacklib

**zenpacklib** is a Python library developed by the Zenoss team to facilitate the process of creating ZenPacks, specially ZenPacks that deal with modeling and monitoring devices and components. Most of the newer ZenPacks that are being released are now being built with zenpacklib.

We can obtain zenpacklib by running the following commands:

```
wget http://zenpacklib.zenoss.com/zenpacklib.py
chmod 755 zenpacklib.py
```

This will download the zenpacklib Python library and give it executable permissions.

## Creating the ZenPack

Using the zenpacklib file we just downloaded, we proceed to create a new fresh ZenPack:

```
./zenpacklib.py create ZenPacks.<your_namespace>.<zenpack_name>
```

This will create the ZenPack base directory with the necessary base files.

Now we go into this directory to begin.

```
cd ZenPacks.<your_namespace>.<zenpack_name>
```

## Creating the ZenPack Daemon

Our custom daemon declaration will be located in a directory named `daemons`, inside our ZenPack directory:

```
mkdir ZenPacks.<your_namespace>.<zenpack_name>/<your_namespace>/<zenpack_name>/daemons
```

Here we will create a new Bashscript file with the name of our daemon. In this case we will name it `mydaemon`:

```bash
#! /usr/bin/env bash

DAEMON_NAME="mydaemon"

. $ZENHOME/bin/zenfunctions

MYPATH=`python -c "import os.path; print os.path.realpath('$0')"` THISDIR=`dirname $MYPATH` PRGHOME=`dirname $THISDIR` PRGNAME=$DAEMON_NAME.py CFGFILE=$CFGDIR/$DAEMON_NAME.conf

generic "$@"

```

Once the ZenPack is installed, files under this `daemons` directory will become executable (`chmod 0755`), a symlink to the file will be created in `$ZENHOME/bin`, and a configuration file will be generated in `$ZENHOME/etc/<daemon_name>.conf`

**NOTE:** If you created your ZenPack using the Zenoss user interface, the `daemons` directory will also be automatically created, and will contain an example daemon file named `zenexample` with code similar to the one above. In this case you should simply replace the necessary values.

<!--more-->

## Programming the Daemon's Logic

We will program our daemon using Python, by creating a Python file within the ZenPack Directory using the daemon's name, in this case `mydaemon.py`. This python code will be executed when the daemon is started or during a scheduled execution.

**NOTE:** If you created your ZenPack using the Zenoss user interface, a `zenexample.py` file will be automatically created. This file contains the boiler plate code which implements the necessary interfaces to begin building the daemon.

### Daemon Interfaces

The daemon code will need to implement the following interfaces:

**ICollectorPreferences**:

- The daemon's preferences will be defined here.
- Configuration Service is specified here (more on this in a bit).
- Here we can set `cycleInterval` and `configCycleInterval` values.
- We can also declare and assign global variables that the daemon tasks can use.

**IScheduledTask**:

- Represents each task associated to one device.
- The scheduler will schedule each task accordingly.
- Implements `doTask()` method. This is where we put all the collector daemon logic.
- Other custom methods can be called inside the `doTask()` method.


Here is an example of a daemon code:

```python
# This is an example of a custom collector daemon.

import logging
log = logging.getLogger('zen.Example')

import Globals
import zope.component
import zope.interface

from twisted.internet import defer

from Products.ZenCollector.daemon import CollectorDaemon
from Products.ZenCollector.interfaces \
    import ICollectorPreferences, IScheduledTask, IEventService, IDataService

from Products.ZenCollector.tasks \
    import SimpleTaskFactory, SimpleTaskSplitter, TaskStates

from Products.ZenUtils.observable import ObservableMixin

# unused is way to keep Python linters from complaining about imports that we
# don't explicitely use. Occasionally there is a valid reason to do this.
from Products.ZenUtils.Utils import unused

# We must import our ConfigService here so zenhub will allow it to be
# serialized and deserialized. We'll declare it unused to satisfy linters.
from ZenPacks.NAMESPACE.PACKNAME.services.ExampleConfigService \
    import ExampleConfigService

unused(Globals)
unused(ExampleConfigService)


# Your implementation of ICollectorPreferences is where you can handle custom
# command line (or config file) options and do global configuration of the
# daemon.
class ZenExamplePreferences(object):
    zope.interface.implements(ICollectorPreferences)

    def __init__(self):
        self.collectorName = 'zenexample'
        self.configurationService = \
            "ZenPacks.NAMESPACE.PACKNAME.services.ExampleConfigService"

        # How often the daemon will collect each device. Specified in seconds.
        self.cycleInterval = 5 * 60

        # How often the daemon will reload configuration. In seconds.
        self.configCycleInterval = 5 * 60

        self.options = None

    def buildOptions(self, parser):
        """
        Required to implement the ICollectorPreferences interface.
        """
        pass

    def postStartup(self):
        """
        Required to implement the ICollectorPreferences interface.
        """
        pass


# The implementation of IScheduledTask for your daemon is usually where most
# of the work is done. This is where you implement the specific logic required
# to collect data.
class ZenExampleTask(ObservableMixin):
    zope.interface.implements(IScheduledTask)

    def __init__(self, taskName, deviceId, interval, taskConfig):
        super(ZenExampleTask, self).__init__()
        self._taskConfig = taskConfig

        self._eventService = zope.component.queryUtility(IEventService)
        self._dataService = zope.component.queryUtility(IDataService)
        self._preferences = zope.component.queryUtility(
            ICollectorPreferences, 'zenexample')

        # All of these properties are required to implement the IScheduledTask
        # interface.
        self.name = taskName
        self.configId = deviceId
        self.interval = interval
        self.state = TaskStates.STATE_IDLE

    # doTask is where the collector logic should go. It is also required to
    # implement the IScheduledTask interface. It will be called directly by the
    # framework when it's this task's turn to run.
    def doTask(self):
        # This method must return a deferred because the collector framework
        # is asynchronous.
        d = defer.Deferred()
        return d

    # cleanup is required to implement the IScheduledTask interface.
    def cleanup(self):
        pass


if __name__ == '__main__':
    myPreferences = ZenExamplePreferences()
    myTaskFactory = SimpleTaskFactory(ZenExampleTask)
    myTaskSplitter = SimpleTaskSplitter(myTaskFactory)

    daemon = CollectorDaemon(myPreferences, myTaskSplitter)
    daemon.run()

```

Note that the `doTask()` method is the logic that will be executed on each of the daemon's cycle. It is on that method where you should write any necessary collection or monitoring logic.

### Configuration Services

Configuration Services are Zenhub services that run inside the Zenhub daemon and are responsible for all the interaction with collector daemons. Configuration services for our daemon are Python programs that are placed in `$ZP_DIR/services`.

If you created your ZenPack using the user interface, you will find an example configuration service in this directory.

The configuration service is loaded by our daemon in the `Preferences` class. This service will basically fetch all the devices we want to work with, along with their data sources, and will provide them to the daemon.

A configuration service has two important methods:

`_filterDevice()`: In this method we can filter the devices we want to work with. Example: We only want to work with devices that have the `Power` data source.

`_createDeviceProxy()`: A proxy represents the list of devices that will be sent to the daemon. Calls to other custom methods can be made inside this method. `proxy.datapoints` is the list that contains all the data points for a device. We can append dictionaries of data into this list.

Here is an complete example of a configuration service:

```python
"""
ExampleConfigService
ZenHub service for providing configuration to the zenexample collector daemon.

    This provides the daemon with a dictionary of datapoints for every device.
"""

import logging
log = logging.getLogger('zen.mydaemon')

import Globals
from Products.ZenUtils.Utils import unused
from Products.ZenCollector.services.config import CollectorConfigService

unused(Globals)

# Your daemon configuration service should almost certainly subclass
# CollectorConfigService to make it as easy as possible for you to implement.
class PowerMonConfigService(CollectorConfigService):
    """
    ZenHub service for the zenexample collector daemon.
    """

    # When the collector daemon requests a list of devices to poll from ZenHub
    # your service can filter the devices that are returned by implementing
    # this _filterDevice method. If _filterDevice returns True for a device,
    # it will be returned to the collector. If _filterDevice returns False, the
    # collector daemon won't collect from it.
    def _filterDevice(self, device):
        # First use standard filtering.
        filter = CollectorConfigService._filterDevice(self, device)

        # If the standard filtering logic said the device shouldn't be filtered
        # we can setup some other contraint.

        has_flag = False			# Flag to determine if should filter devise
        if filter:
           # Return only devices that have a valid value for Power Data Point (Assigned by ServerMonitor ZenPack)
           try:
              if device.getRRDValue('Power') != None:
                 has_flag = True
           except Exception as e:
              print e

        return CollectorConfigService._filterDevice(self, device) and has_flag

    # The _createDeviceProxy method allows you to build up the DeviceProxy
    # object that will be sent to the collector daemon. Whatever is returned
    # from this method will be sent as the device's representation to the
    # collector daemon. Use serializable types. DeviceProxy works, as do any
    # simple Python types.
    def _createDeviceProxy(self, device):
        proxy = CollectorConfigService._createDeviceProxy(self, device)

        proxy.configCycleInterval = 5 * 60 					# 5 minutes
        proxy.datapoints = []

        perfServer = device.getPerformanceServer()

        self._getPowerDp(proxy, device, device.id, None, perfServer)


        return proxy

    # This is not a method we must implement. It is used by the custom
    # _createDeviceProxy method above.
    def _getPowerDp(
            self, proxy, deviceOrComponent, deviceId, componentId, perfServer
            ):

        try:
           # Get the ServerDevice RRD Template. Specified by the ServerMonitor ZenPack
           template = deviceOrComponent.getRRDTemplateByName('ServerDevice')


           # Get the Power data point for the device. Specified by the ServerMonitor ZenPack
           dp = template.getRRDDataPoint('Power')

           # Get the value
           dp_value = deviceOrComponent.getRRDValue('Power')

           dpInfo = dict(
              devId = deviceId,
              dpId = dp.getId(),
              rrdCmd = perfServer.getDefaultRRDCreateCommand(),
              dpValue = dp_value
              )

           proxy.datapoints.append(dpInfo)

        except Exception as e:
           print e


# For diagnostic purposes, allow the user to show the results of the
# proxy creation.
# Run this service as a script to see which devices will be sent to the daemon.
# Add the --device=name flag to see the detailed contents of the proxy that
# will be sent to the daemon
#
if __name__ == '__main__':
    from Products.ZenHub.ServiceTester import ServiceTester
    tester = ServiceTester(PowerMonConfigService)
    def printer(config):
        # Fill this out
        print config.datapoints


    tester.printDeviceProxy = printer
    tester.showDeviceInfo()
```

## Daemon Logs

Log files generated by the daemon will be placed in a file in `$ZENHOME/log/<daemon_name>.log`. It is possible that the `INFO` and `DEBUG` logs will not show in the file, if this is the case then we can add the following code to the daemon file, after setting the logger:

```python
import logging
log = logging.getLogger('zen.DAEMON_NAME')
logging.basicConfig() # Add this new line
```

Alternatively you can set the `logseverity 10` (default is 20) configuration in the daemon configuration. This will make the daemon show DEBUG level logs.

## Daemon Configuration

You can find your daemon's configuration file under `$ZENHOME/etc/<daemon_name>.conf`. It is also possible to view and edit this configuration from the Zenoss user interface by navigating to *Advanced > Daemons*, where you will see the list of all the daemons, including your ZenPack's new daemon.

-> **If no configuration file is generated**: Manually create a `$ZENHOME/etc/<daemon_name>.conf` file. You can copy the contents of other daemon's configuration file and modify accordingly. Alternatively you can run the following command: `<daemon_name> genconf`.

## Manipulating the Daemon

The daemon will run and collect depending on the cycle interval values configured in the code, however we can still manipulate the daemon just like the other Zenoss daemons:

```
Usage: /usr/local/zenoss/bin/servermond {run|start|stop|restart|status|help|genconf|genxmlconfigs|debug|stats} [options]

  where the commands are:

    run     - start the program but don't put it in the background.
              NB: This mode is good for debugging.

    start   - start the program in daemon mode -- running in the background,
              detached from the shell

    stop    - stop the program

    restart - stop and then start the program
              NB: Sometimes the start command will run before the daemon
                  has terminated.  If this happens just re-run the command.

    status  - Check the status of a daemon.  This will print the current
              process nuber if it is running.

    help    - display the options available for the daemon

    genconf - create an example configuration file with default settings

    genxmlconfigs - create an XML file with default settings

    debug   - toggle the logging of daemons between Debug level and the default

    stats   - display detailed statistics of the deamon

```