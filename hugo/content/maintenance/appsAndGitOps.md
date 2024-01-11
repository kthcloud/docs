---
title: Apps and GitOps
---

# Apps and GitOps

Most of the time we use deploy to manage all of the apps and VMs. However, there are some apps that are not managed by deploy, such as depenedencies of deploy itself. These apps are managed using GitOps. This means that all apps are deployed using manifests stored in a GitHub repo, you can find the repo [here](https://github.com/kthcloud/k8s). The repo is only accessible to system admins, so if you need access, ask a system admin to add you.

The repo uses templates to make it easier to setup, for example, NFS storage for persistent volumes. These template values are substituted with the correct values after the push to the repo. It is divided into clusters under `apps`, meaning that if you add a manifest to the `sys` folder, it will be deployed to the sys-cluster. 

Please see the [System Apps](/administration/systemApps) page for more information on how to add apps to the sys-cluster.

## Configuration
Behind the hood, it is [Rancher](/internal/rancher) that enables GitOps. Rancher uses a tool called [Fleet](https://fleet.rancher.io/) to manage the GitOps. Rancher monitors changes in the `apps` folder under the `artifacts` branch deploys the manifests to the correct cluster.
To edit the configuration, go to [Rancher](https://rancher.mgmt.cloud.cbh.kth.se) and click on `Continuous Delivery` in the left menu.

<img src="../../images/rancher_cd.png" width="35%">