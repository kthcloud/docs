# Configuration
This page describes the configuration of the cloud.

## Overview
The cloud is divided into zones that logically group hardware. Each zone is in turn divided into two main clusters; `sys-cluster` and `deploy-cluster`. The `sys-cluster` is used to manage several `deploy-clusters` and only exists in one zone, `se-flem`, while the `deploy-cluster` is used to deploy applications and VMs and exists in all zones. 

The sys-cluster uses K3s and hosts Rancher. Rancher is then used to manage any system servies such as `console` and `go-deploy`. A deploy-cluster is set up using Rancher. A deploy cluster may be extended with `KubeVirt` to deploy VMs.


### se-flem
The `se-flem` zone is located in Flemingsberg and is the main cluster of the cloud and, as such, hosts the sys-cluster. This zone also hosts a deploy-cluster with `KubeVirt` enabled.

### se-kista
The `se-kista` zone is located in Kista and is a secondary cluster of the cloud. It is not yet set up with the new system, see [the blog post](News/2024-04-14) for more information.

### IP Setup
| Zone | Host CIDR | IPMI CIDR |
|------|--------------|--------------|
| se-flem | 172.31.0.0/16 | 10.17.5.0/24 |
| se-kista | 172.30.0.0/16 | Fill in! |

### IPMI
| Vendor | Username | Password |
|--------|----------|----------|
| Dell | root | calvin |
| Supermicro | ADMIN | ADMIN |