---
date: '2017-04-06'
tags:
- ceilometer
- openstack
- cloudcomputing
title: Ceilometer and OpenStack Notifications
---

Ceilometer has different mechanisms to collect data from OpenStack. One of these mechanisms, are **notifications**, which will be explained in this post.

## OpenStack Notifications

All OpenStack services (such as Nova Compute, Neutron, etc.) send notifications about executed operations or the state of the system. Many of these notifications carry information that can be metered such as **CPU time** of a virtual machine instance created by the compute service.

OpenStack services send these notifications through an AMQP message queue. However, not all these notifications are consumed by the Telemetry service, as the intention is only to capture the billable events and notifications that can be used for monitoring or profiling purposes. The notification agent filters by the **event type**. Each notification message contains the event type.

Here is a table with a few examples:

| OpenStack Service       | Event types |
|:-----------------------:|:-----------:|
| OpenStack Compute       | `scheduler.run_instance.scheduled`, `scheduler.select_destinations`, `compute.instance.*` |
| OpenStack Image         | `image.update`, `image.upload`,  `image.delete`, `image.send` |

In Ceilometer, the **notification agent** is reponsible for consuming these notifications from the AMQP message bus, and then transforming them into **events** and **samples**.

![Notifications Collection](https://docs.openstack.org/developer/ceilometer/_images/2-1-collection-notification.png)

<!--more-->

## Meter Definitions

Meters are created by **filtering** notifications emitted by the OpenStack services. Meter definitions can be found in a configuration file called `ceilometer/meter/data/meters.yaml`.

The following is an example meter taken from that file:

```yaml
  # Image
  - name: "image.size"
    event_type:
      - "image.upload"
      - "image.delete"
      - "image.update"
    type: "gauge"
    unit: B
    volume: $.payload.size
    resource_id: $.payload.id
    project_id: $.payload.owner
```

The `name`, `event_type`, `type`, `unit`, and `volume` fields are required. If there is a match on the event type, samples are generated for the meter.

The value of each field is specified by using JSON path in order to find the right value from the notification message. In order to be able to specify the right field you need to be aware of the format of the consumed notification. The values that need to be searched in the notification message are set with a JSON path starting with `$`. For instance, if you need the size information from the payload you can define it like `$.payload.size`.

## The Source Code ([`notification.py`](https://github.com/openstack/ceilometer/blob/master/ceilometer/notification.py))

The heart of the system is the notification daemon (agent-notification) which monitors the message queue for data sent by other OpenStack components such as Nova, Glance, Cinder, Neutron, Swift, Keystone, and Heat, as well as Ceilometer internal communication.

The notification daemon loads one or more listener plugins, using the namespace `ceilometer.notification`. Each plugin can listen to any topic, but by default, will listen to `notifications.info`, `notifications.sample`, and `notifications.error`. The listeners grab messages off the configured topics and redistributes them to the appropriate plugins(endpoints) to be processed into Events and Samples.

```python
class NotificationService(cotyledon.Service):
    """Notification service.
    When running multiple agents, additional queuing sequence is required for
    inter process communication. Each agent has two listeners: one to listen
    to the main OpenStack queue and another listener(and notifier) for IPC to
    divide pipeline sink endpoints. Coordination should be enabled to have
    proper active/active HA.
    """

    NOTIFICATION_NAMESPACE = 'ceilometer.notification'
```

The `NotificationService` class extends a `Service` class from the `cotyledon` package. We can see this package being imported in the import section at the beginning of the module:

```python
import cotyledon
```

The [cotyledon package](https://pypi.python.org/pypi/cotyledon/1.6.7) provides a framework for defining long-running services. It provides handling of Unix signals, spawning of workers, supervision of children processes, daemon reloading, sd-notify, rate limiting for worker spawning, and more.

=> Imports are separated in 3 sections. The first section is for Python standard library imports, the second is for other OpenStack related imports (such as oslo modules), and the third section is for Ceilometer (or in the case of another project, that same project) module imports.

A notification service object also has `run` and `terminate` methods which start and terminates the service, respectively.

## References

1. [Ceilometer Administration Guide](https://docs.openstack.org/admin-guide/telemetry.html)
2. [Ceilometer Developer's Documentation](https://docs.openstack.org/developer/ceilometer/)