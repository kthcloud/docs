## Navigate to kthcloud Docker registry

Navigate to the [kthcloud Docker
registry](https://registry.cloud.cbh.kth.se).

## Click LOGIN VIA OIDC PROVIDER and enter your admin credentials

Click **LOGIN VIA OIDC PROVIDER** and enter your admin credentials.

## Navigate to your project

Navigate to your project.

[284px|thumb| (png)](/File:harbor-click-project.png "wikilink")

## Navigate to Robot Accounts and press + New Robot Account

Navigate to **Robot Accounts** and press **+ New Robot Account**.

[857px|thumb| (png)](/File:harbor-add-robot-account.png "wikilink")

## Fill in the fields

Name: Should describe the intent behind the account, for example *ci*
for push from a GitHub action file. Expiration time: Should be a
reasonable expiration time. Description: Optional, fill in if using
multiple Robot Accounts. Permissions: Reasonable permission level based
on the account's intent. [602px|thumb|
(png)](/File:harbor-create-robot-account-form.png "wikilink")

## The last step displays the account information

Name: The actual login username. Note that this is different from the
*Name* in the previous step. Secret: The account's password.
[884px|thumb| (png)](/File:harbor-view-secret.png "wikilink")