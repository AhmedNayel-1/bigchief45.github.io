---
date: '2018-06-26'
tags:
- python
- django
title: BytesIO File Uploads to Django Using Requests
---

It's very easy to post file data to Django using requests:

```python
import requests


requests.post(url, files={'cover': open('imgpath.jpg', 'rb')})
```

However I was having a hard time getting that to work using [BytesIO](https://wiki.python.org/moin/BytesIO). The reason I wanted to use BytesIO was because I was reading the file binary data located in S3, from AWS Lambda. I didn't want to write the file to disk first and then do something like the code shown above.

Here's how to achieve that:

<!--more-->

```python
import io

import boto3
import requests


# Object in S3
s3_file = boto3.resource('s3').Object('my-bucket', 'key')

# Read Bytes data into BytesIO
file_bytes = io.BytesIO(s3_file.get()['Body'].read())

# Post file using requests
files = {'avatar': ('myimage.jpg', file_bytes)}
requests.post('someurl', files=files)
```

The trick here in order for Django to recognize this file upload, is to define the `files` dictionary with a tuple that contains a dummy file name along with the binary data. As you can see, the approach that uses `open()` does not need this, and this is what took me a while to figure out.

If in your Django application you assign a particular file name to the uploaded file, then this dummy name will be discarded after the file is posted.