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

To deploy Traefik as the Ingress controller, first, set the following variables in the [Traefik](Terraform/Traefik) Terraform configuration:
```terraform
# MAIA/Terraform/Traefik/terraform.tfvars
traefik_resolver = "<TRAEFIK_RESOLVER_NAME>"
acme_email = "<ACME_EMAIL>"
load_balancer_ip = "<LOAD_BALANCER_IP>"
```
Then, run the following commands to apply the Terraform configuration:
```shell
cd MAIA/Terraform/Traefik
terraform init
terraform plan
terraform apply
```
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

## Authentication 

To enable authentication for the MAIA cluster, the Dex and Login App are used. Dex is an OpenID Connect Identity (OIDC) provider that allows users to authenticate with the cluster using their credentials. The Login App is a web application that provides a login interface for users to authenticate with the cluster and retrieve their KUBECONFIG file.

## Dex
To deploy Dex, first, set the following variables in the [Dex](Terraform/Dex) Terraform configuration:
```terraform
# MAIA/Terraform/Dex/terraform.tfvars

kubeconfig_path = "<PATH_TO_KUBECONFIG>"
kube_context = "<CONTEXT_IN_KUBECONFIG>"

traefik_resolver       = "<TRAEFIK_RESOLVER_NAME>"
dex_hostname         = "<DEX_HOSTNAME>"
token_expiration     = "720h"

## Optional Connectors

### GitHub
#github_client_id = "<GITHUB_CLIENT_ID>"
#github_client_secret = "<GITHUB_CLIENT_SECRET>"
#github_hostname = "<GITHUB_HOSTNAME>"
#github_organization = "<GITHUB_ORGANIZATION>"


### Login App
static_secret        = "<STATIC_SECRET>"
static_id            = "<STATIC_ID>"
callbacks            = [
    "https://<LOGIN_APP_URL>/callback"
  ]

### LDAP
ldap_host = "<OPENLDAP_SVC>.<OPENLDAP_NAMESPACE>.svc.cluster.local:389"
ldap_bind_dn = "cn=admin,dc=maia,dc=cloud,dc=cbh,dc=kth,dc=se"
ldap_bind_pw = "<LDAP_PASSWORD>"
ldap_user_base_dn = "ou=users,dc=maia,dc=cloud,dc=cbh,dc=kth,dc=se"
ldap_group_base_dn = "ou=groups,dc=maia,dc=cloud,dc=cbh,dc=kth,dc=se"

### Keycloak

keycloack_client_id = "<KEYCLOAK_CLIENT_ID>"
keycloack_client_secret = "<KEYCLOAK_CLIENT_SECRET>"
keycloack_redirect_uri = "https://<DEX_HOSTNAME>/callback"
keycloack_issuer = "<KEYCLOAK_ISSUER>"
```
Then, run the following commands to apply the Terraform configuration:
```shell
cd MAIA/Terraform/Dex
terraform init
terraform plan
terraform apply
```


## Login App
To deploy the Login App, first, set the following variables in the [Login App](Terraform/Login_App) Terraform configuration:
```terraform
# MAIA/Terraform/Login_App/terraform.tfvars

kubeconfig_path = "<PATH_TO_KUBECONFIG>"
kube_context = "<CONTEXT_IN_KUBECONFIG>"

loginapp_hostname      = "<LOGIN_APP_HOSTNAME>"
secret                 = "<LOGIN_APP_SECRET>"
client_secret          = "<DEX_OR_KEYCLOAK_CLIENT_SECRET>"
client_id              = "<DEX_OR_KEYCLOAK_CLIENT_ID>"
issuer_url             = "<DEX_OR_KEYCLOAK_ISSUER>"
cluster_server_address = "<K8S_API_SERVER_ADDRESS>"
cluster_server_name    = "MAIA"
traefik_resolver       = "<TRAEFIK_RESOLVER_NAME>"
ca_file                = "<CA_FILE_PATH>"
```
The CA file can be found in `/var/snap/microk8s/current/certs/ca.crt` on the control-plane node.
For Karmada Cluster, the CA file can be found in the `karmada-cert` secret in the `karmada-system` namespace, as `server_ca.crt`.

Then, run the following commands to apply the Terraform configuration:

```shell
cd MAIA/Terraform/Login_App
terraform init
terraform plan
terraform apply
```


## Microk8s Addons
The following Microk8s addons are enabled in the MAIA cluster:
```shell
microk8s enable dashboard metrics-server cert-manager metallb nfs hostpath-storage
microk8s enable istio observability # Optional, DO NOT enable istio if traefik is used as the Ingress controller
```

### Observability

Observability is a set of tools that provide insights into the cluster and the applications running on it. The Observability tools enabled in the MAIA cluster are:
- Prometheus
- Grafana
- Kube-Prometheus-Stack
- Loki
- Tempo

To add OIDC Authentication and GPU Metrics to the Observability tools, the following configurations are applied to the `kube-prom-stack` Helm chart:

```yaml
grafana:
  defaultDashboardsEnabled: true
  persistence:
    enabled: true


  grafana.ini:
    server:
      root_url: <GRAFANA_URL>
    ## grafana Authentication can be enabled with the following values on grafana.ini
    auth.generic_oauth:
      name: "OAuth"
      enabled: true
      client_id:  <CLIENT_ID>
      client_secret: <CLIENT_SECRET>
      scopes: openid profile email
      empty_scopes: false
      team_ids_attribute_path: groups[*]
      team_ids: "MAIA:admin"
      role_attribute_path: contains(groups[*], 'MAIA:admin') && 'Admin' || 'Viewer'
      teams_url: <KEYCLOACK_REALM_URL>/protocol/openid-connect/userinfo
      auth_url: <KEYCLOACK_REALM_URL>/protocol/openid-connect/auth
      token_url: <KEYCLOACK_REALM_URL>/protocol/openid-connect/token
      api_url: <KEYCLOACK_REALM_URL>/protocol/openid-connect/userinfo

prometheus:


  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
    additionalScrapeConfigs:
    - job_name: gpu-metrics
      kubernetes_sd_configs:
      - namespaces:
          names:
          - gpu-operator-resources
        role: endpoints
      metrics_path: /metrics
      relabel_configs:
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_node_name
        target_label: kubernetes_node
      scheme: http
      scrape_interval: 1s
```
And, to expose the Grafana service using Traefik as the Ingress controller, the following Ingress configuration is applied:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: observability
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: 'true'
    traefik.ingress.kubernetes.io/router.tls.certresolver: <TRAEFIK_RESOLVER>
spec:
  tls:
    - hosts:
        - <GRAFANA_URL>
  rules:
    - host: <GRAFANA_URL>
      http:
        paths:
          - path: /
            pathType: ImplementationSpecific
            backend:
              service:
                name: kube-prom-stack-grafana
                port:
                  number: 80
EOF
```



## Kubernetes Dashboard
To expose the Kubernetes Dashboard using Traefik as the Ingress controller, the following Ingress configuration is applied:
```bash
cat <<EOF | kubectl apply -f -
---
apiVersion: traefik.containo.us/v1alpha1
kind: ServersTransport
metadata:
  name: kubernetes-dashboard-transport
  namespace: kube-system

spec:
  serverName: kubernetes-dashboard
  insecureSkipVerify: true

---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: kubernetes-dashboard-ingress
  namespace: kube-system
spec:
  entryPoints:                      # [1]
    - websecure
  routes:                           # [2]
  - kind: Rule
    match:   Host(`<DASHBOARD_URL>`) # [3]
    priority: 10                    # [4]
    services:                       # [8]
    - kind: Service
      name: kubernetes-dashboard
      namespace: kube-system
      port: 443                      # [9]
      serversTransport: kubernetes-dashboard-transport
  tls:                              # [11]
    certResolver: <TRAEFIK_RESOLVER>

EOF
```
## MinIO

MinIO is a high-performance object storage server that is API-compatible with Amazon S3 cloud storage service. MinIO is used to store the data of the applications deployed on the cluster.

To deploy a MinIO tenant on a specific namespace, run the following command:
```shell
microk8s kubectl-minio tenant create <TENANT_NAME> --servers 1 --volumes 1 --capacity 1Gi --namespace <NAMESPACE> --disable-tls --storage-class nfs --enable-audit-logs=false --enable-prometheus=false
```

To configure MinIO for the MAIA cluster, the following environment variables should be set inside the Secret `admin-env-configuration`:
```shell
admin-env-configuration

export MINIO_ROOT_USER="<MINIO_ROOT_USER>"
export MINIO_ROOT_PASSWORD="<MINIO_ROOT_PW>"
export MINIO_SERVER_URL="<MINIO_URL>"
export MINIO_IDENTITY_OPENID_CONFIG_URL="<KEYCLOAK_REALM_URL>/.well-known/openid-configuration"
export MINIO_IDENTITY_OPENID_CLIENT_ID="<CLIENT_ID>"
export MINIO_IDENTITY_OPENID_CLIENT_SECRET="<CLIENT_SECRET>"
export MINIO_IDENTITY_OPENID_REDIRECT_URI="https://<MINIO_CONSOLE_URL>/oauth_callback"
export MINIO_IDENTITY_OPENID_CLAIM_NAME="groups"
export MINIO_IDENTITY_OPENID_SCOPES="openid,profile,email"
export MINIO_IDENTITY_OPENID_DISPLAY_NAME="MAIA"
```
And then, create a new Policy for the MinIO tenant:
```shell
microk8s kubectl-minio tenant policy create <TENANT_NAME> <MAIA_GROUP_NAME> --permission <PERMISSIONS>
```

## Join Cluster

Before running the join command, make sure to:
- Install microk8s on the worker node
- Update the allow-cluster-internal-ingress-only network policy
- Create the corresponding Host-Endpoint for the worker node
- Update the UFW rules to allow traffic from the worker node to the control-plane node and vice versa
- Verify full connectivity among the nodes

On the control-plane node, run the following command to get the token:
```shell
microk8s add-node
```
Install microk8s on the worker nodes and join the cluster by running the following command on the worker nodes:
```shell
sudo snap install microk8s --classic --channel=1.28/stable
sudo microk8s join <CONTROL_PLANE_NODE_IP>:16443/<TOKEN>
```
On the control-plane node, run the following command to check the status of the worker nodes:
```shell
microk8s kubectl get nodes
```
Next, label the worker node as a worker:
```shell
microk8s kubectl label node <WORKER_NODE_NAME> node-role.kubernetes.io/worker=worker
```
