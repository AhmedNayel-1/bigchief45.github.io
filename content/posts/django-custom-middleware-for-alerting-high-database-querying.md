---
title: "Django: Custom Middleware for Alerting High Database Querying"
date: 2020-05-06T15:27:47-06:00
tags: [django]
---

In this post I will show you how you can implement a custom [middleware](https://docs.djangoproject.com/en/3.0/topics/http/middleware/) that you can use in your development environment to monitor queries to the database in your views when developing Django applications.

Let's begin by creating a `middleware.py` file (a nice convention) where we will place our new middleware. The middleware is relatively simple and small, this is how it looks like:

<!--more-->


{{< gist BigChief45 ae3984fc084117876bdaa3beb16a5341 >}}

You can customize the threshold value as you see fit.

Finally add the new middleware to the `MIDDLEWARE` configuration in your settings:

```python
MIDDLEWARE = [
    # Other middleware...
    'myapp.middleware.DatabaseQueryAlertingMiddleware',
]
```
