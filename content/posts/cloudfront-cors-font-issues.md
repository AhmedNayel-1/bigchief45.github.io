---
title: "CloudFront CORS Font Issues"
date: 2018-12-12T16:32:22Z
tags: [cloudfront, cors]
---

I was experiencing an issue with CloudFront and some static assets of a Django application deployed to ElasticBeanstalk. The issue was happening when trying to retrieve some fonts that are stored in S3 and served by CloudFront, the browser dev tools would show some errors similar to the following:

```
Access to Font at 'http://CLOUDFRONT_HOSTNAME.cloudfront.net/FONT_PATH' from origin 'http://www.example.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

A [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) issue. And apparently, very common when trying to load fonts.

To fix this, there are a few possible things that you might have to try. I will list some of the fixes I found.

<!--more-->

## S3 Bucket CORS Policy

You might have to begin by setting an appropriate CORS policy for the S3 Bucket. In the S3 Console, navigate to _Your Bucket > Permissions > CORS Configuration_ and paste the following configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
<CORSRule>
    <AllowedOrigin>*</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <MaxAgeSeconds>3000</MaxAgeSeconds>
    <AllowedHeader>Authorization</AllowedHeader>
</CORSRule>
</CORSConfiguration>
```

Some people have reported that changing the value of `<AllowedHeader>` to `*` fixed their issue. So you might want to keep that in mind as well.

## CloudFront Whitelisted Headers

This was the solution that fixed the issue for me. In the CloudFront Console, navigate to your CloudFront distribution's _Behaviors_ tab.

Select the existing default behavior (`Default (*)`) and select _Edit_. For the _Cache Based on Selected Request Headers_ option, select _Whitelist_ from the dropdown. This will prompt a list of headers to appear. Look for the _Origin_ header and add it to the whitelist, and save the changes.

## References

1. http://thelazylog.com/correct-configuration-to-fix-cors-issue-with-cloudfront/
2. https://serverfault.com/questions/867016/aws-s3-cloudfront-web-font-cors-error
