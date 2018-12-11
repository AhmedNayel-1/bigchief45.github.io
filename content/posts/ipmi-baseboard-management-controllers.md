---
date: '2016-11-18'
tags:
- sysadmin
- monitoring
- linux
- hardware
- ipmi
- ipmitool
- bmc
title: IPMI & Baseboard Management Controllers
---

An **Intelligent Platform Management Interface (IPMI)** is a set of interfaces that allow system administrators to manage and monitor systems, independently of the system's CPU, BIOS, and operating system.

IPMI can also help manage computers that are unresponsive or powered off, by using a network connection to the **hardware**, rather than to a operating system or login shell.

More specifically, IPMI can help us monitor, obtain data, and perform tasks such as:

- System temperature
- Voltages
- Fans
- Power supplies
- Chassis intrusion
- Perform recovery procedures
- System rebooting
- System powering

An IPMI sub-system consists of a main controller, called the baseboard management controller (BMC) and other management controllers distributed among different system modules that are referred to as *satellite controllers*. The satellite controllers within the same chassis connect to the BMC via another system interface (not covered in this post) called Intelligent Platform Management Bus/Bridge (IPMB)

<!--more-->

![IPMI Sub-System](https://upload.wikimedia.org/wikipedia/commons/f/f2/IPMI-Block-Diagram.png)


## The Baseboard Management Controller

An IPMI sub-system consists of a main controller, called the **baseboard management controller (BMC)** and other management controllers distributed among different system modules that are referred to as satellite controllers.

The BMC is actually a microcontroller that is embedded on the **motherboard** of a computer (usually a server). The BMC manages the interface between system-management software and the hardware.

![BMC](http://www.servethehome.com/wp-content/uploads/2010/11/Nuvotion-BMC.jpg)

## Querying the BMC With ipmitool

It is possible to use a tool called [ipmitool](http://freecode.com/projects/ipmitool) to query the BMC for some data (like the one listed above).

For example:

```
ipmitool -I lanplus -H $BMC_IP -U $USERNAME -P $PASSWORD sdr'
```

Where `$BMC_IP` stands for the BMC server's IP Address, `$USERNAME` stands for the server's username, and `$PASSWORD` stands for the server's password for the entered username.

If ipmitool can successfully connect and query to the server, it can print out a lot of information such as:

```
MLB Inlet TEMP   | 28 degrees C      | ok
PCH Local TEMP   | 56 degrees C      | ok
MLB Outlet TEMP1 | 45 degrees C      | ok
MLB Outlet TEMP2 | 46 degrees C      | ok
CPU 1 Temp       | 47 degrees C      | ok
CPU 2 Temp       | 49 degrees C      | ok
CPU1 PECI ABS    | 44 degrees C      | ok
CPU2 PECI ABS    | 42 degrees C      | ok
VCORE1           | 0.84 Volts        | ok
VCORE2           | 0.83 Volts        | ok
CPU1 AB DDR      | 1.36 Volts        | ok
CPU1 CD DDR      | 1.37 Volts        | ok
CPU2 AB DDR      | 1.36 Volts        | ok
CPU2 CD DDR      | 1.36 Volts        | ok
STBY 3.3V        | 3.39 Volts        | ok
STBY 5V          | 5.07 Volts        | ok
PS 12V           | 12.16 Volts       | ok
PS 1.1V          | 1.13 Volts        | ok
SYS FAN1         | 5643 RPM          | ok
SYS FAN2         | 5643 RPM          | ok
SYS FAN3         | 5643 RPM          | ok
SYS FAN4         | 5643 RPM          | ok
SYS Inlet TEMP   | 23 degrees C      | ok
CPU1 Status      | 0x00              | ok
CPU2 Status      | 0x00              | ok
PEF Action       | 0x00              | ok
Watchdog2        | 0x00              | ok
PCI BUS          | 0x00              | ok
Memory           | 0x00              | ok
SEL Fullness     | 0x00              | ok
ACPI Pwr State   | 0x00              | ok
Single MLB PWR   | 39.90 Watts       | ok
System PWR       | 42 Watts          | ok
Chassis PWR      | 356.70 Watts      | ok
PSU1 Status      | 0x00              | ok
PSU2 Status      | 0x00              | ok
PSU Redundancy   | 0x00              | ok
PSU1_AC_STATUS   | 0x00              | ok
PSU1_DC_STATUS   | 0x00              | ok
PSU2_AC_STATUS   | 0x00              | ok
PSU2_DC_STATUS   | 0x00              | ok
PSU1_In_Power    | 185.50 Watts      | ok
PSU2_In_Power    | 169.60 Watts      | ok
PSU1_Out_Power   | 169.60 Watts      | ok
PSU2_Out_Power   | 164.30 Watts      | ok
PSU1_Out_Vol     | 12 Volts          | ok
PSU2_Out_Vol     | 12.10 Volts       | ok
PSU1_In_Temp     | 40 degrees C      | ok
PSU2_In_Temp     | 41 degrees C      | ok
PSU1_In_Vol      | 220 Volts         | ok
PSU2_In_Vol      | 220 Volts         | ok
```

With that output, we can then individually select which fields of data we actually need by using combinations of Linux commands such as `grep` and `awk`.