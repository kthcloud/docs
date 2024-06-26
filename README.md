# 📖 kthcloud/docs <img src=https://github.com/kthcloud/docs/actions/workflows/deploy.yaml/badge.svg >

This repository contains all the code and content for kthcloud's documentation. It is inspired by [dev-tillitis](https://github.com/tillitis/dev-tillitis) and is built using [Hugo](https://gohugo.io/). The documentation is automatically built on every push, and deployed to [https://docs.cloud.cbh.kth.se](https://docs.cloud.cbh.kth.se).

## Try locally

1. Install [Hugo](https://gohugo.io/)
2. Clone the repository with submodules
```
git clone --recurse-submodules https://github.com/kthcloud/docs.git
```
3. Start the server and navigate to the URL in the terminal
```
cd hugo
hugo server
...
Web Server is available at http://localhost:1313/ 
```

## Make edits
All the documentation content and all images are available under `hugo/content`. 

Fork it, change it, and make a PR!

### Example

You: "I want to add new documentation related to usage!"

1. Go to `hugo/content/usage`
2. Create a file: `camelCase.md`
3. Make sure it looks good by starting the server locally


If you find that your name gets interpreted incorrectly (Hugo tries to put spaces between the words in your filename), you can overwrite it using the following config in the top of your document.
```yaml
---
title: My Overwritten Name
weight: 2 # Order in the list
---
```
