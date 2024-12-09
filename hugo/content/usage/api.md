---
title: API
---

# Using kthcloud via API
kthcloud published various REST APIs to interact with. Here are the main services and their respective API documentation.


## Accessing the API
You'll need an API key to access the APIs. Create one on the Profile page on [kthcloud](https://cloud.cbh.kth.se/profile).

<br/>

## go-deploy 
The go-deploy project is the main service behind kthcloud. It is responsible for deploying and managing the lifecycle of resources.

### REST API Docs 
- https://api.cloud.cbh.kth.se/deploy/v2/docs/index.html
- https://api.cloud.cbh.kth.se/deploy/v1/docs/index.html

### Python SDK
We publish a Python SDK to simplify scripting and automation. The SDK is available on PyPi and can be installed using pip.

```bash
pip install kthcloud
```

Learn more in the [examples](https://github.com/kthcloud/showcase/tree/main/scripts).


## sys-api
The sys-api provides information about the physical hosts, such as sensor readouts and capacity.

### REST API Docs
- https://api.cloud.cbh.kth.se/landing/v2/docs/index.html
