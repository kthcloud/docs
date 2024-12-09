# MAIA Namespace
In MAIA, the namespace is a way to organize and manage resources in a Kubernetes cluster. Namespaces are intended for use in environments with many users spread across multiple teams or projects. Namespaces are a way to divide cluster resources between multiple users (via resource quota).
Namespaces are created on a per-project basis, with each project having its own namespace. The namespace is used to isolate resources, such as pods, services, and deployments, from other projects. This isolation ensures that resources are not shared between projects, which can help prevent conflicts and security issues.
At the same time, namespaces allow users to share resources within a project. For example, a namespace can contain multiple pods, services, and deployments that are all part of the same project. This sharing of resources within a namespace can help reduce duplication and improve resource utilization, promoting project collaboration and efficiency.


## Request a MAIA Workspace
Anyone with a KTH account can request a namespace in the MAIA cluster. To request a namespace, please follow these steps:
1. Go to the [MAIA Registration Webpage](https://maia.cloud.cbh.kth.se/register/) and fill in the required information:
    - **Username**: Your KTH username
    - **Email**: Your KTH email address
    - **Namespace**: The name of the namespace you would like to create, associated with your project
    - **GPU Request**: Optional GPU Model selection (if you need GPU resources)
    - **Project Allocation Until**: The date until which you need the namespace
    - **Conda/Python Environment File**: Optional file to specify the conda environment or the pip packages list you would like to use in the namespace.


