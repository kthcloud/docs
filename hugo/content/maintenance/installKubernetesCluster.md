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

1. Set envs (you need to set some of them manually, or edit them for your environment):
    ```bash
    # Cluster Configuration
    export DOMAIN="cloud.cbh.kth.se"
    export IP_POOL="172.31.100.100-172.31.100.150"
  
    # PDNS Configuration
    export PDNS_API_URL="http://172.31.1.68:8081"
    export PDNS_API_KEY=[base64 encoded]
    
    # NFS Configuration
    export NFS_SERVER="nfs.cloud.cbh.kth.se"
    export CLUSTER_NFS_PATH="/mnt/cloud/apps/sys"

    # S3 Configuration
    export S3_ENDPOINT="s3.cloud.cbh.kth.se"
    
    export LOKI_S3_BUCKET_PREFIX="loki"
    export LOKI_S3_ACCESS_KEY=
    export LOKI_S3_SECRET_KEY=
    ```

2. Install `MetalLB`
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.4/config/manifests/metallb-native.yaml
    ```

3. Configure IP range for MetalLB

    Edit the `POOL` variable to match the IP range you want to use. The IP range should be within the subnet of the sys-cluster.

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: sys-cluster-pool
      namespace: metallb-system
    spec:
      addresses:
      - $IP_POOL
    ---
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: sys-cluster-l2
      namespace: metallb-system
    EOF
    ```

4. Install `Ingress-NGINX`
    ```bash
    helm upgrade --install ingress-nginx ingress-nginx \
      --repo https://kubernetes.github.io/ingress-nginx \
      --namespace ingress-nginx \
      --create-namespace \
      --values - <<EOF
    controller:
      ingressClassResource:
        default: "true"
      config:
        allow-snippet-annotations: "true"
        proxy-buffering: "on"
        proxy-buffers: 4 "512k"
        proxy-buffer-size: "256k"
    defaultBackend:
      enabled: true
      name: default-backend
      image:
        repository: dvdblk/custom-default-backend
        tag: "latest"
        pullPolicy: Always
      port: 8080
      extraVolumeMounts:
        - name: tmp
          mountPath: /tmp
      extraVolumes:
        - name: tmp
          emptyDir: {}
    EOF
    ```

5. Install `cert-manager`
    ```bash
    helm upgrade --install \
      cert-manager \
      cert-manager \
      --repo https://charts.jetstack.io \
      --namespace cert-manager \
      --create-namespace \
      --version v1.12.0 \
      --set 'extraArgs={--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}' \
      --set installCRDs=true
    ```
6. Install cert-manager Webhook for DNS challenges

    kthcloud uses PowerDNS for DNS management, so we need to install the cert-manager-webhook for PowerDNS.

    ```bash
    helm install cert-manager-webhook-powerdns-domain-1 cert-manager-webhook-powerdns \
      --repo https://lordofsystem.github.io/cert-manager-webhook-powerdns \
      --namespace cert-manager \
      --set groupName=${DOMAIN}
    ```


7. Install cert-manager issuer

    Now that we have the webhook installed, we need to install the issuer that will use the webhook to issue certificates.

    Create the PDNS secret (or any other DNS provider secret)
    ```bash
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

    Create the cluster issuer for *http01* and *dns01* challenges.
    Keep in mind that if you need more than one root domain, you need to create a new issuer for each domain. The issuer name should be unique for each domain, for example `deploy-cluster-issuer-domain-1` and `deploy-cluster-issuer-domain-2`.

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: cluster-issuer-domain-1
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: noreply@${DOMAIN}
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

    Create wildcard certificate
    ```bash
    kubectl apply -f - <<EOF
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: wildcard-domain-1
      namespace: ingress-nginx
    spec:
      secretName: wildcard-domain-1-secret
      issuerRef: 
        kind: ClusterIssuer
        name: cluster-issuer-domain-1
      commonName: ""
      dnsNames:
        - "*.${DOMAIN}"
    EOF
    ```

    Create a fallback ingress so a certificate does not need to be specified on all ingresses
    ```bash
    kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: fallback-ingress-se-flem
      namespace: ingress-nginx
    spec:
      ingressClassName: nginx
      tls:
      - hosts:
        - "*.cloud.cbh.kth.se"
        secretName: kthcloud-wildcard-se-flem-secret
      rules:
      - host: "*.cloud.cbh.kth.se"
    EOF
    ```

8. Install `Rancher`

    Edit the variables as needed. The `hostname` variable is the URL that Rancher will be available at.

    ```bash
    CHART_REPO="https://releases.rancher.com/server-charts/latest"

    helm upgrade --install rancher rancher \
      --namespace cattle-system \
      --create-namespace \
      --repo $CHART_REPO \
      --set hostname=mgmt.${DOMAIN} \
      --set bootstrapPassword=admin \
      --set ingress.tls.source=letsEncrypt \
      --set letsEncrypt.email=noreply@${DOMAIN} \
      --set letsEncrypt.ingress.class=nginx
    ```

    Wait for Rancher to be installed.

    ```bash
    watch kubectl get pods -n cattle-system
    ```

9. Fix expiry date for secrets

    Go to the Rancher URL deployed. The navigate to `Global Settings` -> `Settings` and edit both `auth-token-max-ttl-minutes` and `kubeconfig-default-token-ttl-minutes` to `0` to disable token expiration.

10. Install NFS CSI provisioner

    The NFS provisioner allows automatic creation of PVs and PVCs for NFS storage. 

    ```bash
    helm install csi-driver-nfs csi-driver-nfs \
      --repo https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts \
      --namespace kube-system \
      --version v4.7.0
    ```

11. Install miscellaneous storage class

    It's convienient to have a storage class for general use. Since storage is implemented on a per-cluster basis. You need to edit the following manifest so it fits your environment. The manifest below is configured for the `sys` cluster in the zone `se-flem`.

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: kthcloud-misc
    parameters:
      server: nfs.cloud.cbh.kth.se
      share: /mnt/cloud/apps/sys/misc
    provisioner: nfs.csi.k8s.io
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
    EOF
    ```

12. Setup monitoring
  
    Rancher has built-in monitoring using Prometheus and Grafana. To enable monitoring, you need to install the monitoring stack. Go to the cluster in Rancher then `Apps > Charts` and install `Monitoring`.
    
    Bonus points if you use the misc storage class you created in the previous step!

13. Install Loki
  
    Loki is used to collect logs from the cluster. It requries S3 storage, which you need to configure. The example below uses the S3 endpoint from MinIO in zone `se-flem`.

    ```bash
    helm upgrade --install loki loki \
      --repo https://grafana.github.io/helm-charts \
      --namespace loki \
      --create-namespace \
      --values - <<EOF
      loki:
        auth_enabled: false
        commonConfig:
          replication_factor: 1
        storage:
          type: 's3'
          bucketNames:
            chunks: loki-chunks
            ruler: loki-ruler
            admin: loki-admin
          s3:
            endpoint: ${S3_ENDPOINT}
            region: us-east-1
            secretAccessKey: ${LOKI_S3_SECRET_KEY}
            accessKeyId: ${LOKI_S3_ACCESS_KEY}
            s3ForcePathStyle: true
            insecure: false
            
        schemaConfig:
          configs:
          - from: 2024-01-01
            store: tsdb
            index:
              prefix: loki_index_
              period: 24h
            object_store: filesystem
            schema: v13
      read:
        replicas: 1
      backend:
        replicas: 1
      write:
        replicas: 1
    EOF
    ```

14. Install Harbor

    Harbor is used to store container images. It is setup up with a pre-existing PVC that points it its data.
    The example below is configured for the `sys` cluster in the zone `se-flem`.

    Start by creating a PV and PVC for the Harbor data:
    ```bash
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Namespace
    metadata:
      name: harbor
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv-harbor
    spec:
      storageClassName: kthcloud-manual
      capacity:
        storage: 100Gi
      accessModes:
        - ReadWriteMany
      nfs:
        path: ${CLUSTER_NFS_PATH}/harbor2/data
        server: ${NFS_SERVER}
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: pvc-harbor
      namespace: harbor
    spec:
      storageClassName: kthcloud-manual
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 100Gi
    EOF
    ```

    Then create install Harbor using Helm. Version v1.10.0 (Harbor version 2.6.0)
    ```bash
    helm upgrade --install harbor harbor \
      --repo https://helm.goharbor.io \
      --version v1.10.0 \
      --namespace harbor \
      --create-namespace \
      --values - <<EOF
    expose:
      type: ingress
      tls:
        enabled: false
      ingress:
        hosts:
          core: registry-beta.${DOMAIN}
        controller: default
        className: nginx
    externalURL: https://registry-beta.${DOMAIN}
    persistence:
      enabled: true
      resourcePolicy: keep
      persistentVolumeClaim:
        registry:
          existingClaim: pvc-harbor
          subPath: registry
          storageClass: "kthcloud-manual"
          accessMode: ReadWriteMany
        jobservice:
          jobLog:
            existingClaim: pvc-harbor
            subPath: job_logs
            storageClass: "kthcloud-manual"
            accessMode: ReadWriteMany
        database:
          existingClaim: pvc-harbor
          subPath: database
          storageClass: "kthcloud-manual"
          accessMode: ReadWriteMany
        redis:
          existingClaim: pvc-harbor
          subPath: redis
          storageClass: "kthcloud-manual"
          accessMode: ReadWriteMany
        trivy:
          existingClaim: pvc-harbor
          subPath: trivy
          storageClass: "kthcloud-manual"
          accessMode: ReadWriteMany
      imageChartStorage:
        type: filesystem
    database:
      internal:
        password: harbor
    metrics:
      enabled: true
      core:
        path: /metrics
        port: 8001
      registry:
        path: /metrics
        port: 8001
      jobservice:
        path: /metrics
        port: 8001
      exporter:
        path: /metrics
        port: 8001
    EOF
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

1. Log in [Rancher](https://mgmt.cloud.cbh.kth.se)
2. Navigate to `Cluster Management` -> `Create` and select `Custom`
3. Fill in the required details for your cluster, such as automatic snapshots.
4. Make sure to **untick** both `NGINX Ingress` and `Metrics Server` as they will be installed later.
5. Click `Create` and wait for the cluster to be created.
6. Deploy your node by following [Host provisioning guide](/maintenance/hostProvisioning.md).\
Remember to use the API key you created in step 4 when creating the cloud-init script.

### Aquire API token
If this is the first deploy cluster for the Rancher setup, you need to create an API key to use when creating the cluster. The API key ise used to automatically add the new cluster node to the cluster. If you have already created a cluster, you probably already have an API key in the `admin` repo in the `cloud-init` settings. 

1. Click on the profile icon in the top right corner and select `Account & API Keys`.
2. Create an API key that does not expire and save the key.\
It will be used when creating cloud-init scripts for nodes connecting to the cluster.

### Install required services
If you are deploying the first node in the cluster, you should follow the steps below. These steps assumes that every previous step has been completed.
Make sure that the cluster you are deploying have atleast one node for each role (control-plane, etcd, and worker). 

1. Set envs:
    ```bash
    # The root domain for your certificates. 
    # For example: cloud.cbh.kth.se if you want to issue certificates for:
    # - *.app.cloud.cbh.kth.se
    # - *.vm-app.cloud.cbh.kth.se
    # - *.storage.cloud.cbh.kth.se
    export DOMAIN=
    # API URL to the PDNS instance http://172.31.1.68:8081
    export PDNS_API_URL=
    # API key for the PDNS instance (base64 encoded)
    export PDNS_API_KEY=
    # IP_POOL for MetalLB, for example 172.31.50.100-172.31.50.150
    export IP_POOL=
    # NFS server for the storage classes, for example nfs.cloud.cbh.kth.se
    export NFS_SERVER=
    # Path to the deploy service, for example /mnt/cloud/apps/sys/deploy
    export DEPLOY_NFS_PATH=
    # Path to the cluster storage, for example /mnt/cloud/apps/se-flem-2-deploy
    export CLUSTER_NFS_PATH=
    ```

2. Install `Ingress-NGINX`
    ```bash
    helm upgrade --install ingress-nginx ingress-nginx \
      --repo https://kubernetes.github.io/ingress-nginx \
      --namespace ingress-nginx \
      --create-namespace \
      --values - <<EOF
    controller:
      ingressClassResource:
        default: "true"
      config:
        allow-snippet-annotations: "true"
        proxy-buffering: "on"
        proxy-buffers: 4 "512k"
        proxy-buffer-size: "256k"
    defaultBackend:
      enabled: true
      name: default-backend
      image:
        repository: dvdblk/custom-default-backend
        tag: "latest"
        pullPolicy: Always
      port: 8080
      extraVolumeMounts:
        - name: tmp
          mountPath: /tmp
      extraVolumes:
        - name: tmp
          emptyDir: {}
    EOF
    ```

3. Install `cert-manager`
    ```bash
    helm upgrade --install \
      cert-manager \
      cert-manager \
      --repo https://charts.jetstack.io \
      --namespace cert-manager \
      --create-namespace \
      --version v1.12.0 \
      --set 'extraArgs={--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}' \
      --set installCRDs=true
    ```

4. Install cert-manager Webhook for DNS challenges

    kthcloud uses PowerDNS for DNS management, so we need to install the cert-manager-webhook for PowerDNS.

    ```bash
    helm install cert-manager-webhook-powerdns-domain-1 cert-manager-webhook-powerdns \
      --repo https://lordofsystem.github.io/cert-manager-webhook-powerdns \
      --namespace cert-manager \
      --set groupName=${DOMAIN}
    ```

5. Install cert-manager issuer

    Now that we have the webhook installed, we need to install the issuer that will use the webhook to issue certificates.

    Create the PDNS secret (or any other DNS provider secret)
    ```bash
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
    ```bash
    kubectl apply -f - <<EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: deploy-cluster-issuer
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
    ```bash
    kubectl apply -f - <<EOF
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: deploy-wildcard
      namespace: ingress-nginx
    spec:
      secretName: deploy-wildcard-secret
      secretTemplate:
        labels:
          # This should match with the settings in go-deploy
          app.kubernetes.io/deploy-name: deploy-wildcard-secret
      issuerRef: 
        kind: ClusterIssuer
        name: deploy-cluster-issuer
      commonName: ""
      dnsNames:
        - "*.app.${DOMAIN}"
        - "*.vm-app.${DOMAIN}"
        - "*.storage.${DOMAIN}"
    EOF
    ```

    Create a fallback ingress so a certificate does not need to be specified on all ingresses
    ```bash
    kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: fallback-ingress
      namespace: ingress-nginx
    spec:
      ingressClassName: nginx
      tls:
      - hosts:
        - "*.app.cloud.cbh.kth.se"
        - "*.vm-app.cloud.cbh.kth.se"
        - "*.storage.cloud.cbh.kth.se"
        secretName: deploy-wildcard-secret
      rules:
      - host: "*.app.cloud.cbh.kth.se"
      - host: "*.vm-app.cloud.cbh.kth.se"
      - host: "*.storage.cloud.cbh.kth.se"
    EOF
    ```

6. Install `MetalLB`
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

    Add `metallb.universe.tf/allow-shared-ip: go-deploy` to Ingress-NGINX service to allow MetalLB to use the IP for VMs.
    Use Rancher GUI or edit the manifest directly or use the following command:
    ```bash
    kubectl edit svc -n ingress-nginx ingress-nginx-controller
    ```

7. Install `metrics-server`
    ```bash
    helm upgrade --install metrics-server metrics-server \
      --repo https://kubernetes-sigs.github.io/metrics-server \
      --namespace kube-system \
      --create-namespace    
    ```

8. Install `hairpin-proxy`

    Hairpin-proxy is a proxy that allows us to access services in the cluster from within the cluster. This is needed for the webhook to be able to access the cert-manager service when validating DNS challenges.

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/JarvusInnovations/hairpin-proxy/v0.3.0/deploy.yml
    ```

    Edit the created `hairpin-proxy-controller` deployment in the `hairpin-proxy` namespace using Rancher or:
    ```bash
    kubectl edit deployment hairpin-proxy-controller -n hairpin-proxy
    ````
    Change the environment variables to be the following:
    ```yaml
    - name: COREDNS_CONFIGMAP_NAME
      value: rke2-coredns-rke2-coredns
    - name: COREDNS_IMPORT_CONFIG
      value: 'false'
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

10. Install NFS CSI provisioner

    The NFS provisioner allows automatic creation of PVs and PVCs for NFS storage. This is used for the VM disks and scratch space.

    ```bash
    helm install csi-driver-nfs csi-driver-nfs \
      --repo https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts \
      --namespace kube-system \
      --version v4.7.0
    ```

11. Install required storage classes

    This step is only necessary if you installed KubeVirt in the previous step. The storage classes are used to define the storage that the VMs will use, and uses 2 storage classes for different purposes. User storage does not use a storage class and instead manually creates PV and PVCs (so it needs to be configured in the configuration later on).

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: deploy-vm-disks
    parameters:
      server: ${NFS_SERVER}
      share: ${DEPLOY_NFS_PATH}/vms/disks
    provisioner: nfs.csi.k8s.io
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
    EOF
    ```

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: deploy-vm-scratch
    parameters:
      server: ${NFS_SERVER}
      share: ${DEPLOY_NFS_PATH}/vms/scratch
    provisioner: nfs.csi.k8s.io
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
    EOF
    ```

12. Install miscellaneous storage class

    It's convienient to have a storage class for general use. Since storage is implemented on a per-cluster basis. You need to edit the following manifest so it fits your environment. The manifest below is configured for the `se-flem-2-deploy` cluster in the zone `se-flem`.

    ```bash
    kubectl apply -f - <<EOF
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: kthcloud-misc
    parameters:
      server: ${NFS_SERVER}
      share: ${CLUSTER_NFS_PATH}/misc
    provisioner: nfs.csi.k8s.io
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
    EOF
    ```

13. Setup monitoring

    Rancher has built-in monitoring using Prometheus and Grafana. To enable monitoring, you need to install the monitoring stack. Go to the cluster in Rancher then `Apps > Charts` and install `Monitoring`.

    Bonus points if you use the misc storage class you created in the previous step!

14. Edit the `CDI` installation to use the scratch space storage classes

    This step is only necessary if you installed KubeVirt in the previous step. The CDI operator uses the scratch space storage class to store temporary data when importing VMs.

    Edit the CDI instance in the `cdi` namespace using Rancher or the following command:
    ```bash
    kubectl edit cdi cdi -n cdi
    ```

    Change the `scratchSpaceStorageClass` to `deploy-vm-scratch`
    ```yaml
    spec:
      config:
        scratchSpaceStorageClass: deploy-vm-scratch
    ```

15. Install `Velero`

    **This step is currently WIP. You can skip this step for now.**

    Velero is a backup and restore tool for Kubernetes. It is used to backup the cluster in case of a disaster. Keep in mind that it does NOT backup persistent volumes in this configuration, but only the cluster state that points to the volumes. This means that the volumes must be backed up separately (either by the application using them or our TrueNAS storage solution).
    *Note: You will need the Velero CLI to use Velero commands. You can download it from the [Velero releases page](https://velero.io/docs/v1.8/basic-install)*

    Start by creating a bucket for Velero in [MinIO](https://minio.cloud.cbh.kth.se). The bucket will be used for all the files that Velero backs up.

    Set the following envs
    ```bash
    export S3_ENDPOINT="https://minio.cloud.cbh.kth.se"
    export S3_BUCKET_NAME="velero-se-flem-deploy-2"
    export S3_KEY=""
    export S3_SECRET=""
    ```

    Install Velero using Helm
    ```bash
    helm upgrade --install velero velero \
      --repo https://vmware-tanzu.github.io/helm-charts \
      --namespace velero \
      --create-namespace \
      --set backupsEnabled=true \
      --set snapshotsEnabled=false \
      --set configuration.backupStorageLocation[0].name=default \
      --set configuration.backupStorageLocation[0].provider=aws \
      --set configuration.backupStorageLocation[0].bucket=$S3_BUCKET_NAME \
      --set configuration.backupStorageLocation[0].credential.name=cloud \
      --set configuration.backupStorageLocation[0].credential.key=cloud \
      --set configuration.backupStorageLocation[0].config.region=minio \
      --set configuration.backupStorageLocation[0].config.s3ForcePathStyle=true \
      --set configuration.backupStorageLocation[0].config.s3Url=$S3_ENDPOINT \
      --set configuration.backupStorageLocation[0].config.publicUrl=$S3_ENDPOINT \
      --set credentials.useSecret=true \
      --set credentials.name=cloud \
      --set credentials.secretContents.cloud="[default]\naws_access_key_id=$S3_KEY\naws_secret_access_key=$S3_SECRET"
    ```

### Next steps

Finally, to make the cluster available to users, you need to configure the `go-deploy` service to use the new cluster. This is done by adding the cluster to the `go-deploy` configuration. You can find the development version of the configuration in the `admin` repository and the production version in [kthcloud Drive](https://drive.cloud.cbh.kth.se) under `apps/sys/deploy/config`.