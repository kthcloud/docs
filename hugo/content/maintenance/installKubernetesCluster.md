# Install Kubernetes Cluster

Before you start, this guide is intended you guide you through the creation of Kubernetes clusters in the **new** environment (where KubeVirt replaces CloudStack).

## Prerequisites

- One or more ready-to-use machines
- kubectl and a kubeconfig file with access to the cluster
- Helm installed on your local machine

## Create a sys-cluster

A sys-cluster is a Kubernetes cluster that is used for system services, such as the console and go-deploy. It also hosts Rancher, which is then used to manage additional clusters. For this reason, the sys-cluster is set up first and in a specific way. Sys-clusters uses [K3s](https://k3s.io) as the Kubernetes distribution. 

This guide is only required if you are setting up a new sys-cluster. If you are adding a new node to an existing sys-cluster, you don't need to configure anything.


### 1. Setup Rancher and dependencies
You should SSH into a master node of the sys-cluster to run the following commands.

1. Install `MetalLB`
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

1. Install `Ingress-NGINX`
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.ingressClassResource.default=true
```

2. Install `cert-manager`

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
### 2. Update required DNS records
Since the sys-cluster is used to manage other clusters, it is important that the DNS records are set up correctly. 

1. Ensure that a DNS record exists for the sys-cluster. This record should point to the public IP of the sys-cluster, which in turn points to the MetalLB IP range.

Use the following command to get the assigned local IP of the sys-cluster:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

2. Ensure that an internal DNS record exists for the sys-cluster. This record should point to the local IP of the sys-cluster. This is to enable the sys-cluster to issue certificates. 

3. Ensure that DNS records exists for any other service that will be hosted in the sys-cluster. Such as for `console` and `go-deploy` that are hosted under `cloud.cbh.kth.se`. 

## Create a deploy cluster
A deploy cluster is a Kubernetes cluster that is used for deploying applications and VMs for the users and is therefore controlled by go-deploy.
This cluster is set up using Rancher, which means that a sys-cluster is required to manage it. 

### Steps
1. Log in [Rancher](https://mgmt.cloud.cbh.kth.se) and create an empty cluster.
2. Navigate to `Cluster Management` -> `Add Cluster` -> `Create` and select `Custom`
3. Fill in the required details for your cluster, such as automatic snapshots to (MinIO)[https://minio.cloud.cbh.kth.se]. 
4. Make sure to **untick** both `CoreDNS` and `NGINX Ingress` as they will be installed by Helm later.
5. Click `Create` and wait for the cluster to be created.
6. Deploy your node by following the Host Preparation guide.

### Next steps
If you are deploying the first node in the cluster, you should follow the steps below. These steps assumes that every previous step has been completed.
Make sure that the cluster you are deploying have atleast one node for each role (control-plane, etcd, and worker). 

1. Set variables
Set the following envs:
```bash
# e.g. example.com if you want to issue certificates for *.app.cloud.cbh.kth.se
export DOMAIN=
# API URL to the PDNS instance http://172.31.0.68:8081
export PDNS_API_URL=
# API key for the PDNS instance (base64 encoded)
export PDNS_API_KEY=
# IP_POOL for MetalLB, e.g. 172.31.50.100-172.31.50.150
export IP_POOL=
```

2. Install `CoreDNS`
```bash
helm upgrade --install coredns coredns \
  --repo https://coredns.github.io/helm \
  --namespace kube-system \
  --create-namespace
```

3. Install `Ingress-NGINX`
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.ingressClassResource.default=true
```

4. Install `cert-manager`
```bash
helm upgrade --install \
  cert-manager \
  jetstack/cert-manager \
  --repo https://charts.jetstack.io \
  --namespace cert-manager \
  --create-namespace \
  --version v1.12.0 \
  --set 'extraArgs={--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}' \
  --set installCRDs=true
```

5. Install cert-manager Webhook for DNS challenges
kthcloud uses PowerDNS for DNS management, so we need to install the cert-manager-webhook for PowerDNS.

```bash
helm install \
  --namespace cert-manager \
  --repo https://lordofsystem.github.io/cert-manager-webhook-powerdns \
  cert-manager-webhook-powerdns-cloud-cbh-kth-se \
  cert-manager-webhook-powerdns/cert-manager-webhook-powerdns \
  --set groupName=${DOMAIN} \
```

6. Install cert-manager issuer
Now that we have the webhook installed, we need to install the issuer that will use the webhook to issue certificates.

Create the PDNS secret (or any other DNS provider secret)
```yaml
kubectl apply -f - <<EOF
kind: Secret
apiVersion: v1
metadata:
  name: pdns-secret
  namespace: cert-manager
data:
  api-key: ${PDNS_API_KEY}
EOF
```

Create the cluster issuer for *http01* and *dns01* challenges
```yaml
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: go-deploy-cluster-issuer
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: noreply@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
      - dns01:
          webhook:
            groupName: ${DOMAIN}
            solverName: pdns
            config:
              zone: ${DOMAIN}
              secretName: pdns-secret
              zoneName: ${DOMAIN}
              apiUrl: ${PDNS_API_URL}
EOF
```

Create wildcard certificate for all subdomains
```yaml
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: go-deploy-wildcard
  namespace: ingress-nginx
spec:
  secretName: go-deploy-wildcard-secret
  secretTemplate:
    labels:
      # This should match with the settings in go-deploy
      app.kubernetes.io/deploy-name: deploy-wildcard-secret
  issuerRef: 
    kind: ClusterIssuer
    name: letsencrypt-prod
  commonName: ""
  dnsNames:
    - "*.apps.${DOMAIN}"
    - "*.vm-app.${DOMAIN}"
    - "*.storage.${DOMAIN}"
EOF
```

7. Install `MetalLB`
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.4/config/manifests/metallb-native.yaml
```

```bash
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: deploy-ip-pool
  namespace: metallb-system
spec:
  addresses:
  - $IP_POOL
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: deploy-l2-adv
  namespace: metallb-system
EOF
```

8. Install `hairpin-proxy`
Hairpin-proxy is a proxy that allows us to access services in the cluster from within the cluster. This is needed for the webhook to be able to access the cert-manager service when validating DNS challenges.

```bash
kubectl apply -f https://raw.githubusercontent.com/compumike/hairpin-proxy/v0.2.1/deploy.yml
```

9. Install `KubeVirt`
KubeVirt is what enables us to run VMs in the cluster. This is not mandatory, but it is required if the cluster is to be used for VMs.

Install the KubeVirt operator and CRDs
```bash
export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/$VERSION/kubevirt-operator.yaml
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/$VERSION/kubevirt-cr.yaml
```

Verify installation
```bash
kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}"
```

Install CDI (Containerized Data Importer)
```bash
export TAG=$(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest)
export VERSION=$(echo ${TAG##*/})
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml
```

10. Add the cluster to go-deploy
Edit go-deploy's config and add a new or edit an existing zone. 
```yaml
zones:
- name: my-zone
    configSource:
    type: rancher
    cluster:
```