---
date: '2016-10-31'
tags:
- zenoss
- monitoring
- devops
title: Triggering Commands From Events in Zenoss
---

In Zenoss Core 4, we can configure some **_email_** notifications that produce and send emails based on conditions defined in a trigger, when an event is created.

Additionally, Zenoss Core 4 also provides **_command_** type notifications that allow us to execute commands in the Zenoss machine when the trigger criterias are met.

For example, let's say we want to execute a script everytime we ping a device and get no response. This scenario would involve the following:

1. The device is suddenly down.
2. Zenoss pings the device and gets no response.
3. The device status is then changed to *DOWN*.
4. An Event with an event class of `/Status/Ping` and a severity of *Critical* is created.

With this information, we can create a trigger that will represent this exact scenario. Moreover, we can configure a command notification to be executed when this trigger is fired.

## Configuring a Trigger

1. Navigate to Events > Triggers
2. Create a new trigger.
3. Add the rules that represent the scenario mentioned before. In this case, all of these rules must apply:

![Edit Trigger](/posts/triggering-commands-from-events-in-zenoss/edit_trigger.png)

=> Because we want to make sure the device is truly *DOWN*, and has been so for quite a while, we also want to add a condition that checks that the event count is greater than a certain number, only then the trigger will be fired, and consequently, the command.

<!--more-->

## Configuring the Command Notification

1. Create a new notification of type command.
2. Make sure that the enabled option is marked.
3. Add the previously created trigger to this notification.
4. In the Content pane, in the Command text field, type in the command as it would be run in a terminal. (Example: `./home/zenoss/revive_device.sh`)

![Edit Notification](/posts/triggering-commands-from-events-in-zenoss/edit_notification.png)

**NOTE:** For testing purposes (covered next), we are going to use a <kbd>touch</kbd> command, which simply creates a blank file in the specified path:

```bash
touch /home/zenoss/revive_device.sh
```

## Testing it Out

To test, we are going to add a new device that we know it's already down. Once we add the device, Zenoss will immediately ping it and get no response, the scenario discussed before will then be reproduced, and the event will be created:

![Event Created](/posts/triggering-commands-from-events-in-zenoss/event_fired.png)

We can see that the count value is still below our defined rule (9). If we check the specified path of our touch command, we should see that no file has been created.

![Event Count](/posts/triggering-commands-from-events-in-zenoss/event_count.png)

The default Zenoss ping cycle time is 60 seconds, so every time Zenoss pings the device and gets no response, the count value for this event will increase. Once it reaches the value specified in our trigger rule, the command notification should be fired and the file should be created in the path specified for the <kbd>touch</kbd> command:

![Trigger Result](/posts/triggering-commands-from-events-in-zenoss/trigger_result.jpg)