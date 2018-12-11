---
date: '2017-04-11'
tags:
- ceilometer
- openstack
- gnocchi
- panko
- python
title: Understanding Ceilometer Publishers
---

Continuing with my study of the Ceilometer pipeline, this post now covers Ceilometer **publishers**. Publishers are components that make it possible to save the data into a persistent storage through the message bus, or to send it to one or more external consumers.

Publishers are specified in the `publishers` section for each pipeline that is defined in the `pipeline.yaml` and the `event_pipeline.yaml` files.

Many different publishers are available. The following are the most common and important publishers:

### Gnocchi

![Gnocchi Logo](http://gnocchi.xyz/_images/gnocchi-logo.jpg)

Gnocchi is a multi-tenant timeseries, metrics and resources database. It provides an HTTP REST interface to create and manipulate the data. It is designed to store metrics at a very large scale while providing access to metrics and resources information and history.

<!--more-->

Gnocchi was created to fulfill the need of a time series database usable in the context of cloud computing: providing the ability to store large quantities of metrics. It has been designed to handle large amount of measures being stored, while being performant, scalable and fault-tolerant. While doing this, the goal was to be sure to not build any hard dependency on any complex storage system.

The project was started in 2014 as a spin-off of the OpenStack Ceilometer project to address the performance issues that Ceilometer encountered while using standard databases as a storage backends for metrics.

=> The recommended workflow is to push data to Gnocchi for efficient time-series storage and resource lifecycle tracking.

~> Gnocchi must be registered in the Identity service as Ceilometer discovers the exact path via the Identity service.

### Panko

The Panko publisher is for storing **event** data. It provides a REST HTTP interface to query system events in OpenStack. A Panko publisher can be set with `panko://`.

### Notifier

This publisher emits data over AMQP using `oslo.messaging` library.

### HTTP

Samples can be sent using HTTP to an external target. For example:

```yaml
http://localhost:80/?option1=value1&option2=value2
```

![Ceilometer Publishers](https://docs.openstack.org/developer/ceilometer/_images/5-multi-publish.png)

## Difference Between Publishers and Dispatchers

The documentation does a decent job at explaining publishers. However, it does not say much about dispatchers. When looking at the source code, it also seems that dispatchers send metering data for storage in an external location such as Gnocchi (see [Gnocchi dispatcher](https://github.com/openstack/ceilometer/blob/master/ceilometer/dispatcher/gnocchi.py)) or a database.

Being confused about this, I decided to [ask](http://openstack.10931.n7.nabble.com/telemetry-ceilometer-Difference-between-publishers-and-dispatchers-td133396.html) in the [OpenStack dev mailing list](http://lists.openstack.org/cgi-bin/mailman/listinfo/openstack-dev). I managed to obtain a very quick response from Julien Danjou:

> Publishers are configured into the pipeline to indicate where to push
> samples data (e.g. to Gnocchi).
> One of the publisher is `notifier://` which sends the samples to the (now
> deprecated) ceilometer-collector process.
>
> Ceilometer collector stores data into other system via a dispatcher
> mechanism (e.g. to Gnocchi). It's now deprecated as it's just, with
> current architecture, a unnecessary step: publishers can do the job
> directly.

And another one from Hanxi Liu:

> Ceilometer has deprecated collector from Pike, so dispatchers will be no longer used in the future. Data should be pushed from publisher to storage backend(e.g. Gnocchi) and/or other outer system. Some dispatchers were deprecated because there are corresponding developed publisher, for example, file dispatcher to file publisher. Of course, If you still want to use previous version, you could use dispatcher behind collector.

## The Source Code

In Ceilometer's source code, publisher logic can be found in [`ceilometer/publisher`](https://github.com/openstack/ceilometer/blob/master/ceilometer/publisher). A publisher base class can be found in the ``__init__.py` file:

```python
@six.add_metaclass(abc.ABCMeta)
class ConfigPublisherBase(object):
    """Base class for plugins that publish data."""

    def __init__(self, conf, parsed_url):
        self.conf = conf

    @abc.abstractmethod
    def publish_samples(self, samples):
        """Publish samples into final conduit."""

    @abc.abstractmethod
    def publish_events(self, events):
        """Publish events into final conduit."""
```

We can see the abstract methods to be implemented by each publisher. The `publish_samples` method is of particular interest.

If we take a look at the HTTP publisher source code, we can see how it implements these methods:

```python
class HttpPublisher(publisher.ConfigPublisherBase):
    # ...

    def publish_samples(self, samples):
        """Send a metering message for publishing
        :param samples: Samples from pipeline after transformation
        """
        self.poster([sample.as_dict() for sample in samples])

    def publish_events(self, events):
        """Send an event message for publishing
        :param events: events from pipeline after transformation
        """
        if self.raw_only:
            data = [evt.as_dict()['raw']['payload'] for evt in events
                    if evt.as_dict().get('raw', {}).get('payload')]
        else:
            data = [event.serialize() for event in events]
        self.poster(data)
```