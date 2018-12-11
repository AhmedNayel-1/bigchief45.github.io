---
date: '2016-10-26'
tags:
- zenoss
- python
- zenpacks
title: Changing Zenoss Dashboard Portlets Using CLI
---

The Zenoss [ZenPacks.zenoss.Dashboard](http://wiki.zenoss.org/ZenPack:Dashboard) ZenPack adds a very nice and new dashboard to our Zenoss Core 4 deployment, replacing the old default dashboard that comes with the installation.

![ZenPack Dashboard](http://wiki.zenoss.org/images/0/01/Separate_dashboard.png)

<!--more-->

We can see that the dashboard shows some portlets by default, from the list of available portlets.

The source code that does this can be found in `ZenPacks.zenoss.Dashboard/ZenPacks/zenoss/Dashboard/__init__.py`:

```python
DEFAULT_DASHBOARD_STATE = '[{"id":"col-0","items":[{"title":"Welcome to Zenoss!","refreshInterval":3000,"config":{"siteUrl":"https://www2.zenoss.com/in-app-welcome?v=4.9.70&p=core"},"xtype":"sitewindowportlet","height":399,"collapsed":false},{"title":"Google Maps","refreshInterval":300,"config":{"baselocation":"/zport/dmd/Locations","pollingrate":400},"xtype":"googlemapportlet","height":400,"collapsed":false}]},{"id":"col-1","items":[{"title":"Open Events","refreshInterval":300,"config":{"stateId":"ext-gen1351"},"xtype":"eventviewportlet","height":400,"collapsed":false},{"title":"Open Events Chart","refreshInterval":300,"config":{"eventClass":"/","summaryFilter":"","daysPast":3},"xtype":"openeventsportlet","height":400,"collapsed":false}]}]'
```

It is basically a big JSON formatted string that describes which portlets go into which columns, with what kind of configurations. This string is then later assigned to a Dashboard object inside the `_buildRelationships` method:

```python
# ...
dashboard = Dashboard('default')
dashboard.columns = 2
dashboard.owner = 'admin'
dashboard.state = DEFAULT_DASHBOARD_STATE
dmd.ZenUsers.dashboards._setObject('default', dashboard)
```

## Changing The State

We can then manually change the default state by opening a *zendmd* shell (type `zendmd` in your console as the `zenoss` user):

```python
from ZenPacks.zenoss.Dashboard.Dashboard import Dashboard

dashboard = Dashboard('default')
dashboard.columns = 2
dashboard.owner = 'admin'
dashboard.state = 'NEW_STATE_IN_JSON_FORMAT'

commit()
```

The `commit()` instruction is necessary for changes to take place. After this, refreshing your dashboard should now reflect its new state.