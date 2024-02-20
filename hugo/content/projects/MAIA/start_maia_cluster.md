# Start a Single MAIA Cluster
The foolowing instructions will guide you through the process of starting a single MAIA cluster, based on the [Kaapana](https://www.kaapana.ai/) installation.
For more information about Kaapana, see the [Kaapana documentation](https://kaapana.readthedocs.io/en/latest/index.html).

Kaapana is built on top of MicroK8s, a lightweight Kubernetes distribution that is designed for easy installation and management.

## Server Preparation
The first step is to prepare the server that will host the MAIA cluster. The server should have at least 16GB of RAM and 4 CPU cores, and should be running Ubuntu 20.04.

Additionally, GPU support is recommended for running AI models, and the server should have at least one NVIDIA GPU installed.

To establish a connection with the MAIA federation, the server should be accessible from the internet on port 16443, the default port for the Microk8s API server.

Furthermore, in order to access the applications deployed on the MAIA cluster, through a Kubernetes Ingress, the server should have a public IP address and a corresponding DNS record.

### Run Kaapana pre-installation script
The first step is to run the pre-installation script for Kaapana. This script will install the necessary dependencies and configure the server for running the MAIA cluster.

```bash
git clone https://github.com/kaapana/kaapana.git
```
To customize the microk8s installation you can create a `microk8s-config.yaml` and add the following content:

```yaml
version: 0.2.0
extraCNIEnv:
  IPv4_CLUSTER_CIDR: "<PODS_CIDR>"    # e.g. 10.2.0.0/16
  IPv4_SERVICE_CIDR: "<SERVICE_CIDR>" # e.g. 10.94.0.0/34
extraSANs:
  - "<SECOND_IP_IN_THE_CIDR_RANGE>"   # e.g. 10.94.0.1
  - "<CLUSTER_DOMAIN>"                # e.g. maia.cloud.cbh.kth.se
addons:
  - name: dns

# OPTIONAL: Not needed when creating a cluster to join the MAIA federation, since OIDC authentication will be handled by the federation.
extraKubeAPIServerArgs:               # To enable OIDC authentication
  --oidc-issuer-url: "<OIDC_ISSUER_URL>" 
  --oidc-client-id: "<OIDC_CLIENT_ID>"
  --oidc-username-claim: email
  --oidc-groups-claim: groups
```
Then edit the `kaapana/server-installation/server_installation.sh` script and add the following lines when the `snap install microk8s` command is called:

```bash
function install_microk8s {
    if command -v microk8s &> /dev/null
    then
        echo ""
        echo "${GREEN}microk8s is already installed ...${NC}"
        echo "${GREEN}-> skipping installation ${NC}"
        echo ""
        echo ""
        echo "${GREEN}If you want to start-over use the --uninstall parameter first! ${NC}"
        echo ""
        echo ""
        exit 0
    else
        echo "${YELLOW}microk8s is not installed -> start installation ${NC}"
        dns_check
        
        if [ "$OFFLINE_SNAPS" = "true" ];then
            echo "${YELLOW} -> offline installation! ${NC}"

            echo "${YELLOW}Installing microk8s...${NC}"
            snap_path=$SCRIPT_DIR/microk8s.snap
            assert_path=$SCRIPT_DIR/microk8s.assert
            [ -f $snap_path ] && echo "${GREEN}$snap_path exists ... ${NC}" || (echo "${RED}$snap_path does not exist -> exit ${NC}" && exit 1)
            [ -f $assert_path ] && echo "${GREEN}$assert_path exists ... ${NC}" || (echo "${RED}$assert_path does not exist -> exit ${NC}" && exit 1)
            
            snap ack $assert_path
            snap install --classic $snap_path
            MICROK8S_BASE_IMAGES_TAR_PATH="$SCRIPT_DIR/microk8s_base_images.tar"
            echo "${YELLOW}Start Microk8s image import from $MICROK8S_BASE_IMAGES_TAR_PATH ... ${NC}"
            [ -f $MICROK8S_BASE_IMAGES_TAR_PATH ] && echo "${GREEN}MICROK8S_BASE_IMAGES_TAR exists ... ${NC}" || (echo "${RED}Images tar does not exist -> exit ${NC}" && exit 1)
            echo "${RED}This can take a long time! -> please be patient and wait. ${NC}"
            microk8s.ctr images import $MICROK8S_BASE_IMAGES_TAR_PATH
            echo "${GREEN}Microk8s offline installation done!${NC}"
        else
            echo "${YELLOW}Installing microk8s v$DEFAULT_MICRO_VERSION ...${NC}"
            ## ADD THE FOLLOWING LINES
            mkdir -p /var/snap/microk8s/common/
            cp ~/microk8s-config.yaml /var/snap/microk8s/common/.microk8s.yaml
            ## END OF ADDITION
            snap install microk8s --classic --channel=$DEFAULT_MICRO_VERSION
        fi
```
In addition, set the DEFAULT_MICRO_VERSION to `1.28/stable`:
```bash
DEFAULT_MICRO_VERSION="1.28/stable"
```
Then run the installation script:
```bash
kaapana/server-installation/server_installation.sh
```
To enable the GPU support, run the following command:
```bash
kaapana/server-installation/server_installation.sh -gpu
```

After the installation is complete, the KUBECONFIG file will be available at `/var/snap/microk8s/current/credentials/client.config`. Copy this file to your local machine and set the `KUBECONFIG` environment variable to point to it.

Finally, label the node with the `kubernetes.io/role` label:
```shell
kubectl label node NODE_NAME node-role.kubernetes.io/control-plane=control-plane
kubectl label node NODE_NAME node-role.kubernetes.io/master=master
```
The cluster API server will be available at `https://<PUBLIC_IP>:16443`.