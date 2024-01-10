Most of kthcloud resources are managed in GitHub, view [kthcloud on
GitHub](https://github.com/orgs/kthcloud).

|                                                                            |                                                                                                    |        |
| -------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | ------ |
| [landing-frontend](https://github.com/kthcloud/landing-frontend)           | Frontend for the kthcloud landing project (landing page and deploy platform)                       | Public |
| [go-deploy](https://github.com/kthcloud/go-deploy)                         | API for kthcloud deployment platform                                                               | Public |
| [go-deploy-placeholder](https://github.com/kthcloud/go-deploy-placeholder) | Base frontend for go-deploy apps without any code                                                  | Public |
| [sys-api](https://github.com/kthcloud/sys-api)                             | API for kthcloud internal stats such as host status and total containers in use                    | Public |
| [host-api](https://github.com/kthcloud/host-api)                           | API installed locally on each server in kthcloud exposing stats such as CPU usage and temperature  | Public |
| [cicd-manager](https://github.com/kthcloud/cicd-manager)                   | API that simplifies CICD-operations. Right now only supports restarting deployments on Harbor push | Public |
| [wallpaper-of-the-day](https://github.com/kthcloud/wallpaper-of-the-day)   | Frontend that gives kthcloud a nice new wallpaper background every day                             | Public |
| [visualize-frontend](https://github.com/kthcloud/visualize-frontend)       | Frontend for the visualize project (dashboard with live updates from go-deploy)                    | Public |
| [visualize-backend](https://github.com/kthcloud/visualize-backend)         | API for the visualize project                                                                      | Public |
| [llama-proxy](https://github.com/kthcloud/llama-proxy)                     | Simple load-balancer proxy in front of kthcloud LLaMA instances                                    | Public |
| [llama-prefetch](https://github.com/kthcloud/llama-prefetch)               | Service that prepares LLaMa queries for the landing project                                        | Public |

Service Repositories

|                                                                      |                                                                                                              |         |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------- |
| [admin](https://github.com/kthcloud/admin)                           | Stores cloud-init scripts and generic secrets used in kthcloud                                               | Private |
| [ansible-setup-host](https://github.com/kthcloud/ansible-setup-host) | Ansible playbook that is run when a host is provisioned                                                      | Public  |
| [k8s](https://github.com/kthcloud/k8s)                               | Stores K8s manifests that are automatically deployed in the right K8s cluster using Rancher                  | Private |
| [ansible](https://github.com/kthcloud/ansible)                       | Stores ansible playbooks for K8s clusters                                                                    | Private |
| [branding](https://github.com/kthcloud/branding)                     | Stores generic branding resources such as logos                                                              | Private |
| [secd-admin](https://github.com/kthcloud/secd-admin)                 | Stores generics administration resources for the secd project, such as K8s manifests and configuration files | Private |

System Repositories

## Self-hosted runners

We self-host GitHub runners to allow unlimited actions for private
repositories (using a self-hosted runner for public repositories is
security risk, see more
[here](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security))

To use a self-hosted runner in a private repository in the kthcloud
GitHub organization use: `runs-on: self-hosted`