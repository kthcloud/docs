---
title: VM Template
---

# VM Template

This guide will show how kthcloud manages VM templates and ensures that
the templates are available in every zone.

We host every template separately from CloudStack, as CloudStack
integrate such a system better (cross-zone template synchronization by
URL). This is hosted as a Jail in [TrueNAS](/TrueNAS "wikilink") in the
Flemingsberg zone. It is exposed on IP <http://172.31.5.12> only
accessible internally (through a VPN).

You can also view and edit the template files as a NFS storage at
[kthcloud
Drive](https://drive.cloud.cbh.kth.se/files/cloudstack/templates).

## Customize the template

Start by customizing a VM that you want to use as a template. This
include installing the necessary packages, creating users etc.

Normally this is done by customizing the VM called "Ubuntu 22.04 Cloud
template".

Ensure the VM is Stopped when you are done.

If using "Ubuntu 22.04 Cloud template", make sure to run
"prepare-template.sh" before turning it off.

<img src="../../images/view_template_vm_volume.png" width="70%">

## Prepare the download

Navigate to VM that you want to template, and find the root disk.

Click "Download Volume". This will not actually download the volume, but
prepare it for download and then give you a link.

<img src="../../images/download_vm_template_volume.png" width="35%">

Copy the link.

<img src="../../images/vm_template_volume_download_link.png" width="35%">

## Download the template in the Template server

To ensure that all templates are synchronized in the zone, we host
templates separately from CloudStack, since CloudStack integrates such
as system better.

Login at <https://nas.cloud.cbh.kth.se> and navigate to "Jails" and
enter the shell for the jail called "templates".

Run `cd /opt/templates` then ` wget <cloudstack link> -O <template name>`

<img src="../../images/truenas_template_jail.png" width="85%">

## Add the template to CloudStack

Go to <https://dashboard.cloud.cbh.kth.se> and navigate to
"Images/Templates".

Click "Register template from URL" an enter the information (KVM, QCOW2
image). Use the IP 172.31.5.12 to reference the template server.

Ensure the template is synchronized to every Zone.

Once the template is registered, ensure it is downloaded in every Zone.

<img src="../../images/create_cloudstack_template_form.png" width="40%">
[600px](/File:Create-cloudstack-template-form.png "wikilink")