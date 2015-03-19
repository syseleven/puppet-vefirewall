# vefirewall

Setting up a firewall for sys11 hosts.

This module consists of the two parts ```vefirewall``` and ```vefirewall::ipv6```.
While ```vefirewall``` sets up the default IPv4 firewall, ```vefirewall::ipv6``` does the same for IPv6. Although ```vefirewall``` and ```vefirewall::ipv6``` can be used separately, they share some code.

You can use both modules separately, but you definitely should **not** (see Known Issues). If you are using up ```vefirewall``` *only* IPv4-firewall will be set up. If you using ```vefirewall::ipv6``` *only* IPv6-firewall will be set up. However, you can use both at the same time.

## IPv4

```vefirewall``` currently ships an init-file ```/etc/init.d/firewall```. This init-scripts is registered for boot up, and sets up the firewall.

Stopping the firewall:
```
/etc/init.d/firewall stop
```
Calling ```iptables-save``` to persist the rules into a file.
Resetting all policies to ```ACCEPT``` and flushing all tables.

Starting the firewall:
```
/etc/init.d/firewall start
```
Calling ```iptables-restore``` using the save file.
Resetting all policies to ```ACCEPT``` and flushing all tables.


### Examples

Using ```vefirewall``` in an enc-db yaml file:
```
  vefirewall:
    host_trusted_services:
      - 10.3.20.40,tcp,10050
      - 109.68.230.4,tcp,5666
      - 77.247.83.0/26,tcp,443
```

## IPv6

```vefirewall::ipv6``` currently ships an init-file ```/etc/init.d/firewall6```. This init-scripts is registered for boot up, and sets up the firewall.

Stopping the firewall:
```
/etc/init.d/firewall6 stop
```
Calling ```ip6tables-save``` to persist the rules into a file.
Resetting all policies to ```ACCEPT``` and flushing all tables.

Starting the firewall:
```
/etc/init.d/firewall6 start
```
Calling ```ip6tables-restore``` using the save file.
Resetting all policies to ```ACCEPT``` and flushing all tables.


### Examples

Using ```vefirewall::ipv6``` in an enc-db yaml file:
```
  vefirewall::ipv6:
    host_trusted_services:
      - 2a00:13c8:2000:16::/64,tcp,443
      - 2a00:13c8:4000:3:2:128:0:1,tcp,22
```

## IPv4 and IPv6 in a single yaml

Using both in the same enc-db yaml file:
```
  vefirewall:
    host_trusted_services:
      - 10.3.20.40,tcp,10050
      - 109.68.230.4,tcp,5666
      - 77.247.83.0/26,tcp,443
  vefirewall::ipv6:
    host_trusted_services:
      - 2a00:13c8:2000:16::/64,tcp,443
      - 2a00:13c8:4000:3:2:128:0:1,tcp,22
```

## Supported OS

 * Gentoo
 * Ubuntu
 * Debian

## Known issues

* If you use one of IPv4 or IPv6 custom rules in the other part are deleted, due to purging.
* No CentOS support so far
* No support for systemd

### Why puppetlabs-firewall is kind of broken

There is only **one** type ```firewall```, used for both IPv4 and IPv6, by switching the ```provider``` to ```iptables``` or ```ip6tables```. Beacuse of this fact, the provider currently only suport purging on ```iptables```.

Example:

You want to manage your ```ip6tables``` via puppet, but not your ```iptables```. However, you may configure something like this:
```
resources { 'firewall':
  purge => true,
}

firewall { 'my fancy rule':
  provider => 'ip6tables',
  ...
}
```

As a result of this code, all your IPv4-Rules are purged.

## Troubleshooting

```vefirewall::ipv6``` may fail on Gentoo-machines if ```iptables``` is compiled without IPv6-Support. You have to fix this by hand.

## Migrations

There are two cases of migration so far.

### Moving a VE from a HN with Kernel < 2.6.19 to a HN with Kernel >= 2.6.19

If you run ```puppet``` in the migrated VE, all rules containing ```state``` are replaced by rules using ```ctstate```.

You may want to use ```force_migration: true``` in the node yaml of the VE you want to migrate.

This causes ```vefirewall``` and ```vefirewall::ipv6``` to reset the ```INPUT```- and ```OUTPUT```-policy to ```ACCEPT``` and flush all tables **before** doing anything else.

### Because of development in ```vefirewall```

In some cases, you (as the developer) may throw away the one ```INPUT```-rule, that allows incomming traffic for outgoing connections. This may cause ```puppet``` to hang.

In this case, you have to increase ```vefirewall::params::version``` or ```vefirewall::params::version6```, depending on the change you made.

This causes ```vefirewall``` and ```vefirewall::ipv6``` to reset the ```INPUT```- and ```OUTPUT```-policy to ```ACCEPT``` **before** doing anything else.
