---
title: CloudStack
---

[200px](/File:Cloudstack-logo.png "wikilink")

CloudStack is used as the base for VM provisioning and Kubernetes
cluster creation.

## Access

CloudStack is used by system admins and a special account is needed to
access it.

The dashboard is available at <https://dashboard.cloud.cbh.kth.se>.

## Administration

**Edit**: Edit config files in `/etc/cloudstack` and the restart

**Update**: `apt upgrade` on se-flem-001 in the Flemingsberg zone.

**Restart**: `systemctl restart cloudstack-management`

## Setup

The setup in kthcloud followed [this
guide](https://rohityadav.cloud/blog/cloudstack-kvm/) by Rohit Yadav.
Any questions around configuration should be answered there.

## Persistent storage

CloudStack uses a MySQL database that is hosted on se-flem-001 in the
Flemingsberg zone.