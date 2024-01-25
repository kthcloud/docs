This guide will explain how a virtual machine can be deployed in
kthcloud.

<span id="upload-iso"></span>

## Upload ISO

If your installation requires a different ISO to the ones provided in
kthcloud (Ubuntu 20.04, Ubuntu 22.04), one can be uploaded with the
following steps. Otherwise, skip to the next part.

1.  Go to Images

[image](/File:Upload-iso.png "wikilink")

1.  Go to ISOs

[image](/File:Upload-iso-2.png "wikilink")

1.  Open Register ISO

[image](/File:Upload-iso-3.png "wikilink")

1.  Register ISO with appropriate parameters. Cloudstack will download
    the ISO and make it available to users.

<span id="create-network"></span>

## Create Network

If you already have a network that you intend to use with this VM,
please skip this step. Otherwise:

1.  Go to Network

[image](/File:Network.png "wikilink")

1.  Go to Guest Network

[image](/File:Network-2.png "wikilink")

1.  Select Add network

[image](/File:Network-3.png "wikilink")

1.  Fill in fields:
2.  Name
3.  Description
4.  Zone
5.  Network offering (select Offering for isolated networks with source
    nat service enabled)

The other fields will be set to kthcloud defaults which should work in
most configurations.

<span id="create-vm"></span>

## Create VM

<span id="go-to-compute"></span>

### 1\. Go to Compute

[image](/File:Compute.png "wikilink")

<span id="go-to-instances"></span>

### 2\. Go to Instances

[image](/File:Compute-2.png "wikilink")

<span id="go-to-add-instance"></span>

### 3\. Go to Add instance

[image](/File:Compute-3.png "wikilink")

<span id="create-vm-1"></span>

### 4\. Create VM

This page will guide you through the process of filling in the various
parameters for VM creation.

<span id="select-deployment-infrastructure"></span>

#### 4.1 Select deployment infrastructure

Select the appropriate zone for your deployment (Most likely
Flemingsberg). For most VMs, the pod, cluster and host fields can be
left empty.

<span id="templateiso"></span>

#### 4.2 Template/ISO

Go to ISOs, Select your iso

NB\! Hypervisor must be chosen. For now this is always KVM.

[image](/File:Vm.png "wikilink")

<span id="compute-offering"></span>

#### 4.3 Compute offering

Select the compute offering that best suits your needs.

If none fit, an admin account can be used to create a new one. In that
case, visit the Service offering \> Compute offering tab. Otherwise:

[image](/File:Vm-2.png "wikilink")

HA denotes offerings with High Availability, meaning that the VM will be
moved to another host if failure is detected. This also enables VMs to
be auto restarted in the event of a power outage.

<span id="disk-size"></span>

#### 4.4 Disk size

Select the offering that suits your needs, but do not allocated too much
disk space as the total amount is currently quite limited on kthcloud.

<span id="networks"></span>

#### 4.5 Networks

The network you created earlier can be chosen in this step. It is
easiest to only configure one NIC.

<span id="finalizing"></span>

#### Finalizing

The SSH keypair, advanced settings, Group, keyboard language can be
skipped. Name your machine and then click Launch Instance.

[image](/File:Vm-3.png "wikilink")

<span id="use-vm"></span>

## Use VM

To use the VM, the simplest way is through the built-in noVNC client.

SSH can be configured on the VM through the noVNC client, and then port
forwarded in the firewall, as well as in the isolated network. It is
however easier to use the VM through the noVNC client.

To enter the client:

1.  Visit dashboard.cloud.cbh.kth.se.
2.  Go to Compute

[image](/File:Use.png "wikilink")

1.  Go to Instances

[image](/File:Use-2.png "wikilink")

1.  Choose your VM

[image](/File:Use-3.png "wikilink")

1.  Select View console

[image](/File:Use-4.png "wikilink")

You will now be presented with the VM's virtual display

[image](/File:Use-5.png "wikilink")

This allows you to use the VM a a normal computer. The toolbar to the
left provides additional functionality, like hotkeys and clipboard.

[image](/File:Use-6.png "wikilink")

[image](/File:Use-7.png "wikilink")

<span id="protips"></span>

## Protips

  - All of this configuration can be done through the CMK cli.
  - The public IP of your network can be found under Networks \> {Your
    network} \> Public IP addresses. This can be port forwarded to for
    access using the port forwarding built in to your isolated network.
  - GPU capability can be configured using the latter part of the
    [Configure GPU
    passthrough](https://github.com/pierrelefevre/kthcloud/wiki/Configure-GPU-passthrough#start-gpu-vm-in-cloudstack)
    tutorial. Remember that the VM then needs to be started on a GPU
    enabled VM which is currently not being used with GPU passthrough.

<span></span>