---
title: Stop user registration
---

# Stop user registration 

For some reason, you may want to temporarily disable new user registrations from kthcloud. This is how it was done last time it was needed.

### 1. Log into the kthcloud iam https://iam.cloud.cbh.kth.se/ admin panel

<img src="../../images/cbhcloud-realm.png" height="300px">

### 2. Visit the identity provider section, and click on the Login with KTH option

<img src="../../images/idp-kth.png" height="400px">

### 3. Scroll down to Advanced settings, First login flow override, and select the `deny new users` flow.

<img src="../../images/idp-flow.png" height="400px">

### Editing flows 
The flows can be edited in keycloak admin panel's `Authentication` tab.

The default `first broker login` flow should be used when you want to allow new users to register again.


## Announcing the registration pause
Please alert users of the change by posting a message on kthcloud's Mastodon and Bluesky accounts, as well as creating an alert on https://github.com/kthcloud/alert

