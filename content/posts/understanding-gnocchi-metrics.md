---
date: '2017-05-18'
tags:
- gnocchi
- openstack
- python
title: Understanding Gnocchi Metrics
---

Metrics are one of the main object types in Gnocchi. They are identified by a UUID and they can also be attached to a resource by using a resource name. Metrics store **measures**, and the way they do this is defined by **archive policies**. These are concepts that I will cover in future articles.

Basically, a metric designates any thing that can be measured: the CPU usage of a server, the temperature of a room or the number of bytes sent by a network interface.

![Gnocchi Architecture](http://gnocchi.xyz/_images/architecture.png)

In the Gnocchi architecture, the **storage** back-end is responsible for storing measures of created metrics. It receives timestamps and values, and pre-computes aggregations according to the defined archive policies.

<!--more-->

## Interacting With Metrics Using the API

Using the Gnocchi REST API, a metric can be created by simply passing an archive policy:

```http
POST /v1/metric HTTP/1.1
Content-Length: 35
Content-Type: application/json

{
  "archive_policy_name": "high"
}
```

The API will respond with a created `201 CREATED` status code and some information about the created metric:

```http
HTTP/1.1 201 Created
Location: http://localhost/v1/metric/4c964d57-9d67-4c49-bc61-d48d15b705c6
Content-Length: 206
Content-Type: application/json

{
  "archive_policy_name": "high",
  "created_by_project_id": "",
  "created_by_user_id": "admin",
  "creator": "admin",
  "id": "4c964d57-9d67-4c49-bc61-d48d15b705c6",
  "name": null,
  "resource_id": null,
  "unit": null
}
```

We can then retrieve the complete information of this metric by using its UUID:

```http
GET /v1/metric/4c964d57-9d67-4c49-bc61-d48d15b705c6 HTTP/1.1
Content-Length: 0
```

The response will be:

```http
HTTP/1.1 200 OK
Content-Length: 532
Content-Type: application/json

{
  "archive_policy": {
    "aggregation_methods": [
      "min",
      "count",
      "max",
      "std",
      "sum",
      "mean"
    ],
    "back_window": 0,
    "definition": [
      {
        "granularity": "0:00:01",
        "points": 3600,
        "timespan": "1:00:00"
      },
      {
        "granularity": "0:01:00",
        "points": 10080,
        "timespan": "7 days, 0:00:00"
      },
      {
        "granularity": "1:00:00",
        "points": 8760,
        "timespan": "365 days, 0:00:00"
      }
    ],
    "name": "high"
  },
  "created_by_project_id": "",
  "created_by_user_id": "admin",
  "creator": "admin",
  "id": "4c964d57-9d67-4c49-bc61-d48d15b705c6",
  "name": null,
  "resource": null,
  "unit": null
}
```

## Metric Source Code

Source code for the Metric object can be found in [`storage/__init__.py`](https://github.com/openstack/gnocchi/blob/master/gnocchi/storage/__init__.py):

**storage/__init__.py**:

```python
class Metric(object):
    def __init__(self, id, archive_policy,
                 creator=None,
                 name=None,
                 resource_id=None):
        self.id = id
        self.archive_policy = archive_policy
        self.creator = creator
        self.name = name
        self.resource_id = resource_id

    def __repr__(self):
        return '<%s %s>' % (self.__class__.__name__, self.id)

    def __str__(self):
        return str(self.id)

    def __eq__(self, other):
        return (isinstance(other, Metric)
                and self.id == other.id
                and self.archive_policy == other.archive_policy
                and self.creator == other.creator
                and self.name == other.name
                and self.resource_id == other.resource_id)

__hash__ = object.__hash__
```

Some exceptions related to metrics are also defined here. For example:

```python
class MetricAlreadyExists(StorageError):
    """Error raised when this metric already exists."""

    def __init__(self, metric):
        self.metric = metric
        super(MetricAlreadyExists, self).__init__(
            "Metric %s already exists" % metric)

class LockedMetric(StorageError):
    """Error raised when this metric is already being handled by another."""

    def __init__(self, metric):
        self.metric = metric
        super(LockedMetric, self).__init__("Metric %s is locked" % metric)
```

We can see these exceptions being raised by the drivers, which are also located in `/storage/`. For example, when the [file driver](https://github.com/openstack/gnocchi/blob/master/gnocchi/storage/file.py) is trying to create a metric:

```python
    def _create_metric(self, metric):
        path = self._build_metric_dir(metric)
        try:
            os.mkdir(path, 0o750)
        except OSError as e:
            if e.errno == errno.EEXIST:
                raise storage.MetricAlreadyExists(metric)
            raise
        for agg in metric.archive_policy.aggregation_methods:
            try:
                os.mkdir(self._build_metric_path(metric, agg), 0o750)
            except OSError as e:
                if e.errno != errno.EEXIST:
                    raise
```

Since the file driver storages the metric data in the file system using actual *files*, when a file already exists, a system error will be produced and the `OSError` exception will be catched.

This storage module makes use of the Python [`errno` module](https://docs.python.org/2/library/errno.html), which provides standard system `errno` symbols. In this case, the exception's `errno` would be `EEXIST`, indicating the [file already exists](https://docs.python.org/2/library/errno.html#errno.EEXIST). The `MetricAlreadyExists` exception is then raised.

## Interacting With Metrics Using the Gnocchi Client

With the [gnocchi client](http://gnocchi.xyz/gnocchiclient/index.html), we can create metrics like this:

```python
gnocchi.metric.create({
        'name': 'my_metric',
        'archive_policy_name': 'high',
})
```

And we can delete it by passing the metric's UUID (if there is no resource ID) like this:

```python
gnocchi.metric.delete(metric='1c0f69bf-67bb-4080-8e7c-53723f7e6194')
```