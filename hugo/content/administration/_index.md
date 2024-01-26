---
bookCollapseSection: true
weight: 120
title: Administrator's handbook
---
# Administrator's handbook

Welcome to the kthcloud administrator's handbook. Here you can find some
of the common tasks you will face as an admin, and what some possible
solutions are.

## Announcing news

To communicate with our users, kthcloud has a presence on Mastodon and
Bluesky. The Mastodon account is linked with the Discord server to relay
information to those users.

The outage reports are all AI generated with a fun and creative tone, so
try to keep any manual posts that way too\! A great way to keep the same
vibe is to send your post through ChatGPT or Llama 2.

## Architecture overview
The following images are generated using Google Slides. Find the document
[here](https://docs.google.com/presentation/d/1TVdSmhKcgaDN6ya3vnFJIltLvctDd9UZWXmQFHg1jDA/edit?usp=sharing).
Request edit access by admin if updates are needed.

### Components

<img src="../../images/kthcloud_components.png" width="75%">

### Flow

<img src="../../images/kthcloud_flow.png" width="75%">

### Network
#### IPv4

Current IP allocation, see the up-to-date list in the [firewall](https://fw.cloud.cbh.kth.se).

| IP address        | usage                      |
| ----------------- | -------------------------- |
| 130.237.83.244    | MAIA                       |
| 130.237.83.245/32 | ☁️ kthcloud                |
| 130.237.83.246/32 | ☁️ kthcloud                |
| 130.237.83.247/32 | ☁️ kthcloud                |
| 130.237.83.248/32 | ☁️ kthcloud                |
| 130.237.83.249/32 | ☁️ kthcloud                |
| 130.237.83.251/32 |                            |
| 130.237.83.252/32 |                            |
| 130.237.83.243/32 | kthcloud (Kista Temporary) |
| 130.237.83.242/32 | ☁️ kthcloud                |

<!-- Copy the lines below to append easier -->
<!-- |                   |                            | -->


#### IPv6

We are waiting on a IPv6 block for easier VM networking.