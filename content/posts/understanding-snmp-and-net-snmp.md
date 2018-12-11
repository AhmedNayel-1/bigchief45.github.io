---
date: '2017-01-16'
tags:
- snmp
- monitoring
- sysadmin
title: Understanding SNMP and Net-SNMP
---

[Net-SNMP](http://net-snmp.sourceforge.net/) is a suite of tools used to implement SNMP (Simple Network Management Protocol). SNMP is a widely used protocol for monitoring the health and welfare of network equipment (eg. routers), computer equipment and even devices like UPSs. Net-SNMP includes tools with capabilities such as:

- An extensible agent
- An SNMP library
- Tools to request or set information from SNMP agents
- Tools to generate and handle SNMP traps
- A version of the unix 'netstat' command using SNMP
- A graphical Perl/Tk/SNMP based mib browser

## How SNMP Works

SNMP allows a management station to treat its network as a distributed database of health and configuration information. SNMP contains a small set of operations:

- GET: Retrieve data from a network node
- GETNEXT: Retrieve the next element from a network node
- SET: Send configuration or control commands to a network node
- TRAP: A network node can send a notification to the management station
- INFORM: An acknowledged trap (network nodes can try and send it again if no acknowledgement is received)

![SNMP Architecture](http://computernetworkingsimplified.com/wp-content/uploads/2014/02/snmparchitecture1.jpg)

<!--more-->

## SNMP Agents and snmpd

SNMP agents are responsible for delivering requested data through SNMP. Devices that are being polled for SNMP data must have a SNMP agent installed, configured, and running.

Net-SNMP comes with a daemon called *snmpd* which works as an SNMP agent. This agent is responsible for listening and responding to requests. Its configuration can be found in `/etc/snmp/snmpd.conf`.

## Understanding OIDs and MIBs

MIBs stand for **Management Information Base**. They represent a collection of information that is accessed hierarchically by protocols such as SNMP. **Scalar** MIBs define a single object instance. **Tabular** MIBs define multiple related object instances grouped in MIB tables.

OIDs stand for **Object Identifiers** and they uniquely identified managed objects in a MIB hierarchy. They can be depicted as trees whose nodes are assigned by different organizations. Generally, an OID is a long sequence of numbers, coding the nodes, separated by dots. Top level MIB object IDs (OIDs) belong to different standard organizations. Vendors define private branches including managed objects for their own products.

Basically a MIB is like a translator that helps a Management Station to understand SNMP responses obtained from your network devices

![OID Tree](http://www.networkmanagementsoftware.com/wp-content/uploads/SNMP_OID_MIB_Tree.png)

## References

1. [How SNMP, MIBs and OIDs work](https://kb.paessler.com/en/topic/653-how-do-snmp-mibs-and-oids-work)
2. [http://www.networkmanagementsoftware.com/snmp-tutorial-part-2-rounding-out-the-basics/](http://www.networkmanagementsoftware.com/snmp-tutorial-part-2-rounding-out-the-basics/)
3. [Net-SNMP Tutorials](http://net-snmp.sourceforge.net/wiki/index.php/Tutorials)