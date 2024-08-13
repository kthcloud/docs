---
title: MAIA
---

# MAIA

MAIA is a Medical AI Platform, designed to be a scalable, secure and easy-to-use platform for developing, deploying and managing AI models in a clinical setting. It is built on top of Kubernetes and leverages the power of the cloud to provide a scalable and secure platform for AI in healthcare.

MAIA is designed as a federation of clusters, where each cluster is a separate Kubernetes cluster. Each cluster can be located in a different geographical location, and can be managed by a different organization. This allows MAIA to be used in a wide range of settings, from small clinics to large hospitals and research institutions.

Each Kubernetes cluster in MAIA is managed by a central control plane (based on [Karmada](https://karmada.io)), which provides a unified interface for managing the clusters. In addition, MAIA users can access the platform only through the central control plane, providing a secure isolation and access control to the underlying clusters.

The single MAIA clusters are based on [Kaapana](https://www.kaapana.ai/), which is a Kubernetes-based platform for providing open-source toolkits for AI in healthcare. Kaapana provides a set of tools for developing, deploying and managing AI models, and is designed to be easy to use and integrate with existing clinical workflows.

To start up a MAIA cluster, follow the instructions in the [Start Single MAIA Cluster](MAIA/start_maia_cluster.md) section.

After following and completing the instructions in the [Start Single MAIA Cluster](MAIA/start_maia_cluster.md) section, you will have a running MAIA cluster, and you can start configuring it ([Configure MAIA Cluster](MAIA/configure_maia_cluster.md)) to support different cluster features and applications.

More information about User Registration in MAIA can be found in the [MAIA User Registration](MAIA/User_Registration.md) section.


