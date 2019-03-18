---
title: "Custom Log Files With Django and Elastic Beanstalk"
date: 2019-02-22T17:49:21Z
tags: [django, elasticbeanstalk]
keywords: [django, elasticbeanstalk, logs, monitoring]
---

With Amazon ElasticBeanstalk it is possible to view log files of your deployed application. However, ElasticBeanstalk by default only returns certain logs like `/var/log/httpd/error_log` or `/var/log/httpd/access_log` if you are using Apache httpd.

If you are generating custom logs in your Django application and using file handlers to save them to log files, you will probably want to be able to access and read them easily from the ElasticBeanstalk console.


In this post I will show you how to achieve this, using Django as our backend framework.

<!--more-->

## Configuring Logging in Django

We will use a very simple logging configuration. Basically we will be using a file handler that streams our logs to files in the instance's file system.

Moreover, let's assume that our Django application is acting as a **worker**, not a web server. This means that its responsibility lies in executing background jobs that take time to process.

The configuration in Django looks like this:

```python
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        " verbose": {
            "format": "%(asctime)s %(levelname)s %(module)s: %(message)s"
        }
    },
    "handlers": {
        "analyzer": {
            "level": "DEBUG",
            "class": "logging.FileHandler",
            "filename": "/opt/python/log/analyzer.log",
            "formatter": "verbose",
        },
    },
    "loggers": {
        "analyzer": {
            "handlers": ["analyzer"], "level": "DEBUG", "propagate": True
        },
    },
}
```

I have created a log called `analyzer` that saves log messages to a log file located the path `/opt/python/log/analyzer.log`. This path is automatically created by ElasticBeanstalk when you are using a Python platform. If you are using another platform, this path will be different.

If you separate different tasks for this worker application under different Django apps, you will probably want to create a log file for each, under the same path. To do this, simply add more loggers and handlers to the Django configuration.

Once the Django application starts running, the log handlers will proceed to create these files.

## Logging Some Messages

Logging messages to this log file is very easy, we simply use the Python logging module to create a logger with the same name as in the configuration:

```python
import logging


logger = logging.getLogger("analyzer")


def some_view(request):
    logger.info("Hello World")
```


## Configuring Permissions in ElasticBeanstalk

Some permissions must be configured in this path so that Django can successfully write logs to these new custom files. In your `.ebextensions` directory, create a new file called `logging.config`:

```yaml
commands:
  01_change_permissions:
    command: chmod g+s /opt/python/log
  02_change_owner:
    command: chown root:wsgi /opt/python/log
```

And with this we are all set.

## Viewing The Logs

Finally we can take a quick look at our logs from the ElasticBeanstalk console by navigating to your deployed environment and then _Logs > Request Logs > Last 100 Lines_.

Aside from the logs that ElasticBeanstalk already outputs, you should be able to see a section of our new
log file:

```
-------------------------------------
/opt/python/log/analyzer.log
-------------------------------------
```
