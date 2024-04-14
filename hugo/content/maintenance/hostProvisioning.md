# Host Provisioning
The workflow to provision a new host is mostly automated using
PXE-booting using [MaaS](https://maas.io/) together with [cloud
init](https://cloudinit.readthedocs.io/en/latest/). But there are some
steps that are manual.

This guide is designed for the new sys-cluster/deploy-cluster setup with KubeVirt. If you are setting up a CloudStack host, please refer to the [old guide](archive/hostProvisioning_old.md).

## Installation

This guide will go through the entire workflow to setup up a brand new
host. 

### Prerequisites
  - Access to the GitHub Admin repository
  - Hostname (e.g. `se-flem-001`)
  - FQDN (e.g. `se-flem-001.cloud.cbh.kth.se`)
  - Password
  - Host and IPMI IP-address (see [Configuration](administration/configuration))
  - MaaS Zone (see [Configuration](administration/configuration))
  - Cluster type (`sys-cluster` or `deploy-cluster`)

### Steps
1.  Configure BIOS and find MAC-address
    1.  Turn on the machine and enter BIOS
    2.  Go to the network cards in the BIOS to find the network card that is used.
    3.  Note the MAC-address (take a photo\!)
    4.  Go to the Boot order and set the connected network card to be first in the list
    5.  Go to the IPMI settings and set the IPMI IP-address (see [Configuration](administration/configuration))\
        Do **NOT** edit the username and password! These should remain default for all machines.
    6.  Turn off the machine
2.  Generate a cloud-init file
    1.  Go to the admin GitHub repository
    2.  Go to `cloud-init/k8s`
    3.  Run `./generate.sh` and follow the instructions in the terminal
3.  Register the machine in MaaS
    1.  Go to [MAAS](https://maas.cloud.cbh.kth.se)
    2.  Go to Machines | Add hadware | Machine
    3.  Enter `Machine name` and `Zone`
    4.  Enter `MAC address` from BIOS
    5.  Select `Power type` to IPMI and enter the `IP address`, `Power user` and `Power password` (see [Configuration](administration/configuration))
    6.  Click `Save machine`\
        The machine will be started by IPMI and will PXE-boot into commissioning
5.  Deploy the machine
    1.  Ensure the machine is in `Ready` state
    2.  Go to the machine in MaaS
    3.  Go to the `Network Tab`
    4.  Find the connected NIC and in the drop-down menu click `Edit Phyiscal`
    5.  Select `Fabric` for the zone, eg. `se-flem`
    6.  Select `Subnet` for the zone, eg. `172.31.0.0/16`
    7.  Select `Static assign` in `IP mode`
    8.  Enter the static IP address of the host in `IP address`
    9.  Click `Save interface`
    10. Click `Take action` and `Deploy` and tick `Cloud-int user-data`
    12. Upload or paste the cloud-init file generated in **step 2**
    13. Click `Start deployment for machine`
    15. Wait for machine to be under the category `Deployed`

### Next steps
If you did not deploy the first node in a cluster, you don't need to do anything more.

If you deployed the first node in a cluster you should follow the guide for [Installing a Kubernetes cluster](maintenance/installKubernetesCluster).