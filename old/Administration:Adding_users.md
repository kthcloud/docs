## Requirements

Python 3.10

## Navigate to the script repo on kthcloud github

Repository link: <https://github.com/kthcloud/scripts>

## Dependencies

pip install -r requirements.txt

## Create

python create.py

\-n, --noGroups

Number of groups to create

\-a, --noApis

Number of API routes per group

\--groupName

Name of the groups, eg. data

\-d, --domain

Name of the domain for the groups to be sub domains to, eg.
dev.kthcloud.com Default: dev.kthcloud.com

Example:

python create.py -n 20 -a 4 -g data

This creates:

20 \* 5 subdomains and proxy hosts called: data1.dev.kthcloud.com,
api1.data1.dev.kthcloud.com ... data20.api4.dev.kthcloud.com 1
certificate including all the domains 20 namespaces in development
cluster in Kubernetes including permissions 20 account in Keycloak and a
list of username/password in the output folder Project in Harbor Docker
registry called ht2022-data Credentials for robot account used for
pushing and pulling to the registry in the output folder

## Delete

Deletes everything that was created using the create script above.

Command: python delete.py

\--certs

Include certs or not (certbot rate limit is harsh, so delete only when
absolutely necessary)

\-g, -groupName

Name of the groups, eg. data

\-d, --domain

Name of the domain for the groups to be sub domains to, eg.
dev.kthcloud.com Default: dev.kthcloud.com