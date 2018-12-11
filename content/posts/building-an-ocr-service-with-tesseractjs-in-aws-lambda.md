---
date: '2017-11-21'
tags: [nodejs, aws lambda, serverless, ocr]
title: Building an OCR Service With TesseractJS in AWS Lambda
---

The past few days I was trying to make [TesseractJS](https://github.com/naptha/tesseract.js) work in [AWS Lambda](https://aws.amazon.com/lambda/) so that I could do some OCR (Optical Character Recognition) on some images I had stored in an S3 bucket. However I am a bit new to NodeJS and I was running into some difficulties getting it to work in the Lambda environment. In this post I am going to go through some of these issues and how I solved them.

TesseractJS is a OCR library written in pure JavaScript. It can recognize the text in images, as well as provide information about the location of the paragraphs, lines, and words in the document.

We will be using a **NodeJS 6.10** runtime in AWS Lambda. And I will be deploying the service with [ClaudiaJS](https://claudiajs.com/).

## Downloading the TesseractJS Files

When running TesseractJS to recognize an image, TesseractJS will automatically begin downloading some files, which include tesseract language files, a core library file, and a worker file. These are all files that TesseractJS requires in order to correctly run.

The problem occurs when trying to download these inside AWS Lambda, since Lambda only allows writing to the `/tmp/` directory, you will get an error like this in your logs:

```
Error: EROFS: read-only file system, open 'eng.traineddata'
```

<!--more-->

To solve this issue, we will need to download the TesseractJS [repository](https://github.com/naptha/tesseract.js), unzip it and place it inside our ClaudiaJS project. There are some files that are not needed, such as `examples` and `docs` directories, as well as other documentation files.

Additionally, we will need to package the language files along with our ClaudiaJS deployment package. Simply download the necessary language files from the [repository](https://github.com/naptha/tessdata/tree/gh-pages/3.02), use something like **gunzip** to extract the contents, and then place them somewhere inside the TesseractJS repository directory we just added inside our ClaudiaJS project, such as a `/lang` directory.

After this, you should have something like this:

```
├── claudia.json
├── lambda.js
├── node_modules
├── package.json
└── tesseract
    ├── dist
    ├── lang
    └── src
```

Then, when requiring TesseractJS in your Lambda function, you will have to specify path parameters for the language files, worker, and core library to TesseractJS, as described in the [local installation](https://github.com/naptha/tesseract.js#local-installation) part of the documentation.

```javascript
const path = require('path');

const Tesseract = require('tesseract.js').create({
    workerPath: path.join(__dirname, 'tesseract/src/node/worker.js'),
    langPath: path.join(__dirname, 'tesseract/lang/'),
    corePath: path.join(__dirname, 'tesseract/src/index.js')
});
```

The `__dirname` variable is what makes it all work. It will point to the package's absolute path inside Lambda (which is something like `/var/task`) and then will find our language files and load them for TesseractJS.

-> In Node.js, `__dirname` is always the directory in which the currently executing script resides. [Read more](https://nodejs.org/api/globals.html#globals_dirname)

## Integrating With SNS (Simple Notification Service)

We want our Lambda function to be triggered as soon as an image file (i.e `jpg` file) is uploaded to our S3 bucket. You can configure an S3 event to the Lambda function from the AWS console, but I find a better and more scalable way is to subscribe the function to a SNS topic instead, and make S3 send events to this topic.

### Creating the SNS Topic

Head over to the [SNS](https://us-west-2.console.aws.amazon.com/sns) service > topics, and create a new topic and enter a name for it.

Once created, select the _Edit topic policy_ option for the topic and go to _Advanced view_. Change the policy to something like the following:

![SNS Topic Policy](https://s3.amazonaws.com/awscomputeblogmedia/fanout-topic-policy-json.png)

The policy above will allow the bucket to publish S3 events to it.

### Configure S3 Bucket to Publish Events

Now go to S3 > your bucket > Properties > Events and add a new notification. We are going to check the _ObjectCreate (All)_ event and add a _jpg_ suffix for the event. Lastly we will configure it to send it to the SNS topic we just created.

### Processing the SNS Event In The Lambda Function

Now when the JPG file is uploaded, S3 will publish the event to the SNS topic, which will send it to the Lambda function under the `event` parameter. We need to parse the JSON data of this event, and we can do so by creating a helper function in our main `lambda.js` file:

```javascript
function getSNSMessageObject(msg) {
    var x = msg.replace(/\\/g, '');
    var y = x.substring(1, x.length - 1);
    var z = JSON.parse(y);

    return z;
}
```

With this function, we can obtain the corresponding bucket and key of the file that was just uploaded:

```javascript
exports.handler = function(event, context, callback) {
    let snsMessage = getSNSMessageObject(
        JSON.stringify(event.Records[0].Sns.Message));
    let bucket = snsMessage.Records[0].s3.bucket.name;
    let key = snsMessage.Records[0].s3.object.key;

    // ...
};
```

We will use this information to obtain the image from S3 within our Lamdba function and proceed to process it with TesseractJS.

## Processing the Image: Memory Issues

I was experiencing a strange behavior when calling `Tesseract.recognize()` on an image, the Lambda function would terminate very quickly. No logs from the `progress()` callback where being shown, yet Lambda reported a full memory use. I thought this was a not-enough memory issue, so I increased the function's memory to 1GB, but no luck:

```javascript
Tesseract.recognize(img)
  .progress(msg => console.log(msg))
  .catch(err => console.log('Tesseract error: ', err))
  .then(function(result) {
      Tesseract.terminate();
      console.log(result);
  });
```

```
REPORT Duration: 29059.34 ms	Billed Duration: 29100 ms Memory Size: 1024 MB	Max Memory Used: 1024 MB
```

This was very strange. I could perfectly process the image in my development environment which has merely 512MB of RAM.

Anyways, I decided to ramp up the function's memory to the max (1536 MB), and lo and behold, it managed to run successfully, still _almost_ reaching the memory limit.

TODO: WHY DOES THIS HAPPEN?

## Asynchronous Processing

This part had more to do with me being a NodeJS noob than with TesseractJS.

Initially, I was first downloading the image file from my S3 bucket like this:

```javascript
var imgFile = fs.createWriteStream('/tmp/' + key);
var params = {Bucket: bucket, Key: key};
s3.getObject(params).createReadStream().pipe(imgFile);

// Process with Tesseract
// ...
```

This was not working, I was getting an error like the following:

```
/var/task/tesseract/src/common/desaturate.js:22
} else { throw 'Invalid ImageData' }

Invalid ImageData
```

This was happeing due to NodeJS asynchronous nature and how JavaScript and NodeJS works with callbacks. The code that proceeded to process the image with TesseractJS was probably being executed and the image wasn't fully obtained from S3 yet. I come from a Ruby & Python background so this was a bit difficult for me to grasp. I changed the above logic to implement [JavaScript native Promises](https://javascript.info/promise-basics):

```javascript
const s3 = require('./s3');
const ocr = require('./ocr');


exports.handler = function(event, context, callback) {
  s3.getImage(bucket, key)
    .then(function(data) {
        return ocr.recognizeImage(data.Body);
    })
    .then(function(result) {
        return s3.uploadOCR(bucket, bookId, pageNum, result);
    })
    .then(fulfilled => callback(null))
    .catch(error => callback(error, 'Error'));
};
```

Looks much better. The respective functions for obtaining the image and uploading the JSON to S3 are located inside the `s3.js` module in my project:

```javascript
'use strict';

const AWS = require('aws-sdk');
const s3 = new AWS.S3({region: 'us-west-1'});


module.exports = {
    getImage: function getImage(bucket, key) {
        let params = {Bucket: bucket, Key: key};
        return s3.getObject(params).promise();
    },

    uploadOCR: function uploadOCR(bucket, bookId, pageNum, ocr) {
        let params = {
            Bucket: bucket,
            Key: (bookId + '/' + pageNum + '.json'),
            Body: ocr,
            ContentType: 'application/json'
        };

        return s3.putObject(params).promise();
    }
};
```

As you can see, the AWS SDK provides a `promise()` object for requests to Amazon services.

Likewise, the function that calls TesseractJS is located inside the `ocr.js` module inside my project, and I wrap the process in a promise (Thanks [Bergi](https://stackoverflow.com/users/1048572/bergi) for suggestion against [Promise constructor antipattern](https://stackoverflow.com/q/23803743/1048572?What-is-the-promise-construction-antipattern-and-how-to-avoid-it)):

```javascript
recognizeImage: function recognizeImage(img) {
    return Promise.resolve(Tesseract.recognize(img))
        .then(function(result) {
            Tesseract.terminate();

            // Do some extra processing on the result

            return JSON.stringify(result);
        });
}
```

The `data` object from `s3.getObject()` is the de-serialized data returned from the request to S3 (docs [here](http://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/S3.html#getObject-property)). The `data.Body` is the raw binary image data and can be passed directly to TesseractJS.

-> The Node.js runtimes v4.3 and v6.10 support the optional `callback` parameter. You can use it to explicitly return information back to the caller. [Read more](http://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-handler.html)

We can then proceed to do more processing on the data returned by TesseractJS, and then later store it in something like ElasticSearch or S3.


## References

1. https://stackoverflow.com/questions/41063214/reading-a-packaged-file-in-aws-lambda-package
2. https://aws.amazon.com/blogs/compute/fanout-s3-event-notifications-to-multiple-endpoints/
2. https://github.com/naptha/tesseract.js/issues/164#issuecomment-345984952
3. http://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-handler.html
4. https://javascript.info/callbacks
5. https://javascript.info/promise-chaining