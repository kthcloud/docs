[200px](/File:Rancher-logo.png "wikilink")

Rancher is used to manage all the Kubernetes clusters and their
resources in kthcloud. Many of its features are not used however, such
as cluster creation, since CloudStack is already used for that.

## Access

Rancher is used by system admins and a special account is needed to
access it.

The dashboard is available at <https://rancher.mgmt.cloud.cbh.kth.se>.

## Setup

The master instance is setup in the management Kubernetes cluster in the
Flemingsberg zone. The entire management cluster is dedicated to run
Rancher.

Rancher was installed using Helm.

### Slave Setup

Rancher is installed manually in each Kubernetes cluster since it is not
used to provision cluster itself (CloudStack does Kubernetes creation).

## Administration

**Update**: Run the Helm-chart again with a higher version

## Persistent storage

Rancher uses some databases that are stored on the NAS in the
Flemingsberg Zone.