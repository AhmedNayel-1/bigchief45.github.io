---
date: '2016-10-28'
tags:
- juju
- keystone
- devops
- bash
- keystone
- openstack
title: Keystone Interface in Juju Charms
---

[Juju Charms interfaces](https://jujucharms.com/docs/1.18/authors-interfaces) make possible the interaction and exchange of data between services deployed by Juju. In this post I will explain how we can use the Keystone interface to make our custom charm service comunicate with the Keystone service within a Juju environment.

In the end, what we really want to achieve, is to link both services so that they can exchange data, using a Juju command:

`juju add-relation keystone myservice`

## Juju Relations

Juju relations operate behind the concept that one service provides something, while another service requires it, and the interaction between the services is done through an **interface**. Since we want to interact with Keystone, this means that we need to use a suitable keystone interface that allows us to get what we need, the *keystone Identity data*. For this, we use the **[keystone-admin interface](https://git.launchpad.net/~canonical-is/charms/+source/interface-keystone-admin)**.

With this in mind, we configure our charm to require this relation and interface in `metadata.yaml`:

```yaml
# ...
requires:
  identity-admin:
    interface: keystone-admin
```

<!--more-->

## Relation Hooks

Now that the relation and interface is correctly configured, we can use the interface to obtain the necessary data in our hooks.  The hook that we need to implement is the *identity-admin-relation-changed* hook, which will be triggered when we run the `juju add-relation keystone myservice`.

From Juju Docs:

**name-relation-changed:** *Always run once, after -joined, and will subsequently be run whenever that remote unit changes its settings for the relation. It should be the only hook that relies upon remote relation settings from relation-get, and it should not error if the settings are incomplete.*

Inside the hook we will try to obtain Keystone's hostname address. If we successfully obtain one, then we proceed to use JuJu's `relation-get` command to retrieve the data provided by the Keystone interface, which can then be used by our service for any particular purpose.

**identity-admin-relation-changed (Bashscript):**

```bash
#!/bin/bash

set -eux

juju-log "Joining with Keystone at $JUJU_REMOTE_UNIT"

# Get the Keystone hostname
service_hostname=`relation-get service_hostname`

# Check if a valid Keystone hostname value was obtained
if [ -z "$service_hostname" ] ; then
   juju-log "No Keystone service hostname sent yet..."
   exit 0
fi

# For our example, we will write a Keystone configuration file
# to the ubuntu user home directory
juju-log "Creating keystone credentials file in /home/ubuntu"
touch /home/ubuntu/keystone
echo "Keystone Credentials" >> /home/ubuntu/keystone
echo "--------------------" >> /home/ubuntu/keystone

keystone_creds=`relation-get` # Retrieves ALL values
echo "$keystone_creds" >> /home/ubuntu/keystone

# We can also retrieve individual values:
service_password=`relation-get service_password`
service_port=`relation-get service_port`
service_region=`relation-get service_region`
service_tenant_name=`relation-get service_tenant_name`
service_username=`relation-get service_username`
auth_url="http://$service_hostname:$service_port/v2.0"