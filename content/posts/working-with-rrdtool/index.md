---
date: '2017-05-02'
tags:
- rrdtool
- monitoring
- sysadmin
title: Working With RRDTool
---

Zenoss makes a lot of use of [RRDTool](http://oss.oetiker.ch/rrdtool/) for [storing monitored performance data and generating graphs](/posts/using-rrdtool-in-zenoss.html). In this post I want to go into more detail on the components of RRDTool and how works.

## Round Robin Databases

RRDTool is a program that works with Round Robin databases (hence RRD). This type of database is more geared and limited towards storing **time series** data.

Moreover, rrdtool also **doesn't** store the data handed to it. Instead, it first **re-samples** the data and *then* stores this re-sampled data. Since rrdtool deals with time series data, it knows that certain data is meant to be stored every certain period of time (i.e 5 minutes). This newly re-sampled data will be the same as the original data, but the stored numbers will be different.

This means that if for example, we were to store some data every 5 minutes, a data sample that arrives at the `03` minute mark cannot go into the database, therefore it has to be re-adjusted into the correct slots. While rrdtool makes this adjustment, it will also change the value, so that this new value still represents the space in the curve.

In rrdtool, each database table is stored in a separate `.rrd` file. This means that one file represents one table.

We can create a database using the following command:

```
rrdtool create ex5.rrd --step=5 DS:input:GAUGE:10:0:1000000 RRA:LAST:0.5:1:603
```

### Data Re-sampling: Step

One important parameter here is the `step` parameter. This means that rrdtool will re-sample all the data that is fed into the database to a 300 second interval. Still, data can be fed as quickly as desired (i.e a lot of data in one second), however the data will be re-sampled to 300 seconds on storage. **This means that it only stores data every 300 seconds**. Because of this re-sampling, rrdtool will not accept data from the past.

<!--more-->

### Data Source

The next parameter after the step is the data source definition, which is composed of different parts.

The `DS:input` part indicates the data source, meaning *where* the data is obtained from. Data will always be time-series floating point data, but by defining the data source we can give rrdtool some information about the nature of the data. So whenever we refer to that column, we can refer to it using that name (in this case `input`).

In the next part, we are indicating that the data is of type `GAUGE`. Gauge basically means that each data point collected in time does not depend on the other (i.e it doesn't matter what the value of the last data point collected was), a piece of information that stands on its own.

Next, we can tell rrdtool how often we insist on updating this data source (known as the **heartbeat**), in this case `10` seconds. This means that data will **only** be accepted if it arrives within **10 seconds** of the last update. If data fails to arrive within this time, rrdtool will store an `Unknown` value for this time range.

In the last part of the data source we define some lower and upper bounds for the data, `0:1000000`. This will make rrdtool check that the incoming data point value is between these bounds. If it's not, rrdtool will store `Unknown`.

### Data Storage: Round Robin Archives

One important feature of the Round Robin database is that it does not store sequentially, rather it sets up a file as you create the database, and that file already has enough space to store all the data you would want to store in that database. This space for storing the data is called the **Round Robin Archive (RRA)**, and a database can actually have several of these archives.

Round Robin archives have a special property of jumping back to the beginning when they reach the end. This means that after returning to the beginning, all the data will be overwritten.

In the database creation example above, we created a new RRA using `RRA:LAST:0.5:1:603`. Let's go over each of the parts belonging to this input:

TODO

The first part represents the consodilation function to use for this archive, in this case `AVERAGE`. Other available functions are `MIN`, `MAX`, and `LAST`. When data is entered into an RRD, it is first fit into time slots of the length defined with the `--step` option, thus becoming a *primary data point*. The data is also processed with the consolidation function of the archive.

#### RRA Structure

A RRA contains two parts of information. The first part is called the **preparation area**, and it stores information prior to actually updating the RRA. In the preparation area, data is fed, stored and prepared, and once ready, one item is transferred to the long term storage.

-> Round Robin archives basically live on their own, and do not depend on any data from the other RRAs. It has its own preparation area where data is being stored and prepared, and once ready, it is transferred into the long term storage area.

This is an example of how an RRA's structure looks like along with the preparation area (`cdp_prep`) in XML format:

```xml
<rra>
  <cf>AVERAGE</cf>
  <pdp_per_row>1</pdp_per_row> <!-- 300 seconds -->

  <params>
  <xff>5.0000000000e-01</xff>
  </params>
  <cdp_prep>
          <ds>
          <primary_value>0.0000000000e+00</primary_value>
          <secondary_value>0.0000000000e+00</secondary_value>
          <value>NaN</value>
          <unknown_datapoints>0</unknown_datapoints>
          </ds>
  </cdp_prep>
</rra>
```

If we had a RRA that stores averaged data once a day, how are the averages created before they are put into the RRA? The answer is that they are actually created in the preparation area. The data in the preparation area is getting built up to the time when the archive should be updated.

Within the `.rrd` file, the location of where all the data preparation happens is within the **Live Head**, shown in green in the image below.

![RRD File Structure](/posts/working-with-rrdtool/rrd_structure.jpg)

This means that as we are updating the database, only this green section of the database needs to be touched. The orange part could be holding possibly one year or even ten years of stored data. This area is not even accessed until data has to be written in the archive.

Likewise, we can take a look at the structure in XML format of the RRA's orange area (long term storage):

```xml
<rra>
  <!-- ... -->

  <database>
    <!-- 2017-04-24 08:00:00 CST / 1492992000 --> <row><v>2.5000000000e+01</v></row>
    <!-- 2017-04-25 08:00:00 CST / 1493078400 --> <row><v>2.5000000000e+01</v></row>
    <!-- 2017-04-26 08:00:00 CST / 1493164800 --> <row><v>2.5000000000e+01</v></row>
    <!-- 2017-04-27 08:00:00 CST / 1493251200 --> <row><v>2.6000000000e+01</v></row>
    <!-- 2017-04-28 08:00:00 CST / 1493337600 --> <row><v>2.5000000000e+01</v></row>
    <!-- 2017-04-29 08:00:00 CST / 1493424000 --> <row><v>2.5000000000e+01</v></row>
    <!-- 2017-04-30 08:00:00 CST / 1493510400 --> <row><v>2.5000000000e+01</v></row>
    <!-- 2017-05-01 08:00:00 CST / 1493596800 --> <row><v>2.5000000000e+01</v></row>
    <!-- 2017-05-02 08:00:00 CST / 1493683200 --> <row><v>2.5000000000e+01</v></row>
  </database>
</rra>
```

## Writing Data

Data can be easily written into the database with the following command:

```
rrdtool update <file.rrd> <timestamp>:<value>
```

The timestamp is a UNIX timestamp and can either be defined in seconds since 1970-01-01 or by using the letter 'N', in which case the update time is set to be the current time.

~> The point in time when the data acquisition was made is very important. RRDTool will use it to re-sample the data into its rigid step inverval blocks. If no information of when the data is acquired is given to rrdtool, there will be jitter, as the data is shifted a bit. This is due to processing happening between the point in time where the data is acquired and when it is actually fed to rrdtool.

Whenever you update the RRD database rrdtool will store the point in time when you updated the database into a `lastupdate` field, so that when the database is updated again, it can use that information to calculate the time difference between the two updates

## References

1. [OUCE-2013 RRDtool Tutorial -- Part One](https://www.youtube.com/watch?v=JaK-IctEyWs)