---
date: '2017-04-25'
tags:
- gnocchi
- ceilometer
- openstack
- python
- ceph
- pecan
title: Diving Into OpenStack Gnocchi
---

Gnocchi is a multi-tenant timeseries, metrics and resources database. It provides an HTTP REST interface to create and manipulate the data. It is designed to store metrics at a very large scale while providing access to metrics and resources information and history.

It is the preferred storage method for metrics in Ceilometer, as of OpenStack Ocata.

In this post I want to dive into Gnocchi specifics such as its configuration, supported backends, APIs, daemons, and source code.

## Configuration

Gnocchi's configuration is stored in a file called `gnocchi.conf`. Ideally, this file would be in `~/gnocchi.conf` or `/etc/gnocchi/gnocchi.conf`. Let's take a look at a basic Gnocchi configuration:

```ini
[DEFAULT]
debug = true
verbose = true

[api]
workers = 1

[database]
backend = sqlalchemy

[indexer]
url = postgresql://gnocchi:gnocchi@127.0.0.1/gnocchi

[storage]
coordination_url = file:///home/ubuntu/gn/locks
driver = file
file_basepath = /home/ubuntu/gn

[cors]
allowed_origin = *
allow_credentials = false
```

The configuration above sets up Gnocchi to use Postgresql as the indexer, and use the file system for storage. Additionally it sets up CORS so that requests from any origin are allowed. You will want to configure CORS in a more secure manner when deploying to a production environment.

### Database Setup

For this example, we are going to use [Cloud 9](www.c9.io) as our environment, and Postgresql as the database. This means that we need to first setup the database before we start using Gnocchi.

Make sure the Postgresql service is running:

```
sudo service postgresql start
```

We can enter the Postgresql command line using:

```
sudo sudo -u postgres psql
```

Now let's create a new Postgresql user:

```
CREATE USER gnocchi SUPERUSER PASSWORD 'gnocchi';
```

Then create the database:

```
CREATE DATABASE gnocchi WITH TEMPLATE = template0 ENCODING = 'UNICODE';
```

When the database is finally set up correctly and the configuration file is in place, we can initialize the indexer and storage:

```
gnocchi-upgrade
```

You should see the following output logs:

```
2017-05-17 05:28:50.917 3895 INFO gnocchi.cli [-] Upgrading indexer <gnocchi.indexer.sqlalchemy.SQLAlchemyIndexer object at 0x7ff76cff6190>
2017-05-17 05:28:50.982 3895 INFO alembic.runtime.migration [-] Context impl PostgresqlImpl.
2017-05-17 05:28:50.982 3895 INFO alembic.runtime.migration [-] Will assume transactional DDL.
2017-05-17 05:28:51.011 3895 INFO alembic.runtime.migration [-] Context impl PostgresqlImpl.
2017-05-17 05:28:51.011 3895 INFO alembic.runtime.migration [-] Will assume transactional DDL.
2017-05-17 05:28:51.154 3895 INFO gnocchi.cli [-] Upgrading storage <gnocchi.storage.file.FileStorage object at 0x7ff7688f9710>
```

## Gnocchi REST API

Gnocchi's REST API is based on [Pecan](http://www.pecanpy.org/index.html), a very lightweight Python web framework that provides object-dispatch style routing. We can confirm this in Gnocchi's `rest/__init__.py` file:

```python
import pecan
from pecan import rest
```

### Metrics

Gnocchi provides an object type that is called metric. A metric designates any thing that can be measured: the CPU usage of a server, the temperature of a room or the number of bytes sent by a network interface.

A metric only has a few properties: a UUID to identify it, a name, the archive policy that will be used to store and aggregate the measures.

Farther down the code in `rest/__init__.py`, we can find a metric controller which inherits from a Pecan REST controller:

```python
class MetricController(rest.RestController):
    _custom_actions = {
        'measures': ['POST', 'GET']
    }

    def __init__(self, metric):
        self.metric = metric
        mgr = extension.ExtensionManager(namespace='gnocchi.aggregates',
                                         invoke_on_load=True)
        self.custom_agg = dict((x.name, x.obj) for x in mgr)

    def enforce_metric(self, rule):
        enforce(rule, json.to_primitive(self.metric))

    @pecan.expose('json')
    def get_all(self):
        self.enforce_metric("get metric")
        return self.metric
```

From the [Pecan documentation](http://pecan.readthedocs.io/en/latest/routing.html), we can learn that Pecan uses a routing strategy known as object-dispatch to map an HTTP request to a controller, and then the method to call. Object-dispatch begins by splitting the path into a list of components and then walking an object path, starting at the root controller.

We can tell Pecan which methods in a class are publically-visible via `expose()`. If a method is not decorated with `expose()`, Pecan will never route a request to it. In the example above, the `get_all()` method is exposed to Pecan. Additionally, it makes use of Pecan's built-in support for a special JSON renderer, which translates template namespaces into rendered JSON text. Meaning that the returned content will be rendered as JSON.

<!--more-->

However, we specifically want to how Pecan's [Rest Controllers work](http://pecan.readthedocs.io/en/latest/rest.html#writing-restful-web-services-with-restcontroller). By default, Rest controllers routes as follows:

|  Method     |         Description                          |       Example Method(s) / URL(s)                 |
|:-----------:|:--------------------------------------------:|:------------------------------------------------:|
| get_one     | Display one record                           | `GET /books/1`                                   |
| get_all     | Display all records in a resource            | `GET /books/`                                    |
| get         | A combo of get\_one and get\_all             | `GET /books/` `GET /books/1`                     |
| new         | Display a page to create a new resource      | `GET /books/new`                                 |
| edit        | Display a page to edit an existing resource  | `GET /books/1/edit`                              |
| post        | Create a new record                          | `POST /books/`                                   |
| put         | Update an existing record                    | `POST /books/1?_method=put` `PUT /books/1`       |
| get_delete 	| Display a delete confirmation page           | `GET /books/1/delete`                            |
| delete 	    | Delete an existing record                    | `POST /books/1?_method=delete` `DELETE /books/1` |


### Authentication

By default, the authentication is configured to basic mode. You need to provide an authorization header in your HTTP requests with a valid username (the password is not used). The `admin` password is granted all privileges, whereas any other username is recognize as having standard permissions.

Other modes of authentication are: no authentication, and Keystone authentication.

Gnocchi handles authentication using a helper for each type of authentication. These helpers can be found in `rest/auth_helper.py`:

```python
class BasicAuthHelper(object):
    @staticmethod
    def get_current_user(headers):
        auth = werkzeug.http.parse_authorization_header(
            headers.get("Authorization"))
        if auth is None:
            rest.abort(401)
        return auth.username

    def get_auth_info(self, headers):
        user = self.get_current_user(headers)
        roles = []
        if user == "admin":
            roles.append("admin")
        return {
            "user": user,
            "roles": roles
        }

    @staticmethod
    def get_resource_policy_filter(headers, rule, resource_type):
        return None
```

It is important to mention that basic authentication is made possible because of [Werkzeug](http://werkzeug.pocoo.org/), Werkzeug is a [WSGI](https://en.wikipedia.org/wiki/Web_Server_Gateway_Interface) utility library for Python. In the basic auth helper, Werkzeug helps parsing the HTTP headers.

## Storage

Gnocchi offers different storage drivers such as Redis, File, OpenStack Swift, and Amazon S3. However the preffered driver is [Ceph](http://ceph.com/). In simple words, Ceph is a tool that provides applications with **object**, **block**, and **file system** storage in a single unified storage cluster.

Additionally, an intermediary library inside Gnocchi called Carbonara is in charge of the time series manipulation.

Storage logic can be found in [`gnocchi/storage`](https://github.com/openstack/gnocchi/blob/master/gnocchi/storage/). Some basic classes defining drivers, measures, and metrics can be found in the `__init__.py` file:

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
```

We can find the storage logic for Ceph in `ceph.py`:

```python
class CephStorage(_carbonara.CarbonaraBasedStorage):
    WRITE_FULL = False

    def __init__(self, conf, incoming):
        super(CephStorage, self).__init__(conf, incoming)
        self.rados, self.ioctx = ceph.create_rados_connection(conf)

    def stop(self):
        ceph.close_rados_connection(self.rados, self.ioctx)
        super(CephStorage, self).stop()

    @staticmethod
    def _get_object_name(metric, timestamp_key, aggregation, granularity,
                         version=3):
        name = str("gnocchi_%s_%s_%s_%s" % (
            metric.id, timestamp_key, aggregation, granularity))
        return name + '_v%s' % version if version else name

    def _object_exists(self, name):
        try:
            self.ioctx.stat(name)
            return True
        except rados.ObjectNotFound:
            return False

    def _create_metric(self, metric):
        name = self._build_unaggregated_timeserie_path(metric, 3)
        if self._object_exists(name):
            raise storage.MetricAlreadyExists(metric)
        else:
            self.ioctx.write_full(name, b"")
```

## Gnocchi Tests

Running the tests in Gnocchi took me a while. Mainly because I am not very familiar with testing in Python and how testing with OpenStack libraries work.

Tests are run using **tox** and [**testr**](https://wiki.openstack.org/wiki/Testr). Therefore we first install tox using pip inside the virtual environment. In Gnocchi (and each OpenStack project) there will be a `tox.ini` file in the root directory. This is a set of test configurations for the project. For example, we can see a list of available environments to test against:

```ini
[tox]
minversion = 2.4
envlist = py{35,27}-{postgresql,mysql}{,-file,-swift,-ceph,-s3},pep8,bashate
```

The complete list can be shown by using the `tox -l` command.

The default settings that applies to all environments are located underneath the `[testenv]` directive:

```ini
[testenv]
usedevelop = True
sitepackages = False
passenv = LANG OS_DEBUG OS_TEST_TIMEOUT OS_STDOUT_CAPTURE OS_STDERR_CAPTURE OS_LOG_CAPTURE GNOCCHI_TEST_* AWS_*
setenv =
    GNOCCHI_TEST_STORAGE_DRIVER=file
    GNOCCHI_TEST_INDEXER_DRIVER=postgresql

# ...
```

Specific environment configurations are specified by adding a a directive with the environment name after the colon:

```ini
[testenv:py35-postgresql-file-upgrade-from-3.1]
```

So to summarize all this, it all basically means that we can run tests with tox using one of these environments, like this:

```
tox -e py27-postgresql-file
```

This will create a directory for this environment under a hidden `.tox/` directory in the project and will begin installing dependencies. Since tox itself creates a virtual environment using `virtualenv`, **you must make sure that you have an up to date version of virtualenv installed**.

-> Why does tox take so long to run? The reason tox takes a long time is two-fold: On the first run it has to create a virtual environment, which can take anywhere from 5 to 30+ minutes depending on the project and the system. The other reason is that it just takes a long time to run all of the test cases in some of the projects.

## References

1. [Gnocchi official documentation](http://gnocchi.xyz/index.html)
2. [*Miscellaneous Resources on Gnocchi*](http://amalagon.github.io/blog/2014/09/14/miscellaneous-on-gnocchi/)
3. [Deploying Pecan in Production](http://pecan.readthedocs.io/en/latest/deployment.html)
4. https://wiki.openstack.org/wiki/Testr
5. https://wiki.openstack.org/wiki/Testing
6. http://waprin.io/2015/05/21/introducing-tox.html