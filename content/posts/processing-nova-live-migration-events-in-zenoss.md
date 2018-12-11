---
date: '2017-01-23'
tags:
- zenoss
- zenpacks
- openstack
- nova
- ceilometer
- rabbitmq
- monitoring
title: Processing Nova Live Migration Events in Zenoss
---

When monitoring OpenStack using the OpenStack Infrastructure ZenPack integrated with Ceilometer, it is possible to get fast virtual machine state changes (on/off powering, etc.) by receiving events sent from Ceilometer to Zenoss.

However I discovered that when trying to get the same effect for **live migration** (live migrating a virtual machine from one compute node to another) scenarios, this would not work. I proceeded to investigate why.

## Ceilometer Dispatcher Live Migration Events

I decided that the first thing to check was if the [Zenoss Ceilometer dispatcher](https://github.com/zenoss/ceilometer_zenoss) was **capturing** and **sending** the live migration events to Zenoss. Indeed, the logs can be found in Ceilometer under `/var/log/ceilometer/ceilometer-collector.log`:

```
2017-01-23 14:22:02.593 25667 INFO ceilometer_zenoss.dispatcher.zenoss [-] record_events called (events=[<Event: 3538a01c-ab8d-4e64-b0ff-6e8fe270e06a, compute.instance.live_migration.post.dest.start, 2017-01-23 06:22:02.584049, <Trait: state_description 1 migrating> <Trait: memory_mb 2 512> <Trait: ephemeral_gb 2 0> <Trait: fixed_ips 1 [{u'version': 4, u'vif_mac': u'fa:16:3e:6e:02:e9', u'floating_ips': [], u'label': u'admin-net', u'meta': {}, u'address': u'192.168.0.15', u'type': u'fixed'}]> <Trait: user_id 1 6d581c230c86475abf70cce41440e8a1> <Trait: service 1 compute> <Trait: priority 1 info> <Trait: state 1 active> <Trait: launched_at 4 2017-01-23 05:06:41> <Trait: flavor_name 1 m1.tiny> <Trait: disk_gb 2 1> <Trait: display_name 1 pdcmtest> <Trait: root_gb 2 1> <Trait: tenant_id 1 10296907e44248d2a707689f77d59ef6> <Trait: instance_id 1 87be4b45-e214-4ca3-8f5c-1bd31159f9e4> <Trait: vcpus 2 1> <Trait: host_name 1 ndc27-3222> <Trait: request_id 1 req-d4c27d06-6329-4ce0-adb5-370b8ca83a22>>])

2017-01-23 14:22:02.771 25667 INFO ceilometer_zenoss.dispatcher.zenoss [-] record_events called (events=[<Event: 8db64329-606c-4184-9b5b-eb815166cb17, compute.instance.live_migration.post.dest.end, 2017-01-23 06:22:02.761138, <Trait: state_description 1 > <Trait: memory_mb 2 512> <Trait: ephemeral_gb 2 0> <Trait: fixed_ips 1 [{u'version': 4, u'vif_mac': u'fa:16:3e:6e:02:e9', u'floating_ips': [], u'label': u'admin-net', u'meta': {}, u'address': u'192.168.0.15', u'type': u'fixed'}]> <Trait: user_id 1 6d581c230c86475abf70cce41440e8a1> <Trait: service 1 compute> <Trait: priority 1 info> <Trait: state 1 active> <Trait: launched_at 4 2017-01-23 05:06:41> <Trait: flavor_name 1 m1.tiny> <Trait: disk_gb 2 1> <Trait: display_name 1 pdcmtest> <Trait: root_gb 2 1> <Trait: tenant_id 1 10296907e44248d2a707689f77d59ef6> <Trait: instance_id 1 87be4b45-e214-4ca3-8f5c-1bd31159f9e4> <Trait: vcpus 2 1> <Trait: host_name 1 ndc27-3222> <Trait: request_id 1 req-d4c27d06-6329-4ce0-adb5-370b8ca83a22>>])

2017-01-23 14:22:02.782 25667 INFO ceilometer_zenoss.dispatcher.zenoss [-] record_events called (events=[<Event: d0dc4f4a-454a-42c5-b767-386dc3e0d1f3, compute.instance.live_migration._post.end, 2017-01-23 06:22:02.776665, <Trait: state_description 1 migrating> <Trait: memory_mb 2 512> <Trait: ephemeral_gb 2 0> <Trait: fixed_ips 1 [{u'version': 4, u'vif_mac': u'fa:16:3e:6e:02:e9', u'floating_ips': [], u'label': u'admin-net', u'meta': {}, u'address': u'192.168.0.15', u'type': u'fixed'}]> <Trait: user_id 1 6d581c230c86475abf70cce41440e8a1> <Trait: service 1 compute> <Trait: priority 1 info> <Trait: state 1 active> <Trait: launched_at 4 2017-01-23 05:06:41> <Trait: flavor_name 1 m1.tiny> <Trait: disk_gb 2 1> <Trait: display_name 1 pdcmtest> <Trait: root_gb 2 1> <Trait: tenant_id 1 10296907e44248d2a707689f77d59ef6> <Trait: instance_id 1 87be4b45-e214-4ca3-8f5c-1bd31159f9e4> <Trait: vcpus 2 1> <Trait: host_name 1 ndc27-3205> <Trait: request_id 1 req-d4c27d06-6329-4ce0-adb5-370b8ca83a22>>])
```

Notice the `live_migration.post.dest.start` and `live_migration.post.dest.end` logs.

<!--more-->

## OpenStack Infrastructure ZenPack OpenStack Events

### Searching for Live Migration Logs in Zenoss

Next I had to check if the ZenPack was actually able to recognize these events. Clearly events for instance state change were being recognized since I could see the instance's state change on the Zenoss user interface. The ZenPack's datasource responsible for processing these events is found in `datasources/EventsAMQPDataSource.py`, here we can see some debug logging for each incoming event received:

```python?line_numbers=false
def processMessage(self, amqp, device_id, message):
    try:
        value = json.loads(message.content.body)
        log.debug(value)

        if value['device'] != device_id:
            log.error("While expecting a message for %s, received a message regarding %s instead!" % (device_id, value['device']))
            return

        if value['type'] == 'event':
            # Message is a json-serialized version of a ceilometer.storage.models.Event object
            # (http://docs.openstack.org/developer/ceilometer/_modules/ceilometer/storage/models.html#Event)
            timestamp = amqp_timestamp_to_int(value['data']['generated'])
            log.debug("Incoming event (%s) %s" % (timestamp, value['data'])) # LOG HERE
            cache[device_id].add(value['data'], timestamp)
        else:
            log.error("Discarding unrecognized message type: %s" % value['type'])
```

Since Zenoss only logs INFO level logs and above, I had to toggle the `zenpython` daemon for debug mode:

```
zenpython debug
```

Next we can check the logs in `$ZENHOME/log/zenpython.log` for incoming live migration logs produced by the code above:

```
2017-01-23 17:21:04,289 DEBUG zen.zenpython: Queued event (total of 6) {u'trait_display_name': u'pdcmtest3', u'trait_request_id': u'req-98542dfd-e17b-4ec8-b4b8-90f78205a75e', 'device_guid': '1ee50718-3d16-4e4a-9378-d8e22c98eb50', u'trait_user_id': u'6d581c230c86475abf70cce41440e8a1', 'eventClassKey': u'openstack|compute.instance.live_migration.post.dest.start', u'trait_tenant_id': u'10296907e44248d2a707689f77d59ef6', u'trait_memory_mb': 512, u'trait_service': u'compute', 'agent': 'zenpython', 'manager': 'localhost', u'trait_host_name': u'ndc27-3205', 'rcvtime': 1485163264.289413, 'device': 'OpenStack', u'trait_state': u'active', 'monitor': 'localhost', u'trait_root_gb': 1, u'trait_launched_at': u'2017-01-23T08:12:14.000000', 'severity': 2, u'trait_flavor_name': u'm1.tiny', u'trait_disk_gb': 1, u'trait_instance_id': u'a0e7145b-21b0-4f3b-ba37-755cfcc069de', u'trait_state_description': u'migrating', 'summary': u'OpenStackInfrastructure: compute.instance.live_migration.post.dest.start', u'trait_vcpus': 1, u'trait_fixed_ips': u"[{u'version': 4, u'vif_mac': u'fa:16:3e:1b:4f:d0', u'floating_ips': [], u'label': u'admin-net', u'meta': {}, u'address': u'192.168.0.16', u'type': u'fixed'}]", 'eventKey': u'b5e42f1b-7300-44de-928a-e6904f29fd12', u'trait_ephemeral_gb': 0, u'trait_priority': u'info'}

2017-01-23 17:21:04,290 DEBUG zen.zenpython: Queued event (total of 7) {u'trait_display_name': u'pdcmtest3', u'trait_request_id': u'req-98542dfd-e17b-4ec8-b4b8-90f78205a75e', 'device_guid': '1ee50718-3d16-4e4a-9378-d8e22c98eb50', u'trait_user_id': u'6d581c230c86475abf70cce41440e8a1', 'eventClassKey': u'openstack|compute.instance.live_migration.post.dest.end', u'trait_tenant_id': u'10296907e44248d2a707689f77d59ef6', u'trait_memory_mb': 512, u'trait_service': u'compute', 'agent': 'zenpython', 'manager': 'localhost', u'trait_host_name': u'ndc27-3205', 'rcvtime': 1485163264.289977, 'device': 'OpenStack', u'trait_state': u'active', 'monitor': 'localhost', u'trait_root_gb': 1, u'trait_launched_at': u'2017-01-23T08:12:14.000000', 'severity': 2, u'trait_flavor_name': u'm1.tiny', u'trait_disk_gb': 1, u'trait_instance_id': u'a0e7145b-21b0-4f3b-ba37-755cfcc069de', u'trait_state_description': u'', 'summary': u'OpenStackInfrastructure: compute.instance.live_migration.post.dest.end', u'trait_vcpus': 1, u'trait_fixed_ips': u"[{u'version': 4, u'vif_mac': u'fa:16:3e:1b:4f:d0', u'floating_ips': [], u'label': u'admin-net', u'meta': {}, u'address': u'192.168.0.16', u'type': u'fixed'}]", 'eventKey': u'bfcdb673-04f8-4665-8924-997540a168f0', u'trait_ephemeral_gb': 0, u'trait_priority': u'info'}
```

Clearly the ZenPack indeed recognizes these live migration events. But why won't the instance's hostname change?

### OpenStack Infrastructure Event Mappings

The OpenStack Infrastructure ZenPack defines some event mappings in `events.py`. If we do a `live_migration` search in this file we will find some mapping definitions:

```python
# Note: I do not currently have good test data for what a real
# live migration looks like.  I am assuming that the new host will be
# carried in the last event, and only processing that one.
'openstack|compute.instance.live_migration.pre.start': (instance_id, None),
'openstack|compute.instance.live_migration.pre.end': (instance_id, None),
'openstack|compute.instance.live_migration.post.dest.start': (instance_id, None),
'openstack|compute.instance.live_migration.post.dest.end':  (instance_id, None),
'openstack|compute.instance.live_migration._post.start':  (instance_id, None),
'openstack|compute.instance.live_migration._post.end': (instance_id, instance_update),
```

It seems that the author is not sure exactly how to work with these live migration events. We can see that only the last definition (`_post.end`) has a function called `instance_update` assigned. This is the function that will update the instance's information, such as the instance state.

However the problem here is that this is not the definition that should be used. The `openstack|compute.instance.live_migration.post.dest.end` definition is the one that should be used instead. I arrived at these conclusions from all the log researching I discussed before.

If remove the function from `_post.end` and assign it to `post.dest.end`, then this should fix all these issues:

```python
'openstack|compute.instance.live_migration.pre.start': (instance_id, None),
'openstack|compute.instance.live_migration.pre.end': (instance_id, None),
'openstack|compute.instance.live_migration.post.dest.start': (instance_id, None),
'openstack|compute.instance.live_migration.post.dest.end':  (instance_id, instance_update),
'openstack|compute.instance.live_migration._post.start':  (instance_id, None),
'openstack|compute.instance.live_migration._post.end': (instance_id, None),
```

Re-install the ZenPack, restart *zenhub* and *zopectl*, and then finally perform an instance live migration from the Horizon dashboard and you should quickly see the instance's host change in the Zenoss interface.

## Further Investigation

While following the instructions above solves the issue, there is still some very interesting stuff that I learned about this ZenPack. If we go to the `instance_update` function definition we arrive upon the following code:

```python
def instance_update(device, dmd, evt):
    evt.summary = "Instance %s updated" % (evt.trait_display_name)

    objmap = instance_objmap(evt)
    _apply_instance_traits(evt, objmap)
    return [objmap]
```

This function takes us to another function:

```python
def _apply_instance_traits(evt, objmap):
    traitmap = {
                'display_name': ['title', 'hostName'],
                'instance_id':  ['resourceId', 'serverId'],
                'state':        ['serverStatus'],
                'flavor_name':  ['set_flavor_name'],
                'host_name':    ['set_host_name'],
                'image_name':   ['set_image_name'],
                'tenant_id':    ['set_tenant_id']
               }
    # ...
```

You could say that the above traits are the instance's fields that can be updated for the Instance object. We can clearly see that `state` and `host_name` are present. By discovering this I realized that no additional code would be needed inside the ZenPack's datasource in order to fix this live migration issue.