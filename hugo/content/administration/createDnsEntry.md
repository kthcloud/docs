---
title: Create a DNS entry
---

# Create a DNS Entry

### Navigate to the GUI

Url: [https://dns.kthcloud.com](https://dns.kthcloud.com/dashboard/)

Click *Sign in using OpenID Connect* and enter your credentials.

### Click on the domain which you will create a subdomain to

<img src="../../images/pdns_click_domain_large.png" width="85%">

### Add a CNAME record pointing to the parent domain

Do not create an A record, as this will add redundant IP configuration.
Nginx Proxy Manager will take care of internal redirection.

Remember to click *Save* and then *Apply Changes* in the top right
corner.

<img src="../../images/pdns_add_record_large.png" width="85%">

Keep in mind the changes might not propagate immediately due to caching,
and changes could take up too a day to be seen.

If you need the change on your device immediately, you could manually
set your DNS server to 130.237.83.246 temporarily.

## Tips and tricks

### DNS Lookup
To check if your DNS is working you could [https://dns.google](https://dns.google) to request
the different DNS records.