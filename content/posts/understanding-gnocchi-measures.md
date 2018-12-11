---
date: '2017-05-24'
tags:
- gnocchi
- python
title: Understanding Gnocchi Measures
---

Measures are simple objects that represent the timeseries data. They simply contain a **timestamp** and a **value**, and they belong to [metrics](/posts/understanding-gnocchi-metrics.html). You could say that a measure *has many* metrics.

## Adding Measures to a Metric

Using the REST API, we can easily add measures to a metric:

```http
POST /v1/metric/511b61a1-8d67-42d5-8add-66d4209a0469/measures HTTP/1.1
Content-Type: application/json
Content-Length: 198

[
  {
    "timestamp": "2014-10-06T14:33:57",
    "value": 43.1
  },
  {
    "timestamp": "2014-10-06T14:34:12",
    "value": 12
  },
  {
    "timestamp": "2014-10-06T14:34:20",
    "value": 2
  }
]
```

<!--more-->

The following example shows how it can be done with the Gnocchi client. This example uses the [psutil](https://pypi.python.org/pypi/psutil/) library to obtain CPU percentage data every minute. This is percentage will be the value for the metric's `value` field.

```python
import uuid
from datetime import datetime

# Let's create a metric first
metric = gnocchi.metric.create({
        'name': 'my_metric',
        'archive_policy_name': 'high'
        })

# Now let's use psutil library
psutil.cpu_times()

# Every minute, we will get a CPU percentage, and we will calculate a timestamp
for x in range(60):
    timestamp = str(datetime.now()).split('.')[0]
    cpu = psutil.cpu_percent(interval=60)

    gnocchi.metric.add_measures(metric['id'], [{
            'timestamp': timestamp,
            'value': cpu,
            }])
```

The code above will create a new measure for the metric, every minute.

If you keep querying the API after the measures are created, you will notice that they do not appear in the response. This delay will depend on the driver, there may be some lag after POSTing measures before they are processed and queryable. To ensure your query returns all measures that have been POSTed, you can force any unprocessed measures to be handled:

```http
GET /v1/metric/:id/measures?refresh=true HTTP/1.1
```

We should then be able to see the measures that have been posted so far:

```json
[
  [
    "2017-05-24T08:00:00+00:00",
    3600,
    47.86666666666667
  ],
  [
    "2017-05-24T09:00:00+00:00",
    3600,
    46.5
  ],
  [
    "2017-05-24T08:57:00+00:00",
    60,
    43.4
  ],
```

## Metric Storage

Storage of metrics is defined by the selected storage driver. If *file* is used as storage, we can find the stored metrics in the directory configured in the `[storage]` section of `gnocchi.conf`:

```ini
[storage]
driver = file
file_basepath = /home/ubuntu/gn
```

Inside this directory you will find more directories with the IDs of the created metrics as their names:

```
gn/
├── 26f0c89a-0a90-405c-a51a-a12220bd3d82
│   ├── agg_count
│   │   ├── 1490400000.0_3600.0_v3
│   │   ├── 1495584000.0_60.0_v3
│   │   ├── 1495612800.0_1.0_v3
│   │   └── 1495616400.0_1.0_v3
│   ├── agg_max
│   │   ├── 1490400000.0_3600.0_v3
│   │   ├── 1495584000.0_60.0_v3
│   │   ├── 1495612800.0_1.0_v3
│   │   └── 1495616400.0_1.0_v3
│   ├── agg_mean
│   │   ├── 1490400000.0_3600.0_v3
│   │   ├── 1495584000.0_60.0_v3
│   │   ├── 1495612800.0_1.0_v3
│   │   └── 1495616400.0_1.0_v3
│   ├── agg_min
│   │   ├── 1490400000.0_3600.0_v3
│   │   ├── 1495584000.0_60.0_v3
│   │   ├── 1495612800.0_1.0_v3
│   │   └── 1495616400.0_1.0_v3
│   ├── agg_std
│   │   └── 1490400000.0_3600.0_v3
│   ├── agg_sum
│   │   ├── 1490400000.0_3600.0_v3
│   │   ├── 1495584000.0_60.0_v3
│   │   ├── 1495612800.0_1.0_v3
│   │   └── 1495616400.0_1.0_v3
```

Inside these metric directories we will find more directories representing the available aggreation methods (count, max, mean, min, sum, etc.) by the metric's **archive policies**, as shown above.

## Source Code

The source code where measures are stored will depend on the driver. Again, using the *file* driver as an example, we can find the source code in [`/gnocchi/storage/file.py`](https://github.com/gnocchixyz/gnocchi/blob/master/gnocchi/storage/file.py#L121):

**/gnocchi/storage/file.py**:

```python
class FileStorage(_carbonara.CarbonaraBasedStorage):
    WRITE_FULL = True

    def __init__(self, conf, incoming):
        super(FileStorage, self).__init__(conf, incoming)
        self.basepath = conf.file_basepath
        self.basepath_tmp = os.path.join(self.basepath, 'tmp')
        utils.ensure_paths([self.basepath_tmp])

    # ...

    def _atomic_file_store(self, dest, data):
        tmpfile = tempfile.NamedTemporaryFile(
            prefix='gnocchi', dir=self.basepath_tmp,
            delete=False)
        tmpfile.write(data)
        tmpfile.close()
        os.rename(tmpfile.name, dest)

    # ...

    def _store_metric_measures(self, metric, timestamp_key, aggregation,
                               granularity, data, offset=None, version=3):
        self._atomic_file_store(
            self._build_metric_path_for_split(metric, aggregation,
                                              timestamp_key, granularity,
                                              version),
        data)
```