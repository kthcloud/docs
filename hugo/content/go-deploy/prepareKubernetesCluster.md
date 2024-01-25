# Prepare a Kubernetes cluster

This guide is aimed to guide you through when setting up a new Kubernetes cluster that go-deploy should use, such as when creating a new zone.

## Prerequisites
- Kubernetes cluster running:
  - Version >= 1.26.0
  - Hosted either by Rancher or CloudStack (for now)
- Helm (*Optional if configuring through terminal*)
  - Version >= 3.0.0 
- kubectl

## Steps
Set the following envs:
```bash
# e.g. example.com if you want to issue certificates for *.app.example.com
export DOMAIN=
# API URL to the PDNS instance https://api.example.com
export PDNS_API_URL=
# API key for the PDNS instance (base64 encoded)
export PDNS_API_KEY=
```

### 1. Ensure go-deploy can access the cluster
go-deploy fetches the Kubernetes config everytime it runs, so it needs to be able to access the cluster. Currently only CloudStack and Rancher is supported.

### 2. Install Ingress Nginx Controller

Using Helm:
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

Using Rancher:
1. Navigate to the cluster and then `Apps/Repositories` and click *Create*. 
2. Fill in the following:
- Name: `ingress-nginx`
- Description: `Ingress Nginx`
- URL: `https://kubernetes.github.io/ingress-nginx`

<img src="../../images/rancher_add_chart_repo.png" width="75%">

3. Install the chart by navigating to `Apps/Charts`, find the `ingress-nginx` chart and click *Install*.

<img src="../../images/rancher_install_chart.png" width="75%">

### 2. Install cert-manager

Using Helm:
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

Using Rancher:
1. Navigate to the cluster and then `Apps/Repositories` and click *Create*.
2. Tick the checkbox *Customize the Helm options before install* and click next.

<img src="../../images/rancher_install_cert_manager_step_1.png" width="75%">

3. Ensure the following settings are set and click *Install*.
```yaml
...
dns01RecursiveNameservers: '8.8.8.8:53\,1.1.1.1:53'
dns01RecursiveNameserversOnly: true
installCRDs: true
...
```

### 3. Install Cert Manager Webhook for DNS challenges
kthcloud uses PowerDNS for DNS management, so we need to install the cert-manager-webhook for PowerDNS. If you are using another DNS provider, you need to install the webhook for that provider instead.

Using Helm:
```bash
helm install \
  --namespace cert-manager \
  --repo https://lordofsystem.github.io/cert-manager-webhook-powerdns \
  cert-manager-webhook-powerdns-cloud-cbh-kth-se \
  cert-manager-webhook-powerdns/cert-manager-webhook-powerdns \
  --set groupName=${DOMAIN} \
```

Where Root domain is the domain that you want to issue certificates for. For example, if you want to issue certificates for `*.example.com`, then the root domain is `example.com`. 

Using Rancher:
1. Add the repo like was done for the ingress-nginx chart.
- Name: `cert-manager-webhook-powerdns-charts`
- Description: `Cert Manager Webhook for PowerDNS`
- URL: `https://lordofsystem.github.io/cert-manager-webhook-powerdns`

2. Install the chart by navigating to `Apps/Charts`, find the `cert-manager-webhook-powerdns` chart.
3. Ensure it is installed in the `cert-manager` namespace and set the following values:
```yaml
...
groupName: ${DOMAIN}
...
```

Where Root domain is the domain that you want to issue certificates for. For example, if you want to issue certificates for `*.example.com`, then the root domain is `example.com`.

### 4. Install cert-manager issuer
Now that we have the webhook installed, we need to install the issuer that will use the webhook to issue certificates.

1. Create the PDNS secret (or any other DNS provider secret)
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

2. Create the cluster issuer for *http01* and *dns01* challenges
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
3. Create wildcard certificate for all subdomains
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

### 5. Install hairpin-proxy
Hairpin-proxy is a proxy that allows us to access services in the cluster from within the cluster. This is needed for the webhook to be able to access the cert-manager service when validating DNS challenges.

Using kubectl:
```bash
kubectl apply -f https://raw.githubusercontent.com/compumike/hairpin-proxy/v0.2.1/deploy.yml
```

### 6. Add the cluster to go-deploy
Edit go-deploy's config and add a new or edit an existing zone. 

With CloudStack:
```yaml
zones:
- name: my-zone
    configSource:
    type: cloudstack
    clusterId: 
    externalUrl: # External URL to the cluster (e.g. https://my-cluster.example.com:6443)
```

With Rancher:
```yaml
zones:
- name: my-zone
    configSource:
    type: rancher
    clusterId: 
```