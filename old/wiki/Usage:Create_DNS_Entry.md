<span id="navigate-to-the-gui"></span>

### Navigate to the GUI

Url: https://dns.cloud.cbh.kth.se[](https://dns.cloud.cbh.kth.se/dashboard/)

Click *Sign in using OpenID Connect* and enter your credentials.

<span id="click-on-the-domain-which-you-will-create-a-subdomain-to"></span>

### Click on the domain which you will create a subdomain to

[478x133px| (png)](/File:Pdns-click-domain_large.png "wikilink")

<span id="add-a-cname-record-pointing-to-the-parent-domain"></span>

### Add a CNAME record pointing to the parent domain

Do not create an A record, as this will add redundant IP configuration.
Nginx Proxy Manager will take care of internal redirection.

Remember to click *Save* and then *Apply Changes* in the top right
corner.

[1000x153px| (png)](/File:Pdns-add-record_large.png "wikilink")

Keep in mind the changes might not propagate immediately due to caching,
and changes could take up too a day to be seen.

If you need the change on your device immediately, you could manually
set your DNS server to 130.237.83.246 temporarily.

<span id="tips-and-tricks"></span>

## Tips and tricks

<span id="dns-lookup"></span>

### DNS Lookup

To check if your DNS is working you could https://dns.google/ to request
the different DNS records.