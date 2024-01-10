[200px](/File:Powerdns-logo.png "wikilink")

A PowerDNS instance is used as an external DNS-server in kthcloud. It is
meant to resolve hostnames to external IP addresses (internally names
are resolved using the Firewall as DNS).

## Access

PowerDNS is used by system admins and a special account is needed to
access it.

The admin dashboard is available at <https://dns.cloud.cbh.kth.se>.

The PowerDNS instance is available over ssh using `ssh
cloud 172.31.1.69`

## Setup

PowerDNS is hosted on a virtual machine in CloudStack. It was installed
using [this guide](https://phoenixnap.com/kb/powerdns-ubuntu)

PowerDNS admin dashboard is a GUI that is hosted in the system cluster
in the Flemingsberg zone.

## Administration

**Edit**: Edit the configuration files in the virtual machine.

**Restart**: Run `systemctl restart powerdns`

**Update**: Run `apt upgrade`

## Persistent storage

PowerDNS uses a MariaDB inside the virtual machine.