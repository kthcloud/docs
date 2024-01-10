---
title: MAAS
---

[200px](/File:Maas-logo.png "wikilink")

MAAS is used for server provisioning servers over PXE. It serves as the
closest-to-hardware management tool in kthcloud. It also provides an
hardware overview of all the servers in kthcloud.

## Access

MAAS is used by system admins and a special account is needed to access
it.

The dashboard is available at <https://maas.cloud.cbh.kth.se>.

## Setup

The master instance of MAAS is setup using Snap on se-flem-001 in the
Flemingsberg zone. It is a monolithic setup where the instance acts as
both a Region controller and Rack controller. Slave setups in other
zones, such as Kista are only Rack controllers.

[This guide](https://maas.io/docs/fresh-installation-of-maas) was used
to setup MAAS.

## Administration

**Edit**: Edit using the [dashboard](https://maas.cloud.cbh.kth.se).

**Restart**: Run `sudo snap restart maas.supervisor`

**Update**: Follow [this guide](https://maas.io/docs/upgrading-maas)

## Persistent storage

MAAS uses a PostgreSQL database that is hosted on se-flem-001 in the
Flemingsberg zone.