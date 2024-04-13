# Install Kubernetes Cluster

Before you start, this guide is intended you guide you through the creation of Kubernetes clusters in the **new** environment (where KubeVirt replaces CloudStack). 


## Prerequisites

- One or more ready-to-use machines
- kubectl and a kubeconfig file with access to the cluster
- Helm installed on your local machine

## Sys-cluster steps

A sys-cluster is a Kubernetes cluster that is used for system services, such as the console and go-deploy. It also hosts Rancher, which is then used to manage additional clusters. For this reason, the sys-cluster is set up first and in a specific way. Sys-clusters uses [K3s](https://k3s.io) as the Kubernetes distribution. 

This guide is only required if you are setting up a new sys-cluster. If you are adding a new node to an existing sys-cluster, you don't need to configure anything.


### **Phase one**
You should SSH into a master node of the sys-cluster to run the following commands.

1. Install `MetalLB` in the sys-cluster
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.4/config/manifests/metallb-native.yaml
```

2. Configure IP range for MetalLB

Edit the `POOL` variable to match the IP range you want to use. The IP range should be within the subnet of the sys-cluster.

```bash
POOL="172.31.100.100-172.31.100.200"

kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: sys-cluster-pool
  namespace: metallb-system
spec:
  addresses:
  - $POOL
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: sys-cluster-l2
  namespace: metallb-system
EOF
```

1. Install `ingress-nginx` in the sys-cluster
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.ingressClassResource.default=true
```

2. Install `cert-manager` in the sys-cluster

```bash
helm upgrade --install cert-manager cert-manager \
  --repo https://charts.jetstack.io \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

3. Install Rancher

Edit the variables as needed. The `hostname` variable is the URL that Rancher will be available at.

```bash
CHART_REPO="https://releases.rancher.com/server-charts/latest"
HOSTNAME="mgmt.cloud.cbh.kth.se"

helm upgrade --install rancher rancher \
  --namespace cattle-system \
  --create-namespace \
  --repo $CHART_REPO \
  --set hostname=$HOSTNAME \
  --set bootstrapPassword=admin \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=noreply@cloud.cbh.kth.se\
  --set letsEncrypt.ingress.class=nginx
```


### **Phase two**
You should use a kubeconfig from Rancher to run the following commands.