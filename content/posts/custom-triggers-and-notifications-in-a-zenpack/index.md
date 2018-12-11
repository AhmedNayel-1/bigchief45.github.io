---
date: '2017-05-04'
tags:
- zenoss
- zenpack
- zenpacklib
- python
- zendmd
- sysadmin
- monitoring
title: Custom Triggers and Notifications in a ZenPack
---

In a [previous post](/posts/triggering-commands-from-events-in-zenoss.html) I talked about how to use **triggers** and **command notifications** in Zenoss to trigger custom actions when certain events occur. All of this was done using the Zenoss user interface.

In this post we will achieve something similar, but from a custom ZenPack. At the end of this post, our custom ZenPack will be able to create new custom triggers and notifications when installed.

## Defining ZenPack Triggers & Notifications

Triggers and notifications within a ZenPack are actually defined using JSON. To do so, you must create a file named `actions.json` in a directory called `zep` (create it if it doesn't exist), within the ZenPack's top directory.

**actions.json**:

```json?line_numbers=false
{
  "triggers": [
    {
      "name": "Critical_death_event",
      "uuid": "4c055067-98b7-483e-8f49-2820b4f2f721",
      "enabled": false,
      "rule": {
        "api_version": 1,
        "type": 1,
        "source": "(evt.event_class.startswith(\"/Status/Ping\")) and (evt.status == 0) and (evt.severity > 2)"
      }
    }
  ],

  "notifications": [
    {
      "id": "send_sms_message",
      "description": "Send SMS using Twilio",
      "action": "command",
      "guid": "2606439f-5ef7-40dc-90e4-3f3bee11cfe6",
      "enabled": false,
      "action_timeout": 60,
      "delay_seconds": 0,
      "repeat_seconds": 0,
      "send_initial_occurrence": false,
      "send_clear": false,
      "body_format": "echo \"Hello World!\"",
      "clear_body_format": "",
      "subscriptions": ["4c055067-98b7-483e-8f49-2820b4f2f721"]
    }
  ]
}
```

<!--more-->

Below is a table with fields for triggers:

|    Name       |    Description                                             |
|:--------------|:-----------------------------------------------------------|
| uuid          | Unique identifier                                          |
| name          | Trigger's name                                             |
| rule          | Dictionary with attributes `api_version`, `type`, `source` |
| enabled       | If the trigger is enabled or not (boolean).                |
| subscriptions | List of dictionaries, each containing a notification       |
| users         | List of dictionaries, each containing a user with permissions on this trigger |

We can find the basic notification fields in `$ZENHOME/Products/ZenModel/NotificationSubscription.py`. Notification-specific fields can be found at `$ZENHOME/Products/Zuul/interfaces/actions.py`.

The following is a table of Notification fields:

|     Name       |          Description                                     |
|:---------------|:---------------------------------------------------------|
| id             | Notification ID (String)                                 |
| name           | Notification's name                                      |
| enabled        | Boolean                                                  |
| action         | Can choose between *command*, *email*, *SNMP trap*, etc. |
| delay_seconds  |                                                          |
| repeat_seconds |                                                          |
| send\_initial\_occurrence | |
| send_clear     |                                                          |
| subscriptions  | List of dictionaries, each representing a trigger        |
| recipients     | List of dictionaries representing a user to receive the notification |
| globalRead     |                                                          |
| globalWrite    | |
| globalManage   | |
| content        | Details for an email or pager or the command and environment
details for a *command* notification |

Triggers and notifications require [Universally Unique IDs (UUID)](https://en.wikipedia.org/wiki/Universally_unique_identifier). We can generate them using Python and then use them in the JSON file:

```
python -c "import uuid; print uuid.uuid4()"
```

For each notification, the `subscriptions` field must be a **list** of the required trigger *uuid* fields. This means that the notification will fire when the triggers with those *uuids* are fired.

-> `$ZENHOME/Products/ZenUtils/guid/guid.py` also has code to generate globally unique UUIDs.

If the JSON has no errors, you should receive the following output when installing the ZenPack:

```
2017-05-05 11:05:39,206 INFO zen.ZPLoader: Creating trigger: Critical_death_event
2017-05-05 11:05:39,307 INFO zen.ZPLoader: Creating notification: send_sms_message
```

Let's compare the trigger JSON data with the result shown in the user interface:

![Custom Trigger](/posts/custom-triggers-and-notifications-in-a-zenpack/custom_trigger.jpg)

Let's also take a look at the result for the custom notification:

![Custom Notification](/posts/custom-triggers-and-notifications-in-a-zenpack/custom_notification.jpg)

![Custom Notification 2](/posts/custom-triggers-and-notifications-in-a-zenpack/custom_notification2.jpg)

Excellent! Everything looks good.

~>
When a ZenPack is removed, event fields are removed; however notifications and triggers are **NOT** removed.<br><br>Additionally, if a trigger or notification already exists when a ZenPack is installed, it will be overriden by the definition in the ZenPack.

A possible solution to the problem above would be to programatically remove the notifications and triggers in the ZenPack's `remove` method in the `__init__.py` file:

```python
def remove(self, app, leaveObjects=False):
    try:
        ZenPack.UNINSTALLING = True

        # Remove triggers & notifications here...

        super(ZenPack, self).remove(app, leaveObjects=leaveObjects)
    finally:
        ZenPack.UNINSTALLING = False
```

## References

1. *ZenPack Developer's Guide* by Jane Curry
2. [Providing Triggers Notifications and Event Details in ZenPack](http://wiki.zenoss.org/Providing_Triggers_Notifications_and_Event_Details_in_ZenPack)