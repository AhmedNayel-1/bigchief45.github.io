---
date: '2016-11-03'
tags:
- zenoss
- monitoring
- snmp
- data
- linux
- cpu
- rrdtool
- rpn
- python
title: Zenoss Monitoring Template Data Points
---

_Content from this post is mostly obtained from **Zenoss Core Administration guide**._

In Zenoss Core **monitoring templates**, data sources can return data for one or more performance metrics. Each metric retrieved by a data source is represented
by a **data point**.

When creating a data point, there are some important fields that we can define for our data point:

- **Name:** Displays the name you entered in the *Add a New DataPoint* dialog.

- **RRD Type:** Specify the RRD data source type to use for storing data for this data point. (Zenoss Core uses RRDTool to store performance data.) Available options are:
  - **COUNTER:** Saves the rate of change of the value over a step period. This assumes that the value is always
increasing (the difference between the current and the previous value is greater than 0). Traffic counters on a
router are an ideal candidate for using COUNTER.
  - **GAUGE:** Does not save the rate of change, but saves the actual value. There are no divisions or calculations.
To see memory consumption in a server, for example, you might want to select this value.

  - **DERIVE:** Same as COUNTER, but additionally allows negative values. If you want to see the rate of change
in free disk space on your server, for example, then you might want to select this value.

  - **ABSOLUTE:** Saves the rate of change, but assumes that the previous value is set to 0. The difference between
the current and the previous value is always equal to the current value. Thus, ABSOLUTE stores the current
value, divided by the step interval.

- **Create Command:** Enter an RRD expression used to create the database for this data point. If you do not enter
a value, then the system uses a default applicable to most situations. For details about the <kbd>rrdcreate</kbd> command, go [here](http://oss.oetiker.ch/rrdtool/doc/rrdcreate.en.html).

- **RRD Minimum:** Enter a value. Any value received that is less than this number is ignored.

- **RRD Maximum:** Enter a value. Any value received that is greater than this number is ignored.

## Data Point Aliases

Performance reports pull information from various data points that represent a metric. The report itself knows which
data points it requires, and which modifications are needed, if any, to put the data in its proper units and format.

The addition of a data point requires changing the report.

![CPU Utilization Report](/posts/zenoss-monitoring-template-data-points/cpu_report.jpg)

To allow for more flexibility in changes, some reports use *data point aliases*. Data point aliases group data points so
they can be more easily used for reporting. In addition, if the data points return data in different units, then the plugin
can normalize that data into a common unit.

<!--more-->

An alias-based report looks up the data points that share a common alias string, and then uses them. This approach
allows you to add data points without changing the report.

![CPU Utilization Alias-Based Report](/posts/zenoss-monitoring-template-data-points/cpu_alias_report.jpg)

In the simplest cases, data from the target data points are returned in units expected by a report. For cases in which
data are not returned in the same units, an alias can use an associated formula at the data point. For example, if a data
point returns data in kilobytes, but the report expects data in bytes, then the formula multiplies the value by 1024.

### Alias Formula Evaluation

The system evaluates the alias formula in three passes.

#### Reverse Polish Notation

When complete, the alias formula must resolve to a Reverse Polish Notation (RPN) formula that can be used by
RRDtool. For the simple conversion of kilobytes into bytes, the formula is:

```
1024, *
```

For more information on RRDtool and RPN formulas, go [here](http://oss.oetiker.ch/rrdtool/doc/rrdgraph_rpn.en.html).

#### Using TALES Expressions in Alias Formulas

For cases in which contextual information is needed, the alias formula can contain a TALES expression that has access
to the device as context (labeled as "here"). The result of the TALES evaluation should be an RRD formula.

For example, if the desired value is the data point value divided by total memory, the formula is:

```
${here/hw/totalMemory},/
```

For more information on TALES, the [TALES Specification 1.3](http://wiki.zope.org/ZPT/TALESSpecification13).

#### Using Python in Alias Formulas

You also can embed full Python code in an alias formula for execution. The code must construct a string that results
in a valid RRD formula. To signal the system to evaluate the formula correctly, it must begin with:

```python
__EVAL:
```

Using the same example as in the previous section (division by total memory), the formula is:

```python
__EVAL:here.hw.totalMemory + ",/"
```