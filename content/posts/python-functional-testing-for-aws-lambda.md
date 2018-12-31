---
title: "Python Functional Testing for AWS Lambda"
date: 2018-12-26T17:17:28Z
tags: [python, pytest, aws lambda, serverless, tdd]
---

In this post I will explain and go over how I personally write functional tests for my AWS Lambda functions.

For our example use case, we will assume that our Lambda function is quite complex, as in that it involves downloading a file, processing it, and uploading a result. Additionally it will be called by an SQS event, and it make use of other non-Python related elements, as we will see later.

Let's get started!

<!--more-->

## A Look Into Our Lambda Function

Keeping in mind the characteristics I just mentioned, our Lambda funtion will more or less look like this:

```python
import os
import subprocess

import boto3


s3_client = boto3.client('s3')


def handler(event, context):
    # Pickup the record from the SQS Event
    for record in event['Records']:
        # Some convenience method for parsing the
        # record object
        sqs_msg = _get_sqs_message_obj(record)

        # Let's assume the event is triggered from a
        # file uploaded to S3
        bucket_name = sqs_msg['Records'][0]['s3']['bucket']['name']
        key = sqs_msg['Records'][0]['s3']['object']['key']

        # Download the file
        s3_client.download_file(
            Bucket=bucket_name,
            Key=key,
            Filename='somepath'
        )

        # Some processing is done with this file.
        # Let's assume we call some native program to process this
        # file, using subprocess.check_call
        cmd = ['some', 'command']

        try:
            subprocess.check_call(cmd)
        except Exception:
            pass
        else:
            # After the processing is done, the result is uploaded to
            # S3
            s3_client.put_object()
        finally:
            # Some cleanup of the container could be done here.
            # We can also assert this in our tests
            os.remove('somefile.json')
            os.remove('somefileother.xml')
```

Now that we understand more or less the elements and instructions that compose our function. Let's take a look on how we can write a functional test for it.

## A Functional Test For Our Function

The test should be very simple. Basically it should just call the `handler` and assert the necessary changes. The hard part is actually mocking everything that happens inside the function.

Basically we need to mock the following things:

- SQS event payload
- S3 Bucket
- File that is uploaded to the bucket
- The subprocess call (optional, I'll discuss this later)

I discuss how to mock all the above things (except the last one) in my previous post, [*Pytest Tricks for Better Python Tests*](/posts/pytest-tricks-for-better-python-tests/).

This is how our functional test looks like:

```python
import os

from myapp.my_lambda_function import handler


class LambdaTest:
    def test_function(self, s3_bucket, file_mock, sqs_event):
        # We will first place the file manually in the bucket
        file_key = 'myfile.txt'
        s3_bucket.put_object(Key=file_key, Body=file_mock)

        # Use the mocked payload so that we can send it to the
        # handler.
        payload = sqs_event(file_key)

        handler(payload, None)

        # Now comes the good stuff. First let's assert that the
        # result was uploaded successfully to the bucket
        result_key = 'result.json'
        r = s3_bucket.Object(result_key).get()

        # If the result file isn't in the bucket, an exception
        # will be raised.
        assert r['ResponseMetadata']['HTTPStatusCode'] == 200

        # As I mentioned in the Lambda function, we will probably
        # want to assert that cleanups (i.e deleted files) made to
        # the environment were made successfully
        assert not os.path.exists('somefile.json')
        assert not os.path.exists('someotherfile.xml')
```

As you can see, the test is quite simple. Mostly it's just manually calling the `handler()` function and asserting the necessary stuff. The heavy loading is done with all the fixtures we created, as explained in [*Pytest Tricks for Better Python Tests*](/posts/pytest-tricks-for-better-python-tests/).

### Should I Mock the Subprocess Call?

Previously I mentioned that mocking `subprocess.check_call` was optional. The reason for this is because if we only mock the call without providing any side effect that our Lambda Function can use, the test will obviously fail.

As you can tell from our example, the subprocess call probably calls some program that generates a result file from our downloaded file. In the test, this will be done automatically because the call is not mocked.

## Closing Thoughts

:tada: :tada: :tada: There you have it! A nice functional test for an AWS Lambda function that we can call and run **locally**.

If you have any questions please feel free to ask in the comments section.
