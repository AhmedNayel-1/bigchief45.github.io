---
date: '2018-09-18'
tags: [aws lambda, python, serverless]
title: Recursive Python AWS Lambda Functions
---

There are times where some processing task cannot be completed under the AWS Lambda timeout limit (a maximum of 5 minutes as of this writing). A possible solution for these kind of situations is to implement a recursive approach to perform the processing task.

Basically, if you are able to separate the task into multiple chunks or batches, then you could make each batch to be processed by a different Lambda function. The amount of Lambda functions necessary to finish the task will scale accordingly.

<!--more-->

## Defining Our Use Case

Let's base our business logic on a very common use case: processing of uploaded files to S3. Obviously it is implied that we will be dealing with a processing task that will require a relatively large amount of time (i.e more than 5 minutes) to complete, for each file.

Additionally we will also be using an SQS queue, therefore everytime a file is uploaded to S3, a message is sent to the queue, and each message will trigger our _initial_ functions.

## Implementing Recursion

Let's begin writing the handler for our Lambda function. The first thing we need to do is parse the event object to get the S3 key of the uploaded file:

```python
import os
import json

import boto3


BATCH_SIZE = 400


def handler(event, context):
    sqs_record = event['Records'][0]  # Assumes a Batch Size of 1 in the queue
    position = event.get('position', 0)  # Represents the starting position
    key = _get_object_key_from_s3_notification(sqs_record)


def _get_object_key_from_s3_notification(record):
    """Returns the file's S3 key from the record object."""

    body = json.loads(record['body'])
    msg = json.loads(body['Message'])
    return msg['Records'][0]['s3']['object']['key']
```

Now we can proceed to download the file. Let's keep in mind that we want to make use of the optimization benefits that container re-use gives us. This means that we will first check if the file already exists before we proceed to download it:

```python
def handler(event, context):
    # ...

    file_path = '/tmp/{}'.format(key)
    file_exists = os.path.exists(file_path)
    if not file_exists:
        print('File does not exists. Downloading...')
        # Download the file from S3

    # Processing of the batch goes here

    position += BATCH_SIZE  # Move the position pointer for next batch
    if not _process_is_complete(position):
         # Some function that can determine if the process is completed or not.
         # If it's not, a new function will be invoked.
         event['position'] = position
         _recurse(context, event)
    else:
        print('Processing complete')
        os.remove(file_path)  # Cleanup


def _recurse(context, payload):
    lambda_client = boto3.client('lambda')
    lambda_client.invoke(
        FunctionName=context.function_name,
        InvocationType='Event',
        Payload=json.dumps(payload)
    )
```

And there you have it! This code will spawn multiple Lambda functions depending on how many batches are needed to complete the whole process. Of course you will need to add the necessary logic for `_process_is_complete()` in order to know when to stop.