---
date: '2017-06-07'
tags:
- zenoss
- python
- monitoring
title: Zenoss Custom Notification Actions Using Subscribers
---

In a [previous post](/posts/custom-notification-action-types-in-zenoss.html) I talked about how we could create custom notifications actions in Zenoss. Like a *SMS* notification, for example. In that post we required a valid cellphone number using a text field in the notification's content pane, as shown below:

![Notification Content](/posts/custom-notification-action-types-in-zenoss/sms_action.jpg)

In this post I want to change and improve this by using _**subscribers**_ functionality instead. Similar to the e-mail (or pager) notification, which sends an e-mail to all the subscribed users using their e-mail address configured in their user settings. Since there is no SMS mobile number that we can configure in the user settings, we will have to use the *Pager* field instead.

## The Pager Action

Using Zenoss Core 4's pager action's [source code](https://github.com/BigChief45/zenoss-core-425/blob/master/usr/local/zenoss/Products/ZenModel/actions.py#L449) as reference is a good starting point, since we are going to use the pager field for SMS.

We can see that this action class implements a `executeOnTarget` method instead of a `execute` method we used in the previous post.

<!--more-->

This method is very similar to `execute`, but it receives an additional `target` parameter:

```python
class PageAction(IActionBase, TargetableAction):
    # ...

    def executeOnTarget(self, notification, signal, target):
        # ...
```

The `target` argument is what will represent the subscriber. More specifically, it will represent the subscriber's *pager* value, which will be a string.

Very simple. However, we must not overlook a method from theaction class called `getActionableTargets`. This method implements an interface that should be designed in the context of the targets. In this case, pager addresses. But it could also be in the context of e-mails or other scenarios:

```python
    def getActionableTargets(self, target):
        """
        @param target: This is an object that implements the IProvidesPagerAddresses
            interface.
        @type target: UserSettings or GroupSettings.
        """
        if IProvidesPagerAddresses.providedBy(target):
            return target.getPagerAddresses()
```

The importing of these interfaces can be seen at the top of the file:

**Products/ZenModel/actions.py**:

```python
from Products.ZenModel.interfaces import (
    IAction, IProvidesEmailAddresses, IProvidesPagerAddresses,
    IProcessSignal, INotificationContextProvider,
)
```

## SMS Action With Subscribers

Now to be able to use a similar *subscribers* approach like the e-mail action, we simply need to implement the concepts mentioned above. However, since we are going to use the pager field for the mobile number, we can use the `IProvidesPagerAddresses` interface in our code.

We will rename our `execute` method to `executeOnTarget`, and we will include the new `target` parameter it receives. Additionally, all previous references to the `cellphone_number` field should be changed to `target`.

Then we simply include the `getActionableTargets` method in our class, and make sure we are importing the interface.

With all this we should be good to go. If you create some users and assign a valid mobile number in their *pager* field, add the users to the notification as subscribers, then the notification should successfully pick up the mobile number.

## References

1. [Zenoss Core 4.2.5 Pager Action](https://github.com/BigChief45/zenoss-core-425/blob/master/usr/local/zenoss/Products/ZenModel/actions.py#L449)