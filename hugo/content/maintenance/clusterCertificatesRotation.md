---
title: "Rotation of cluster certificates"
description: "Rotation of cluster certificates."
---

## Overview

Cluster certificates for both k3s and Rancher have an expiration time of one year from their issuance date. After this period, the certificates need to be renewed to avoid any service disruptions.

## k3s Certificate Expiry

k3s client and server certificates are valid for 365 days from their date of issuance. If certificates are expired or within 90 days of expiring, they are automatically renewed each time k3s starts. Additionally, a Kubernetes warning event with reason `CertificateExpirationWarning` will be generated when a certificate is within 90 days of expiration.

To check the expiration dates of your certificates, run the following command on the k3s server node ( `se-flem-003`):

```bash
k3s certificate check --output table # will work if k3s is updated
```

If you need to manually rotate certificates, you can use the following commands on the same node:

```bash
# Stop k3s
systemctl stop k3s

# Rotate certificates
k3s certificate rotate

# Start k3s
systemctl start k3s
```

**Note:** Restarting k3s will cause downtime for kthcloud and any other services on the `local` cluster, as Kubernetes services will be unavailable during the restart.

For more details, refer to the [k3s certificate documentation](https://docs.k3s.io/cli/certificate).

## Rancher Certificate Expiry

Rancher versions v2.6.3 and above automatically renew the `rancher-webhook` TLS certificate when it is within 30 days or fewer of its expiration date. If you are using Rancher v2.6.2 or earlier, you may need to manually rotate the expired webhook certificate.

To manually rotate the expired webhook certificate, use the following commands:

```bash
kubectl delete secret -n cattle-system cattle-webhook-tls
kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io --ignore-not-found=true rancher.cattle.io
kubectl delete pod -n cattle-system -l app=rancher-webhook
```

For more information, refer to the [Rancher documentation on expired webhook certificate rotation](https://ranchermanager.docs.rancher.com/troubleshooting/other-troubleshooting-tips/expired-webhook-certificate-rotation).
