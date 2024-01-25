<hr style="width:100%;text-align:left;margin-left:0">

<b>DEPRRECATED</b> This page is not maintained, but is kept for archival
purposes.

<hr style="width:100%;text-align:left;margin-left:0">


<span id="prerequisites"></span>

### Prerequisites

  - Docker installed on your local machine
  - Docker Hub account or Harbor Robot account (an admin can create
    an *Harbor Robot Account*, see [Add Harbor robot
    accounts](https://www.kth.se/social/group/kth-cloud/page/add-harbor-robot-accounts/)).
    **NOTE**: A Harbor Robot Account is created per application\!
  - Determine which cluster to deploy to:
      - System: Internal apps, such as Keycloak
      - Development: Apps in development, staging apps, student apps
      - Production: Production-ready apps

<span id="dashboard-url"></span>

#### Dashboard URL

  - System: https://k8s.cloud.cbh.kth.se
  - Development: https://k8s.dev.cloud.cbh.kth.se
  - Production: https://k8s.prod.cloud.cbh.kth.se

<span id="create-your-docker-image"></span>

### Create Your Docker image

<span id="build-and-tag-your-docker-image-assuming-working-directory-contains-your-dockerfile"></span>

#### 1\. Build and tag your Docker image (assuming working directory contains your Dockerfile)

''''''docker build . -t <my docker account>/<my docker image>
or
docker build . -t registry.cloud.cbh.kth.se/<my project>/<my image>

<span id="login-in-to-the-registry"></span>

#### **2. Login in to the registry**

docker login
or
docker login registry.cloud.cbh.kth.se *(Use your Harbor Robot account)*

<span id="push-your-image-to-the-registry"></span>

#### 3\. Push your image to the registry

docker push <Docker Hub repo>/<my image>
or
docker push registry.cloud.cbh.kth.se/<my project>/<my image>

<span id="create-your-namespace"></span>

### **Create your namespace**

1\. Go to the dashboard and navigate to the "+" in the top right corner

[create-deployment-button](/File:Plus.png "wikilink")

2\. Add the following after substituting your desired name for the
namespace. Ideally it should be the same as your app name.

apiVersion: v1
kind: Namespace
metadata:
    name: *<namespace name>*

3\. Click *Upload*

<span id="only-if-you-are-using-a-private-harbor-repository-create-your-image-pull-secret"></span>

### \[Only if you are using a private Harbor repository\]
Create your image pull secret

If you chose to use kthcloud Docker registry, and a <span>private</span>
repository, you must add a *image pull secret* in Kubernetes.

1\. Make sure you are logged in with the Harbor robot account with
access to the repository (this should have been done by following the
steps above)

2\. Copy the contents of your *.docker/json* file. This is usually
located in your home directory. (/home/<username> or
C:\\users\\<username>)

3. [Encode it with Base64](https://www.base64encode.org/)  and copy the
result

<span>4. Go to the dashboard and navigate to the "+" in the top right
corner</span>

[create-deployment-button](/File:Plus.png "wikilink")

5\. Edit the following template and then click *Upload*.

kind: Secret
apiVersion: v1
metadata:
    name: **<my secret name>**
    namespace: **<my namespace>**
data:
    .dockerconfigjson: **<Base64 encoded result>**
type: kubernetes.io/dockerconfigjson

<span id="only-if-your-apps-requires-public-access-setup-external-access"></span>

### \[Only if your apps requires public access\]
Setup external access 

If your app needs external access, such as a frontend or backend app, a
route through the DNS and proxy manager must be set up. 

1\. Add an entry in the DNS by following [this
guide](https://www.kth.se/social/group/kth-cloud/page/create-dns-entry/)

2\. Setup a proxy host in the proxy manager following [this
guide](https://www.kth.se/social/group/kth-cloud/page/create-route-in-nginx-proxy-manager/).
Remember when adding the internal address to use the address
<app name>.<namespace>.svc.cluster.local. This is fine to do in advance,
since you probably know what your app will be called, and what port will
be used.

<span id="create-your-app"></span>

### Create your app

''''''This guide will assume your are using the built-in form. However,
this is only recommended for simple web apps.
Deploying a database, setting up persistent storage etc. should be done
using a deployment yaml-file (aka. manifest).

However, since this require a bit more Kubernetes knowledge, the reader
is expected to learn it on its own. 

1\. Select your namespace in the top left corner

2. <span>Go to the dashboard, navigate to the "+" in the top right
corner</span> and click on *Create from form*

[create-deployment-button](/File:Plus.png "wikilink")

3\. Fill in the meta data about your app.

If you added external access earlier, select *Internal Service* expose
the ports you selected in the the Nginx Proxy Manager

4\. Click *Show Advanced Options* and select your namespace (even if you
selected the namespace in step 1) 

[create-deployment](/File:Advanced.png "wikilink")

\[Only if you are using a private Harbor repository\]
5\. Select image pull secret 

Select the secret under *Image Pull Secret* under *Show Advanced
options*

[image-pull-secret](/File:Pull-secret.png "wikilink")

6\. Click *Deploy*