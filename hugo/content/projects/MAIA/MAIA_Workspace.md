# MAIA Workspace

After receiving a request to register a new MAIA Workspace, generate the corresponding form in YAML format:

```yaml
namespace_hub_address: <GROUP_NAME> # To change if needed for a different subdomain
group_ID: <GROUP_NAME> # Group ID in Keycloak: MAIA:<GROUP_NAME>
maia_workspace_version: 2.0 # MAIA Workspace version, according to the official Docker Registry Image Tag
users: [] # List of users
resources_limits: # Resource (Memory and CPU) limits for the MAIA Workspace
  "memory":
    - "1G"
    - "2G"
  "cpu":
    - 1.0
    - 1.0
gpu_request: 1 # Optional flag to request GPU support in the MAIA Workspace. Unset if not needed.
```

## Namespace Creation

```bash
kubectl create namespace <namespace>
```
To be able to pull images from the MAIA Docker Registry, you need to create a secret in the namespace. The secret is created using the following command:
 
```bash
kubectl create secret docker-registry maia-docker-registry-secret --docker-username=<registry_username> --docker-server=<registry_url> --docker-password=<registry_password> -n <namespace>
```

## Shared PVC
To be able to share data between different applications in the MAIA Workspace, you need to create a shared PVC in the namespace.

To create a shared PVC for the MAIA Workspace, you need to create a new PVC in the namespace. The PVC is created using the following command:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared
  namespace: <namespace>
spec:
    accessModes:
        - ReadWriteMany
    resources:
        requests:
        storage: 10Gi
EOF
```


## OAuth2
The OAuth2 Proxy is the first component to be deployed in the MAIA Workspace. The OAuth2 Proxy is used to authenticate users and provide access control to the MAIA Workspace applications.

First create a new OAuth2 Proxy configuration file, `oauth2-proxy-config.yaml`, with the following content:
```yaml
config:
  clientID: "<CLIENT_ID>"
  clientSecret: "<CLIENT_SECRET>"
  cookieSecret: "<RANDOM_COOKIE_SECRET>"
  configFile: |-
    oidc_issuer_url = "<KEYCLOACK_URL>"
    provider = "oidc"
    upstreams = ["static://202"]
    http_address = "0.0.0.0:4180"
    oidc_groups_claim = "groups"
    skip_jwt_bearer_tokens = true
    oidc_email_claim = "email"
    allowed_groups = ["<MAIA_GROUP_ID>","MAIA:admin"]
    scope = "openid profile email"
    redirect_url = "https://<SUBDOMAIN>.<CLUSTER_DOMAIN>/oauth2/callback"
    email_domains = [ "*" ]
redis:
  enabled: true
  global:
    storageClass: <STORAGE_CLASS>
sessionStorage:
  type: redis

image:
  repository: "quay.io/oauth2-proxy/oauth2-proxy"
  # appVersion is used by default
  tag: ""
  pullPolicy: "IfNotPresent"

service:
  type: ClusterIP
  portNumber: 80
  # Protocol set on the service
  appProtocol: https
  annotations: {}
  # foo.io/bar: "true"

## Create or use ServiceAccount
serviceAccount:
  ## Specifies whether a ServiceAccount should be created
  enabled: true
  ## The name of the ServiceAccount to use.
  ## If not set and create is true, a name is generated using the fullname template
  name:
  automountServiceAccountToken: true
  annotations: {}

ingress:
  enabled: true
  # className: nginx
  path: /oauth2
  # Only used if API capabilities (networking.k8s.io/v1) allow it
  pathType: Prefix
  tls:
    - hosts:
        - <SUBDOMAIN>.<CLUSTER_DOMAIN>
      #secretName: admin.app.cloud.cbh.kth.se-tls
  # Used to create an Ingress record.
  hosts:
    - "<SUBDOMAIN>.<CLUSTER_DOMAIN>"
  annotations:
    # For NGINX Ingress Controller
    cert-manager.io/cluster-issuer: <NGINX_CLUSTER_ISSUER>
    # For Traefik
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls.certresolver: <TRAEFIK_RESOLVER>
```
Then deploy the OAuth2 Proxy using the following command:
```bash
helm repo add oauth2-proxy https://oauth2-proxy.github.io/manifests
helm upgrade --install oauth2-proxy -n brain-mre-simulation oauth2-proxy/oauth2-proxy --values oauth2-proxy-config.yaml
```

After successfully deploying the OAuth2 Proxy, add the corresponding URL to the group form:
```yaml
oauth_url: <SUBDOMAIN>.<CLUSTER_DOMAIN>
```

## MinIO
To deploy a MinIO Tenant in the namespace, access the MinIO Operator UI [MinIO Operator](http://console.minio-operator:9090) and create a new Tenant,
setting the Identity Provider to Open ID and linking it to the Keycloak instance. Additionally, disable the TLS and AutoCert in the Security page,
and set the Custom Domain under `Configure` to **https://<SUBDOMAIN>.<CLUSTER_DOMAIN>/minio-console**. 

To grant access to MinIO for the MAIA users in the namespace, create a Policy in the Tenant with the same name as the MAIA group and assign the desired Policy to it.
Additionally, create a new User in the Tenant to generate the Access Key and Secret Key for the MAIA users.

Finally, add the following line to the Secret <TENANT_NAME>-env-configuration:
```
export MINIO_IDENTITY_OPENID_DISPLAY_NAME="MAIA"
```

After successfully deploying MinIO, add the corresponding entries to the group form:
```yaml
minio_console_service: <TENANT_NAME>-console
minio_access_key: <ACCESS_KEY>
minio_secret_key: <ACCESS_SECRET>
```

## MLFlow + MySQL

To deploy MLFlow, together with its MySQL Database, create the two config files ( 1 for MySQL and 1 for MLFlow) and deploy the `MAIAKubeGate_deploy_helm_chart` script:

```json
{
  "namespace": "<NAMESPACE>",
  "chart_name": "mysql-db-v1",
  "docker_image": "mysql",
  "tag": "8.0.28",
  "memory_request": "2Gi",
  "cpu_request": "500m",
  "deployment": true,
  "ports": {
    "mysql": [
      3306
    ]
  },
  "persistent_volume": [
    {
      "mountPath": "/var/lib/mysql",
      "size": "20Gi",
      "access_mode": "ReadWriteMany",
      "pvc_type": "<STORAGE_CLASS>"
    }
  ],
   "env_variables": {
     "MYSQL_ROOT_PASSWORD": "<RANDOM_MYSQL_PASSWORD>",
     "MYSQL_USER": "<MYSQL_USERNAME>",
     "MYSQL_PASSWORD": "<RANDOM_MYSQL_PASSWORD>",
     "MYSQL_DATABASE": "mysql"
  }
}
```


```json
{
  "namespace": "<NAMESPACE>",
  "chart_name": "mlflow-v1",

      "docker_image": "registry.maia.cloud.cbh.kth.se/mlflow",
      "tag": "1.1",
  "memory_request": "2Gi",
  "cpu_request": "500m",
  "allocationTime": "180d",
      "ports": {
      "mlflow": [
        5000
      ]
    },
  "user_secret": [
    "<USER_SECRET>"
  ],
  "user_secret_params": [
    "user",
    "password"
  ],
  "env_variables": {
    "MYSQL_URL": "mysql-db-v1-mkg",
    "MYSQL_PASSWORD": "<MYSQL_PASSWORD>",
    "MYSQL_USER": "<MYSQL_USERNAME>",
    "BUCKET_NAME": "mlflow",
    "BUCKET_PATH": "mlflow",
    "AWS_ACCESS_KEY_ID": "<MINIO_ACCESS_KEY>",
    "AWS_SECRET_ACCESS_KEY": "<MINIO_SECRET_KEY>",
    "MLFLOW_S3_ENDPOINT_URL": "http://minio:80"
  }
}
```
```bash
MAIAKubeGate_deploy_helm_chart --config-file <MYSQL_Config.json>
```
Before deploying MLFlow, create the `mlflow` MinIO bucket and create the MAIA User secret:
```bash
kubectl create secret generic -n <NAMESPACE> <USER_SECRET> --from-literal=user=<USERNAME> --from-literal=password=<RANDOM_PASSWORD>
```
And then:
```bash
MAIAKubeGate_deploy_helm_chart --config-file <MLFlow_Config.json>
```
After successfully deploying MLFlow, add the corresponding entries to the group form:
```yaml
mlflow_service: mlflow-v1-mkg
```
## FileBrowser [Coming Soon]

## MAIA Addons
The MAIA Workspace Hub includes the following addons:
- SSH Access, to allow users to connect to the workspace using SSH.
- Remote Desktop, to allow users to connect to the workspace using a remote desktop client.
- NGINX Proxy, to provide a valid URL for the MinIO Console, MLFlow, KubeFlow and Label Studio.
- Jupyter Proxy, to provide a valid URL for the applications running in the JupyterHub.

To deploy the MAIA Addons:
```bash
MAIAKubeGate_create_MAIA_Addons_config --form <GROUP_FORM> --cluster-config-file <CLUSTER_CONFIG_FILE>
```
and follow the instructions provided from the script. 


## MAIA Workspace Hub [JupyterHub]
The MAIA Workspace Hub is deployed in the selected namespace by using the JupyterHub Helm chart.

To deploy thr MAIA Workspace Hub, run the script:
```bash
MAIAKubeGate_create_jupyterHub_config --form <GROUP_FORM> --cluster-config-file <CLUSTER_CONFIG_FILE>
```
and follow the instructions provided from the script.


## Orthanc + OHIF Viewer
Orthanc is a lightweight, open-source DICOM server that can be used to store and retrieve medical images. The OHIF Viewer is a web-based viewer for medical images that can be used to view and analyze DICOM images stored in Orthanc.

To deploy Orthanc and the OHIF Viewer in the MAIA Workspace, run:

```yaml
helm upgrade --install <NAMESPACE> -n <NAMESPACE> maiakubegate/monai-label-ohif-maia
```

## KubeFlow
KubeFlow is a machine learning toolkit for Kubernetes. It is designed to make it easy to deploy, manage, and scale machine learning models in a Kubernetes cluster.

To deploy KubeFlow in the MAIA Workspace, run:

```bash
export PIPELINE_VERSION=2.2.0
kubectl apply -k "github.com/kubeflow/pipelines/manifests/kustomize/cluster-scoped-resources?ref=$PIPELINE_VERSION"
kubectl wait --for condition=established --timeout=60s crd/applications.app.k8s.io
kubectl apply -k "github.com/kubeflow/pipelines/manifests/kustomize/env/dev?ref=$PIPELINE_VERSION"

```

## Label Studio
Label Studio is a web-based tool for data labeling and annotation. It can be used to create labeled datasets for machine learning models.

To deploy Label Studio in the MAIA Workspace, run:
```bash
helm repo add heartex https://heartexlabs.github.io/charts
helm repo update
helm upgrade --install label-studio -n <NAMESPACE> heartex/label-studio -f <VALUES_FILE>
```
With the following values file:
```yaml
global:
  extraEnvironmentVars:
    LABEL_STUDIO_HOST: https://label-studio.<SUBDOMAIN>.<DOMAIN>
    LOCAL_FILES_SERVING_ENABLED: true
    LABEL_STUDIO_USERNAME: <USERNAME>
    LABEL_STUDIO_PASSWORD: <PASSWORD>
    LABEL_STUDIO_LOCAL_FILES_DOCUMENT_ROOT: /label-studio/data/LabelStudio
    MINIO_STORAGE_ACCESS_KEY: <MINIO_ACCESS_KEY>
    MINIO_STORAGE_SECRET_KEY: <MINIO_SECRET_KEY>
    MINIO_STORAGE_BUCKET_NAME: <BUCKET_NAME>
    MINIO_STORAGE_ENDPOINT: <MINIO_ENDPOINT>
  persistence:
    config:
      volume:
        storageClass: <STORAGE_CLASS>
        existingClaim: shared
app:
  ingress:
    enabled: true
    host: label-studio.<SUBDOMAIN>.<DOMAIN>
    #path: /label-studio
    annotations:
      cert-manager.io/cluster-issuer: <NGINX_CLUSTER_ISSUER>
    tls:
      - hosts:
          - label-studio.<SUBDOMAIN>.<DOMAIN>
        secretName: label-studio.<SUBDOMAIN>.<DOMAIN>-tls
```
