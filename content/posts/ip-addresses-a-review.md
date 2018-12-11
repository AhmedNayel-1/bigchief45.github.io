---
date: '2016-12-02'
tags:
- networking
- ip
title: IP Addresses - A Review
---

*A review of IP addresses, as part of my Computer Networking Fundamentals series.*

A lot of people know what IP addresses are, and a lot of people also probably know that each device that is connected to the Internet must have a **_unique_** IP Address, like *108.161.228.70*

However, in this article I want to do a more in-depth review about IP addresses and how the work.

From a technical point of view and for reviewing purposes, it is worth remembering that IP Addresses (at least IPv4) are **32-bit** addresses, because each number separated by each dot (called *octet*) is an 8-bit number. Since IP Addresses have 4 octets, these together make a sum of 32-bits.

<p class="lead">Another very important detail of IP Addresses is that the <strong>first two</strong> octets represent a <strong>destination network</strong>, while the <strong>last two</strong> octets represent a <strong>destination host</strong> within that destination network.</p>

Since the first two octets make a sum of 16 bits, 2^16 yields a total of 65,536 networks. At the same time, the remaining 16 bits also yield a total of 65,536 different hosts. **_But_** these are 65,536 different hosts **_per each_** network.

This raises a big issue because it makes it hard to decide how many bits in the IP address should be allocated to the network and how many bits should be allocated for the hosts, without wasting IP addresses. This is where **subnet masks** come in.

<!--more-->

### Subnet Masks

A solution was proposed and along came **subnet masks**. A subnet mask is simply another 32-bit address in binary, but it's purpose is to represent which network and which host is being delt with. The 1 bits represent the network, while the 0 bits represent the host.

This approach allows dynamic size of networks (based on # of hosts) without exceeding that 32-bit limit.

#### Obtaining a Network's IP Address

To obtain the IP Address of the current network a device is in, we can simply compare each bit between the IP address and the subnet mask:

1. When **both** bits equal 1, the network's address for that bit is going to be 1.
2. When one of the bits is 0 (doesn't matter which), the network's address for that bit will be 0.

For example, take a look at the following IP address and subnet mask:

```
IP Address:   169 . 174 . 141 . 10
Subnet Mask:  255 . 255 . 255 . 240
```

Converted to binary:

```
IP Address:   10101001  10101110  10001101  00001010
Subnet Mask:  11111111  11111111  11111111  11110000
```

Implementing the method mentioned above, we obtain the following result:

```
IP Address:   10101001  10101110  10001101  00001010
Subnet Mask:  11111111  11111111  11111111  11110000

Network IP:   10101001  10101110  10001101  00000000
```

We can then convert the binary into human-readable format:

```
Network IP: 169 . 174 . 141 . 0
```

#### Finding the # of Hosts

Since we know that the 0 bits in the subnet mask refer to the number of hosts (in the case above, 4 bits), that means that the **total** number of hosts in the network above is 2^4 = 16 hosts.

However, since we need to reserve one IP address for the **network IP address** and one IP address for the **broadcast IP address**. This leaves us with a total number of 14 **usable hosts** or IP Addresses. These can be assigned to any device such as computers, printers, and mobile phones:

```
Network IP:   169 . 174 . 141 . 0
Host #1:      169 . 174 . 141 . 1
...
...
...
...
Host #14:     169 . 174 . 141 . 15
Broadcast IP: 169 . 174 . 141 . 16
```

#### CIDR Notation

Another very common IP Address notation is an IP Address combined with a subnet mask. For example:

```
10.68.90.3/20
```

This is called [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing#CIDR_notation) and it's basically just a shorthand version of writing the subnet mask. This number (`/20` in the example above) means that the subnet mask will have 20 bits with value `1`, and the rest of the bits have a value of `0`.

#### Broadcast Address

The broadcast address is the address where all the devices connected to the network can receive a **[datagram](https://en.wikipedia.org/wiki/Datagram)**. The messages sent to the broadcast address is received by **all** the hosts attached in the network. Network administrators verify successful data packet transmission via broadcast addresses.

Broadcast addresses are usually set up by the operating system once the IP address and subnet mask is entered.

~> Windows systems do not allow users to change the broadcast address by hand.

IP broadcasts are also used by BOOTP and DHCP clients to find and send requests to their respective servers.