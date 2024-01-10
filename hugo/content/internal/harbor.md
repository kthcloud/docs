# Harbor

<img src="../../images/harbor_logo.png" width="35%">

Harbor is used as the container registry in kthcloud.

## Access

Harbor is mainly accessed by system admins, but a normal user can access
it too.

The dashboard is available at <https://registry.cloud.cbh.kth.se>.

The virtual machine is available over ssh using `ssh 172.31.1.10`

## Setup

Harbor is hosted on a virtual machine in CloudStack.

## Administration

**Edit**: Edit using the [dashboard](https://registry.cloud.cbh.kth.se)
or the configuration files at `/opt/harbor/`

**Restart**: Run `systemctl restart harbor`

## Persistent storage

Harbor uses a database inside the virtual machine.