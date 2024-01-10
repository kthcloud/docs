# Managing Apps in Kubernetes

In our Kubernetes cluster, we have adopted a stateless approach to
ensure efficient management and scalability. This page provides a simple
guide on how to manage apps in Kubernetes, emphasizing the goal of
making the cluster completely stateless.

### Repository and Ansible Role

To facilitate app management, we have set up a GitHub repository called
"ansible" with a dedicated folder named "k8s". Within this folder, you
will find an Ansible role named <i>setup-apps.yml</i>. This role plays a
vital role in managing the apps within the Kubernetes cluster.

### Organizing Kubernetes Manifests

The folder <i>ansible/k8s</i> contains subfolders categorized by the
respective clusters; <b>sys</b>, <b>prod</b>, and <b>dev</b>. Each
cluster folder further contains Kubernetes manifests required for that
specific environment, including services, deployments, and persistent
storage etc.

### Manifest Priority

To ensure proper order of operations, each manifest file begins with a
priority value. Lower priority values are applied first. This pattern
guarantees that essential tasks, such as creating persistent volumes
before their claims or setting up namespaces before any associated
resources, are executed in the correct sequence.

### Helm Charts Support

The app management system also supports Helm charts, which can be found
in the <i>k8s/templates/apps/\[sys, prod, dev\]/helm/<helm chart></i>
folder. Helm charts offer a convenient way to package and deploy
applications in Kubernetes.

## App Creation Steps

1\. Add the necessary Kubernetes manifests to the appropriate folder
corresponding to the target cluster. Typically, this includes a
deployment and a service manifest.

2\. If the app requires persistent storage, create a folder within the
NFS share dedicated to the target cluster. This can be done by accessing
the following URL: <https://drive.cloud.cbh.kth.se>.

3\. Once the manifests are in place and the required storage folder is
set up, run the following command from the folder <i>ansible/k8s</i>:

`ansible-playbook -i inventory setup-apps.yml`

4, If this is the first time running the command, it is essential to
install the dependencies by executing the following command:

`ansible-galaxy install -r requirements.yml`