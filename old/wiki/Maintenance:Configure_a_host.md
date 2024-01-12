    Host device minimum recommended hardware requirements

    RAM: 16 GB
    CPU: 4 cores

Configuring a new host is mostly automated using the provided Ansible
scripts.

kthcloud uses an SSH jump host, so any IP specified for the hosts is a
local IP.

<span id="local-machine"></span>

## Local machine

<span id="install-ansible"></span>

### Install Ansible

Ansible needs to be installed on your local machine.

    # Fedora, CentOS, RHEL
    sudo dnf install ansible

    # Ubuntu, Debian
    sudo apt install ansible

    # Arch
    sudo pacman -S ansible

<span id="install-dependencies"></span>

### Install dependencies

ansible-galaxy collection install community.general

<span id="configure-hosts"></span>

### Configure hosts

Add the host to the Ansible inventory in inventory.yml

The IP address, hostname, password etc. can be extrapolated from the
existing configurations
in [Credentials](https://www.kth.se/social/group/kth-cloud/page/credentials/).
For example, if 172.31.0.18 is the latest server, pick 172.31.0.19.

Hostname is in the format of rr-zzzz-XXX where r is region, z is zone
and XXX is the machine ID. For example 172.31.0.11 has se-flem-001. It
is preferred to have a matching IP and hostname in order to simplify
administration and ssh, so 172.31.0.29 should have se-flem-019, etc. 

Current regions:
Sweden (se)

Current zones:
Flemingsberg (flem)

FQDN is hostname.cloud.cbh.kth.se, so for example se-flem-001.cloud.cbh.kth.se

A list of generated but not yet allocated passwords are available at the
bottom of the Credentials page.

<span id="kthcloud-host-appliance"></span>

## kthcloud host appliance

<span id="flash-iso"></span>

### Flash ISO

Flash a bootable ISO with the latest build of Ubuntu Server. 20.04 was
used at the time of writing.

<span id="install-ubuntu-server"></span>

### Install Ubuntu Server

Select and format a disk, then configure a static IP address (as
configured earlier in the Ansible inventory).

Network configuration

network: 172.31.0.0/16

address: 172.31.0.XX (as you chose in the steps above)

gateway: 172.31.83.1

nameservers: 1.1.1.1

Make sure to check *Install OpenSSH server*.

[image](/File:Ubuntu-ssh.png "wikilink")

Fill out the name and credentials form as following:

  - Your name: cloud
  - Your server's name: *hostname* in Ansible inventory
  - Pick a username: cloud
  - Choose a password: some generated password

No additional configuration is needed once the initial configuration is
made.

**NB\! **You must copy id and be able to SSH to the new machine from
your local device before running Ansible.

Instructions for this can be
found at [Credentials](https://www.kth.se/social/group/kth-cloud/page/credentials/) under **SSH-copy-id**

This needs to be possible without any passwords being entered so both
proxy host and destination hosts must have keys copied from your local
machine.

<span id="local-machine-1"></span>

## Local machine

<span id="run-the-ansible-script-to-configure-the-host"></span>

### Run the Ansible script to configure the host

Make sure only the machines you want to configure are active in the
inventory.

Make a machine inactive in the inventory by commenting it or removing it
temporarily from the file.

Run the ansible playbook

ansible-playbook setup-host.yml -i inventory.yml

The destination computers may reboot after installing packages. If this
occurs, a timeout may exit the ansible playbook prematurely.

If this is the case, when the machine is up (when you can ssh to it)
simply run the playbook again using the same command as the first time
so that it finishes properly.

<span id="connect-to-cloudstack"></span>

## Connect to CloudStack

Adding a host to CloudStack can be done using the GUI or API. Adding
through API is recommended if adding more than one host.

<span id="gui"></span>

### GUI

Login to the [dashboard](http://dashboard.cloud.cbh.kth.se)

Before adding a host, determine which cluster it should be added to. A
cluster must contain hosts with homogeneous hardware, therefore **if a
cluster for the hardware model does not already exists**, a new cluster
must be created.

<span id="adding-a-cluster"></span>

#### Adding a cluster

If a new cluster is needed, navigate to *Infrastructure \> Clusters \>
Add Cluster +*
Fill in the form as shown in the image below.
A cluster name should describe which hardware model it contains, eg.
Precision 7920.

[image](/File:Add-cluster.png "wikilink")

<span id="adding-a-host"></span>

#### Adding a host

Add a host by navigating to *Infrastructure \> Hosts \> Add Host +*
Fill in the form as shown in the image below.
If a new cluster was created, make sure it is visible in the *Cluster
name* drop-down menu

[image](/File:Add-host.png "wikilink")

<span id="api"></span>

### API

The API is accessed using CloudMonkey. See this [this
guide](https://github.com/apache/cloudstack-cloudmonkey/wiki/Getting-Started)
how to install CloudMonkey. Once installed, connect to the management
server using:

    (mycloud) 🐱 > set url http://dashboard.cloud.cbh.kth.se/client/api
    (mycloud) 🐱 > set username <username>
    (mycloud) 🐱 > set password <password>
    (mycloud) 🐱 > sync

Since the current CloudStack configuration only contains one zone and
one pod, Flemingsberg and LabRack, using
zoneid=f80a25ea-1b23-4cad-9491-42c0ccd632e3
podid=00dee33d-e80f-400d-8814-ea0c32e7f5d1
podid=00dee33d-e80f-400d-8814-ea0c32e7f5d1 in the following API-calls is
sufficient.

Before adding a host, determine which cluster it should be added to. A
cluster must contain hosts with homogeneous hardware, therefore **if the
machine type does not already exists,** a cluster must be created.

If a new cluster is needed, create it using the following API-call:

    (mycloud) 🐱 > add cluster clustername=<hardware model name, eg. Precsion 7920> \
    clustertype=CloudManaged hypervisor=KVM podid=<id> zoneid=<id>

Add hosts using the following API-call:

    (mycloud) 🐱 > add host username=cloud password=<host password> hypervisor=KVM zoneid=<id> \
    clusterid=<id, created before or if it already exists> url=http://<machine ip>

<span id="troubleshooting"></span>

## Troubleshooting

<span id="ansible-cant-connect-to-the-machine"></span>

#### Ansible can't connect to the machine

Install SSH keys on the machine by running the following command and
change the local IP placeholder:

    ssh-copy-id -o ProxyCommand="ssh -p 8022 -W %h:%p -q cloud@se-flem-001.cloud.cbh.kth.se" cloud@<local IP>

<span id="error-when-deploying-new-instance-in-cloudstack"></span>

#### Error when deploying new instance in CloudStack

Error message: VNC password is 22 characters long, only 8 permitted
Newer version of libvirt shipped with Ubuntu Server 22.04 breaks
CloudStack VNC implementation.
This is fixed in CloudStack 4.17 as seen in [this pull
request](https://github.com/apache/cloudstack/pull/6244), however until
this version of CloudStack is used, downgrade to Ubuntu Server 20.04.

<span></span>