# Host Provisioning (Archived 2024-04-14)

**THIS IS AN OLD GUIDE. PLEASE REFER TO THE NEW GUIDE [HERE](hostProvisioning.md)**

The workflow to provision a new host is mostly automated using
PXE-booting using [MaaS](https://maas.io/) together with [cloud
init](https://cloudinit.readthedocs.io/en/latest/). But there are some
steps that are manual.

## Installation

This guide will go through the entire workflow to setup up a brand new
host. Keep in mind that credentials to each subsystem used in the guide
are assumed to be available.

  - Prerequisites

<!-- end list -->

  - Access to the GitHub Admin repository
  - Name and FQDN
  - Password
  - Static IP-address
  - MaaS Zone (Check the available zones in
    [MaaS](https://maas.cloud.cbh.kth.se))
  - CloudStack Zone (Check the available zones in
    [CloudStack](https://dashboard.cloud.cbh.kth.se), this should match
    with the MaaS Zone)
  - CloudStack Pod (Check the available pods in
    [CloudStack](https://dashboard.cloud.cbh.kth.se))
  - CloudStack Cluster (Clusters are hardware homogeneous, create a new
    one if there isn't a match in
    [CloudStack](https://dashboard.cloud.cbh.kth.se/))

### Steps

1.  Configure BIOS and find MAC-address
    1.  Turn on the machine and enter BIOS
    2.  Go to the network cards in the BIOS to find the network card
        that is used.
    3.  Note the MAC-address (take a photo\!)
    4.  Go to the Boot-order
    5.  Set the connected network card to be first in the list
    6.  Turn off the machine
2.  Generate a cloud-init file
    1.  Go to the admin GitHub repository
    2.  Go to cloud-init folder
    3.  Run `generate.py` and follow the instructions in the terminal
3.  Register the machine in MaaS
    1.  Go to [MAAS](https://maas.cloud.cbh.kth.se)
    2.  Go to Machines | Add hadware | Machine
    3.  Enter *Machine name* and *Zone*
    4.  Enter *MAC address* from BIOS
    5.  Select *Power type* to Manual (this will be edited in the
        future)
    6.  Click *Save machine*
    7.  Refresh the page and ensure that the machine is under the
        category *New*
    8.  (The following steps are necessary until IPMI is fixed)
    9.  Go to the machine in MaaS
    10. Click 'Take action' and 'Abort' the commissioning
    11. Click 'Take action' and 'Commission' again, **but with "Skip
        configuring supported BMC controllers..."** ticked
    12. Click 'Start commissioning for machine'
4.  Commission the machine
    1.  Turn on the machine
    2.  Wait for it to boot and ensure that it picks up the boot image
        from MaaS
    3.  Wait for the machine to turn it self off
5.  Deploy the machine
    1.  Ensure the machine is turned off
    2.  Go to the machine in MaaS
    3.  Go to the 'Network Tab'
    4.  Tick the connected network card and Click 'Create bridge'
    5.  Enter 'cloudbr0' in 'Bridge name'
    6.  Select 'Subnet' for the zone, eg. 172.31.0.0/16
    7.  Select 'Static assign' in 'IP mode'
    8.  Enter the statis IP address of the host in 'IP address'
    9.  Click 'Save interface'
    10. Click 'Take action' and 'Deploy'
    11. Select the 'Release' and tick 'Cloud-int user-data'
    12. Upload or paste the generated cloud-init file
    13. Click 'Start deployment for machine'
    14. Turn on the machine and wait for MaaS to finish the deployment
    15. Refresh and wait for machine to be under the category *Deployed*
6.  Verify installation
    1.  Go to the [dashboard](https://dashboard.cloud.cbh.kth.se)
    2.  Go to Infrastructure | Hosts
    3.  Verify that the new machine is present. NOTE\! It might take
        some time for it to appear in CloudStack as the machine will
        reboot a couple of times more before it is completely ready
    4.  Go to the [status page](https://cloud.cbh.kth.se/status)
    5.  Ensure the host status is visible under *Server statistics*
