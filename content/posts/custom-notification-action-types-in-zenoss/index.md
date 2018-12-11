---
date: '2017-05-09'
tags:
- zenoss
- zenpack
- python
- zope
title: Custom Notification Action Types in Zenoss
---

In a [previous post](/posts/triggering-commands-from-events-in-zenoss.html) I talked about how we could create *command* type notifications to execute shell scripts when a trigger is fired by an event in Zenoss. Also, in a [more recent post](/posts/custom-triggers-and-notifications-in-a-zenpack.html) I explained how a ZenPack could automatically create these triggers and notifications when installed by defining them in JSON format.

In this post I will explain how to create additional custom action types that can be used by notifications for different purposes.

## Zenoss Default Notification Actions

By default, Zenoss comes with a built-in notification action types. You can see them when creating a new notification from the user interface:

![Zenoss Default Actions](/posts/custom-notification-action-types-in-zenoss/default_notifications.jpg)

These action types are:

- **Command**: Runs an executable script. Discussed in one of my [previous posts](/posts/triggering-commands-from-events-in-zenoss.html).
- **Email**: Sends an e-mail to a user.
- **Page**: Sends a message to a user's [pager](https://en.wikipedia.org/wiki/Pager), also known as *beeper*. Probably safe to say that this is not used by anyone anymore.
- **Syslog**: Logs a message to [syslog](https://en.wikipedia.org/wiki/Syslog)
- **SNMP Trap**: Sends an SNMP trap.

All these notifications are sent when an event matches a trigger rule.

## Creating the New Action

Next, we are going to learn how we can create and add a new fully functional custom action to this list, using a ZenPack. For this example, let's assume that we want to create a new SMS action to send SMS messages. Surely something more modern and useful than a Pager!

<!--more-->

### Creating the Interface

In our ZenPack's top directory, we create a file called `interfaces.py`. In this file we will define the contents (fields in the content pane) of the action:

**interfaces.py**:

```python
from zope.interface import Interface
from Products.Zuul.interfaces.actions import IActionContentInfo
from Products.Zuul.interfaces import IFacade
from Products.Zuul.form import schema
from Products.Zuul.utils import ZuulMessageFactory as _t
import textwrap

class ISmsActionContentInfo(IActionContentInfo):
    cellNumber = schema.TextLine(
        title = _t(u'Cellphone Number'),
        order=90,
    )

    message_body = schema.Text(
        title = _t(u'Message Body'),
        description = _t(u'The content of the SMS message'),
        order = 100,
        default = textwrap.dedent(text = u'''
            Device: ${evt/device}
            Component: ${evt/component}
            Severity: ${evt/severity}
            Time: ${evt/lastTime}
            Message:
            ${evt/message}
            ''')
    )
```

Very simple. We are only requiring two fields, the mobile number and the message's body, which I actually copied from the e-mail action. You can see that the message body makes use of TALES expression to obtain the data from the event (`evt`).

### Information Adapter

Next we will create the information adapter that will import the interface we just created. The adapter will then be registered using a `configure.zcml` file. In the ZenPack's top directory, we create a file called `info.py`:

**info.py**:

```python
from zope.interface import implements

from Products.Zuul.infos.actions import ActionContentInfo
from Products.Zuul.infos.actions import ActionFieldProperty

from ZenPacks.andres.Sms.interfaces import ISmsActionContentInfo

class SmsActionContentInfo(ActionContentInfo):
    implements(ISmsActionContentInfo)

    cellNumber = ActionFieldProperty(ISmsActionContentInfo, 'cellNumber')
    message_body = ActionFieldProperty(ISmsActionContentInfo, 'message_body')

```

Notice that we are using the ZenPack's (the ZenPack we are actually working with) full namespace to import the interface we created previously. The adapter will implement this interface and define the fields as `ActionFieldProperty` fields.

### Action Logic

Now we need to code the action's logic, that is, what the notification will actually *do* once it's triggered. Since we are creating a SMS action, then this would be the part where we actually send the SMS message somehow. For this example we will not actually send any SMS message. Intead, we will go through how we can code this action's logic.

Let's create a directory called `actions` in our ZenPack's top directory. Inside this new directory, create a blank `__init__.py` file and then create a Python file for the action's logic. For this example, I am creating a file called `sms.py`.

Let's first go over the imports:

```python
import logging
log = logging.getLogger('zen.useraction.actions')

from zope.interface import implements

from Products.ZenModel.interfaces import IAction, IProvidesEmailAddresses
from Products.ZenModel.actions import IActionBase, TargetableAction
from Products.ZenModel.actions import processTalSource, _signalToContextDict
from Products.ZenUtils.guid.guid import GUIDManager

from ZenPacks.andres.Sms.interfaces import ISmsActionContentInfo
```

Nothing new. Notice that we are again importing the interface we previously defined.

Now let's go over the custom action class that will inherit from `IActionBase` and `TargetableAction`:

```python
# ...

class SmsAction(IActionBase, TargetableAction):
    implements(IAction)

    id = 'sms'
    name = 'SMS'
    actionContentInfo = ISmsActionContentInfo

    # ...
```

The `name` field is the actual string that will be shown in the dropdown menu in the user interface. The `actionContentInfo` represents the content shown in the *content* tab. Here we are simply assigning the content we defined in `interface.py`.

Now let's see what methods we should add to this class:

```python
class SmsAction(IActionBase, TargetableAction):
    # ...

    def __init__(self):
        super(SmsAction, self).__init__()

    def setupAction(self, dmd):
        self.guidManager = GUIDManager(dmd)

    def execute(self, notification, signal):
        log.debug('Executing {0} action'.format(self.name))
        self.setupAction(notification.dmd)

        data = _signalToContextDict(
            signal,
            self.options.get('zopeurl'),
            notification,
            self.guidManager
        )

        # Process the message body first
        message_body = processTalSource(notification.content['message_body'], **data)

        # Call the actual SMS method here
        sendSms(message_body, notification.content['cellNumber'])

    def updateContent(self, content=None, data=None):
        updates = dict()

        properties = [
            'cellNumber',
            'message_body',
        ]

        for k in properties:
            updates[k] = data.get(k)

        content.update(updates)
```

So the method above that peaks our interest is `execute()`. It is here where we process the message body (because it contains TALES expressions), and send the SMS message with a magic method, passing the message body and the cellphone number. Notice how these fields are accessed using `notification.content['key']`.

=> Once everything is finished and the ZenPack is installed. Check the `zenactiond.log` log file for logs related to this action to make sure that the notification is being triggered.

Obviously the above `sendSms()` method doesn't really exist. But suppose we were using this method provided by a Python client that sends SMS messages using a special service (like [Twilio](https://www.twilio.com/)), then we could place this client under the `/lib` directory in the ZenPack's top directory. We can then add another import to `sms.py`:

```python
from ZenPacks.andres.Sms.lib.twiliosms import sendSms
```

You get the idea.

### Registering the Action

In other posts I've talked about how browser resources and templates are registered through the `configure.zcml` file. In this case we will also register the adapter and the action's logic file so that the front-end (ExtJS) knows how to interact with it.

**configure.zcml**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configure
    xmlns="http://namespaces.zope.org/zope"
    xmlns:zcml="http://namespaces.zope.org/zcml">

    <!-- Includes: Browser Configuration -->
    <utility
      factory=".actions.sms.SmsAction"
      provides="Products.ZenModel.interfaces.IAction"
      name="sms"
      />

    <adapter
      provides=".interfaces.ISmsActionContentInfo"
      for="Products.ZenModel.NotificationSubscription.NotificationSubscription"
      factory=".info.SmsActionContentInfo"
      />

</configure>
```

At this point you can proceed to install the ZenPack and restart Zenoss. Afterwards you can navigate to *Events > Triggers > Notifications*, create a new notification of SMS type and fill in or change the default contents:

![SMS Action](/posts/custom-notification-action-types-in-zenoss/sms_action.jpg)

## References

1. [Zenoss Slack ZenPack](https://github.com/ssplatt/slack-zenoss)
2. [ZenPacks.community.HipChat](https://github.com/jregovic/ZenPacks.community.HipChat)
2. [*Triggering Commands From Events in Zenoss*](/posts/triggering-commands-from-events-in-zenoss.html)
3. [*Custom Triggers and Notifications in a ZenPack*](/posts/custom-triggers-and-notifications-in-a-zenpack.html)