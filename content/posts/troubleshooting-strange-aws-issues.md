---
date: '2018-08-07'
tags:
- aws
title: Troubleshooting Strange AWS Issues
---

We've all been there. The same things working fine one time but failing other times without any idea why.

This post is a list of troubleshooting strange issues I've encountered when using AWS.

## ElasticBeanstalk Failing to Create RDS Security Group

I was having an issue where I couldn't create and attach an RDS database to an ElasticBeanstalk environment because an RDS security group was failing at being created. All this was being done using the AWS console.

<!--more-->

The ElasticBeanstalk logs where showing the following:

```
2018-08-07 13:10:04 UTC-0600	ERROR	Creating RDS database security group named: <name> failed Reason: Either the resource does not exist, or you do not have the required permissions.
2018-08-07 13:10:04 UTC-0600	ERROR	Service:AmazonCloudFormation, Message:Stack named '<stack name>' aborted operation. Current state: 'UPDATE_ROLLBACK_IN_PROGRESS' Reason: The following resource(s) failed to create: [AWSEBRDSDBSecurityGroup].
```

This was strange. I had never encoutered this issue when creating and attaching an RDS database to an ElasticBeanstalk environment. I managed to find this [ServerFault question](https://serverfault.com/questions/920834/cant-add-rds-database-to-elastic-beanstalk-environment) which presented the exact same problem. Yet no concrete solution was given.

#### Solution

The problem indeed is that there are somehow no permissions configured to create the security group in question. I started to inspect another AWS account's (used for dev purposes) IAM Roles and noticed that one role was missing in the account where the issue was happening.

This role was the `AWSServiceRoleForRDS`. I am not sure exactly why this role was missing from the list, while other roles (such as `AWSServiceRoleForSupport`) weren't. Anyways, I proceeded to create the `AWSServiceRoleForRDS` manually in IAM and afterwards proceeded again to create and attach the RDS database.

Solved!

#### References

- [Can't add RDS database to Elastic Beanstalk environment](https://serverfault.com/questions/920834/cant-add-rds-database-to-elastic-beanstalk-environment)

Stay tuned for more issues to come!