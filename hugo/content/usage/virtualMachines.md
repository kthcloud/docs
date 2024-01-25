---
title: "Resource: Virtual Machines"
---

# Create a virtual machine

Virtual machines are the most flexible resource type on kthcloud. They
are simply a virtual computer running the latest build of Ubuntu Server.
You can use them for anything you would do on a physical server, without
worrying about power outages, network issues and fan noise!

## Creating a VM

### Navigate to the platform

Go to [https://cloud.cbh.kth.se/deploy](https://cloud.cbh.kth.se/deploy) and login by pressing the button in the top right corner.

If you have any trouble with the login, follow [this guide](/usage/kthSso "wikilink") to troubleshoot KTH SSO.

### Create your VM

Once at the dashboard, create the VM using *+ Create*

#### Name

This name will be the name of your VM, both in our portal and inside the
actual VM. For example with name **galactus**, your bash prompt will be:
**root@galactus**.

#### SSH Key

If you do not have SSH keys yet, upload one on your profile. You can
create one using the command `ssh-keygen`. Check it out [here](https://www.ssh.com/academy/ssh/keygen).

Select your desired key, it will be copied into the VM at creation.

Use it to login to the VM (keys in locations outside the default
\~/.ssh/id_rsa can be used with the -i argument.

Once your VM is up and running, it is possible to add more keys manually
to allow access to other users. Add your new public keys as new lines in
the \~/.ssh/authorized_keys file.

#### Select specs

Specs are the capacity of your VM. You can select CPU cores, RAM and
disk size.

  - CPU cores represent the number of threads that can be run
    simultaneously. We recommend at least 2.
  - RAM is the memory available in your VM
  - Disk size is the size of the virtual internal disk in your VM.

Your account has a quota which can be used however you wish, either with
multiple small VMs or a single large one, this is up to you.

### That's it\!

If you have any questions, reach out on Discord :)

## Using the VM

### Attach a GPU

A list of GPU may be available depending on your account's tier. Select
**Lease GPU** and choose which card you want to attach. The card will be
available to you for a finite timespan. When it expires, the card will
remain attached to your VM, and usable, until someone else requests it.
In this phase, you can renew the lease if you wish to keep it for
another lease period.

Ending the lease prematurely is always possible using the **End lease**
button, and we hope you will return your GPU as soon as you are done
with it, so others can use it.

<img src="../../images/vm_gpu.png" width="100%">

#### Installing drivers

When attaching a GPU, you will need to install the appropriate drivers.

```bash
# Ensure the system is up to date
apt update && apt upgrade -y && apt autoremove -y
# You may need to reboot the vm at this point

# Install the drivers
apt install nvidia-driver-XXX-server nvidia-utils-XXX-server -y` 
# where XXX is the desired driver version, for example 535.
```

You can find the latest version at https://www.nvidia.com/en-us/drivers/unix/. Look for Linux x86_64/AMD64/EM64T, Latest Production Branch. 
For example version 535.146.02 can be installed as nvidia-driver-535-server and nvidia-utils-535-server.

After installation, you may need to reboot the vm, and then you can verify that the driver is installed using `nvidia-smi`. The output should look something like this:

```bash
root@raccoon:~# nvidia-smi
Thu Jan 11 14:25:22 2024       
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.129.03             Driver Version: 535.129.03   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  NVIDIA RTX A6000               Off | 00000000:00:06.0 Off |                  Off |
| 30%   47C    P0              73W / 300W |      2MiB / 49140MiB |      0%      Default |
|                                         |                      |                  N/A |
+-----------------------------------------+----------------------+----------------------+
```



#### Snapshots

Snapshots are a way to backup your VM before doing something risky. They
create a checkpoint that you can revert to at any time. Snapshots will
be created automatically sporadically, but we recommend creating them
manually from time to time.

#### Port forwarding

Port forwarding allows you to access the VM over some custom port. For
example, if you are running MongoDB on your VM, it will likely be
running on 27017 inside the VM.

To make this accessible externally, create a port forwarding rule with
the name of your choice, perhaps "MongoDB", the port 27017, and TCP
protocol. Once the rule is applied, you will receive the public port.
This is the port which you can use in MongoDB Compass or in your
connection string for other apps.

Instructions to access it will be provided, they might be different depending on which zone your VM is in.

<img src="../../images/vm_ports.png" width="100%">

#### HTTP Proxy
To access HTTP apps on your VM with a nice domain name, you can use the built in proxy feature of kthcloud.

Select the desired local port forwarding rule, and enter a name. Your app will then be available at the URL listed in the table.

<img src="../../images/vm_proxy.png" width="100%">

## FAQ

### I can't login to my VM, it says "premission denied (publickey)"

If you have created a ssh key in a location other than the default
(usually \~/.ssh/id_rsa), you'll need to specify it when accessing your
VM.

You can use the -i argument:

    ssh <user>@<host> -p <port> -i <filepath to your keyfile>

If this still does not work, ensure the key you have uploaded to your
profile is the public key, usually denoted by the **.pub** file
extension, like **id_rsa.pub**.