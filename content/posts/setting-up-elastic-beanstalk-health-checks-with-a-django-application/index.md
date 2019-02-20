---
title: "Setting Up Elastic Beanstalk Health Checks With a Django Application"
date: 2019-01-15T20:33:50Z
tags: [django, elasticbeanstalk]
---

I was having an issue the past few days with Django and Elastic Beanstalk in a production environment that was driving me nuts.

Basically the Elastic Beanstalk environment was in a permament Severe/Degraded state. The health monitoring was reporting that 100% of the requests to the load balancer where `4xx` requests:

![Elastic Beanstalk 4xx requests](/posts/setting-up-elastic-beanstalk-health-checks-with-a-django-application/eb_unhealthy_400_requests.png)

This issue was probably caused by several reasons. In this post I will go over the reasons I think I was experiencing it, and how it was fixed in the end.

<!--more-->

## My Environment

Before I start, I want to briefly go over my Elastic Beanstalk environment's properties:

- Load balanced (1 to 4 instances) with an **Application Load Balancer**
- HTTPS secured
- Django 1.11

It is worth mentioning that despite the health check constantly failing, the application is working and running fine.

## Troubleshooting The 4xx Requests

Inspecting the logs revealed messages such as these:

```
GET / http/1.1" 400 26 "-" "ELB-HealthChecker/2.0
```

What this means is that the health check process in EB is making a request to the health check path (usually `/` by default), but this path is returning HTTP status code 400 (Bad Request).

After many hours of research and debugging, I found out that this is caused because **the IP address of the EC2 instance that sends the health check request to Django must be included in the `ALLOWED_HOSTS` setting in Django**.

The tricky thing here though is that this IP address will not be permanent, so we must obtain this address dynamically and add it to our settings. The way to do this is by querying the [EC2 instance metadata service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) from the current instance to obtain its address:

```python
# settings/prod.py

import requests


def get_ec2_instance_ip():
    """
    Tries to obtain the IP address of the current EC2 instance in AWS
    """
    try:
        ip = requests.get(
          'http://169.254.169.254/latest/meta-data/local-ipv4',
          timeout=0.01
        ).text
    except requests.exceptions.ConnectionError:
        return None
    return ip


AWS_LOCAL_IP = get_ec2_instance_ip()
ALLOWED_HOSTS = [AWS_LOCAL_IP, 'mydomain.com', 'etc']
```

This made the health check responses go from 400 to 301 ([Moved Permanently](https://en.wikipedia.org/wiki/HTTP_301)). Not quite there yet, but getting there.

## Fixing The 3xx Requests

The health now reports 100% of requests failing with 3xx. The reason for this is because the Django application is secured with HTTPS and has some security configurations such as these:

```python
# settings.prod.py

# https://docs.djangoproject.com/en/1.11/topics/security/
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_HSTS_SECONDS = 60
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
X_FRAME_OPTIONS = 'DENY'
```

This ensures that _all_ requests to the application must be done with HTTPS. Requests done using HTTP will be redirected to HTTPS. This is what the 301 status code means. Django receives the health check request at `/`. Since this is an HTTP request, it returns the 301 code indicating that the request should be resent using HTTPS. This is something that browsers do automatically.

To fix this, we can include the 301 code to the acceptable health check responses. To do this navigate to _EC2 > Load Balancing > Target Groups_ and select the target group that your load balancer is currently using and under the _Health Checks_ tab, select _edit_ and set `200-301` for the _Success codes_ field.

The health check should now be working and your instance status should return to an OK state :tada:
