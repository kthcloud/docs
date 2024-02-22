# Configure MAIA Cluster
In this section, you will learn how to configure a MAIA cluster to support different cluster features and applications.
In detail, the following aspects will be covered:
- Cluster Permissions
- Network Policies
- Storage Classes
- Kubernetes Ingress
- Microk8s Addons
- Join Cluster


## Cluster Permissions
To allow Admin roles and allow authenticated users to access the cluster resources, follow the Terraform configuration in [Cluster Permissions](Terraform/Cluster_Permissions).
In the Terraform script, the `kubeconfig_path` variable should be set to the path of the kubeconfig file for the cluster.

```terraform
# MAIA/Terraform/Cluster_Permissions/terraform.tfvars
kubeconfig_path = "<PATH_TO_KUBECONFIG>"
kube_context = "<CONTEXT_IN_KUBECONFIG>"
admin_group = "<ADMIN:GROUP>"
```
After setting the variables, run the following commands to apply the Terraform configuration:
```shell
cd MAIA/Terraform/Cluster_Permissions
terraform init
terraform plan
terraform apply

```

## Network Policies
Calico is the chosen Container Network Interface, to create and manage network policies, as well as firewall rules and cluster roles.
The MAIA network policies are defined in order to:
- Create the Host Endpoints for the cluster nodes

For each cluster node:
```shell
kubectl apply -f - <<EOF
apiVersion: crd.projectcalico.org/v1
kind: HostEndpoint
metadata:
  name: <NODE_NAME>-<INTERFACE_NAME>
  labels:
    host-endpoint: enabled
    exposed-to-public: enabled # only for control-plane nodes
spec:
  interfaceName: <INTERFACE_NAME> # see ifconfig
  node: <NODE_NAME>
  expectedIPs:
    - <INTERFACE_IP>
EOF
```
- Allow outgoing traffic from the cluster nodes
```shell
kubectl apply -f - <<EOF
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: allow-outbound-external
spec:
  order: 10
  egress:
    - action: Allow
  selector: has(host-endpoint)
EOF
```
- Deny any incoming traffic from outside the cluster to the cluster nodes
```shell
kubectl apply -f - <<EOF
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: allow-cluster-internal-ingress-only
spec:
  order: 20
  preDNAT: true
  applyOnForward: true
  ingress:
    - action: Allow
      source:
        nets: [
          <POD_CIDR>, <LIST_OF_NODE_IP_ADDRESSES>
        ]
    - action: Deny
  selector: has(host-endpoint)
EOF
```
- Allow specified NodePort traffic

To allow any incoming traffic to a specific port (e.g Kubernetes API server port 16443):
```shell
kubectl apply -f - <<EOF
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: allow-nodeport-<RULE_NAME>
spec:
  applyOnForward: true
  ingress:
    - action: Allow
      destination:
        ports:
          - <PORT_TO_EXPOSE> # e.g. 16443
        selector: has(exposed-to-public)
      protocol: TCP
  order: 10
  preDNAT: true
  selector: has(host-endpoint)
EOF
```
To allow incoming traffic to a specific port from a specific IP address:
```shell
kubectl apply -f - <<EOF
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: allow-nodeport-<RULE_NAME>
spec:
  applyOnForward: true
  ingress:
    - action: Allow
      destination:
        ports:
          - <PORT>
        selector: has(<NODE_LABEL>)
      protocol: TCP
      source:
        nets:
          - <FROM_IP>
  order: 10
  preDNAT: true
  selector: has(host-endpoint)
EOF
```

- Configure Felix to bypass network policies for some default ports
```shell
kubectl apply -f - <<EOF
apiVersion: crd.projectcalico.org/v1
kind: FelixConfiguration
metadata:
  name: default
spec:
  failsafeInboundHostPorts:
    - port: 22
      protocol: tcp
    - port: 53
      protocol: udp
    - port: 67
      protocol: udp
    - port: 68
      protocol: udp
    - port: 179
      protocol: tcp
    - port: 2379
      protocol: tcp
    - port: 2380
      protocol: tcp
    - port: 443
      protocol: tcp
    - port: 6666
      protocol: tcp
    - port: 6667
      protocol: tcp
    - port: 80
      protocol: tcp
EOF
```

## Kubernetes Ingress
To expose the applications deployed on the MAIA cluster, a Kubernetes Ingress is used. The Ingress is a collection of rules that allow inbound connections to reach the cluster services. The Ingress controller is responsible for fulfilling the Ingress, usually with a load balancer.
In the MAIA cluster, the Ingress controller is Traefik.

## Storage Classes

### Local Hostpath Storage
Local hostpath storage is based on the local storage of the cluster nodes. It is used to store the data of the applications deployed on the cluster.
In Microk8s, the hostpath volumes are created by default in the `/var/snap/microk8s/common/default-storage` directory.
```shell
microk8s enable hostpath-storage
```
### NFS Storage
NFS storage is used to store the data of the applications deployed on the cluster on an NFS server.
The NFS server is installed on the control-plane node and the NFS client is installed on the worker nodes.
To enable NFS Storage, the nfs-common package should be installed on the cluster nodes:

```shell
sudo apt install -y nfs-common
```
In Microk8s, the NFS volumes are created by default in the `/var/snap/microk8s/common/nfs-storage` directory.
```shell
microk8s enable nfs -n <CONTROL_PLANE_NODE>
```
### Storage Configuration
To create physical partitions on the local server storage, the Logical Volume Manager (LVM) is used. The LVM is a device mapper that provides logical volume management for the Linux kernel. The LVM allows the creation of logical volumes from physical volumes, and the resizing of logical volumes.

#### Physical Volumes

```shell
sudo lvmdiskscan # List all physical volumes
sudo pvcreate /dev/sda /dev/sdb # Create physical volumes
```

#### Volume Group

```shell
`` # Scan for volume groups
sudo vgcreate volume_group_name /dev/sda /dev/sdb /dev/sdc # Create volume group
sudo vgextend volume_group_name /dev/sdb # Extend volume group
```

#### Logical Volumes

```shell
sudo lvscan # Scan for logical volumes
sudo lvcreate -L 10G -n test LVMVolGroup # Create logical volume
sudo lvresize -L +5G --resizefs LVMVolGroup/test # Resize logical volume
sudo mkfs -t ext4 LVMVolGroup/test # Format logical volume
```

#### Mounting Volumes

Mount the logical volume to the directory for nfs in microk8s ( or alternatively, the local directory for
hostpath-storage):

```shell
sudo mount /dev/LVMVolGroup/test /var/snap/microk8s/common/default-storage
sudo mount /dev/LVMVolGroup/test /var/snap/microk8s/common/nfs-storage
```

## Microk8s Addons
The following Microk8s addons are enabled in the MAIA cluster:
```shell
microk8s enable dashboard metrics-server cert-manager metallb nfs hostpath-storage
microk8s enable istio prometheus # Optional, DO NOT enable istio if traefik is used as the Ingress controller
```
