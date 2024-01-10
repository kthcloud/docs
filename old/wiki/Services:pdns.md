**A DNS recursor (PDNS)**

|                 |   |
| --------------- | - |
| Virtual Machine | x |
| Kubernetes      |   |

|                 |   |
| --------------- | - |
| Virtual Machine |   |
| Kubernetes      | x |

|           |                                                                     |
| --------- | ------------------------------------------------------------------- |
| Update    | Automatically on restart                                            |
| Restart   | Restart the deployment in Kubernetes                                |
| Install   | Create the deployment using the manifest from the Github repository |
| Namespace | keycloak                                                            |

|         |                                |
| ------- | ------------------------------ |
| Website | <https://iam.cloud.cbh.kth.se> |

|                 |                                   |
| --------------- | --------------------------------- |
| Persistent Data | Persistent Database in Kubernetes |

|               |                                                                                                                                           |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Update        | Ssh to the virtual machine Run **sudo systemctl stop pdns** Run **sudo apt update && sudo apt upgrade** Run **sudo systemctl start pdns** |
| Restart       | Ssh to the virtual machine Run **sudo systemctl restart pdns**                                                                            |
| Install       | Follow this guide: <https://computingforgeeks.com/install-powerdns-and-powerdns-admin-on-ubuntu/>                                         |
| Configuration | Edit **/etc/powerdns/pdns.conf** Run **sudo systemctl restart pdns**                                                                      |

|                 |                                            |
| --------------- | ------------------------------------------ |
| Persistent Data | Local MariaDB database (no authentication) |