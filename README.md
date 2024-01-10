# 📖 kthcloud/docs <img src=https://github.com/tillitis/dev-tillitis/actions/workflows/deploy.yaml/badge.svg >

This repository contains all the code and content for kthcloud's documentation. It uses [Hugo](https://gohugo.io/), and this repository is inspired by [dev-tillitis](https://github.com/tillitis/dev-tillitis). 

The documenation is automatically built on every push, and it deployed to [https://docs.cloud.cbh.kth.se](https://docs.cloud.cbh.kth.se).

## Try locally

You need to install [Hugo](https://gohugo.io/) before using it to generate a Hugo website.

After that you can run the documentaion locally.
```
cd hugo
hugo server
...
Web Server is available at http://localhost:1313/ 
...
```

## Make edits
All the documentation content and all images are available under `hugo/content`. 

Fork it, change it, and make a PR!

### Example

You: "I want to add new documentation related to usage!"

1. Go to `hugo/content/usage`
2. Create a file: `camelCase.md`
3. Make sure it looks good by starting the server locally


If you find that you name gets intepreted incorrectly (Hugo tries to put spaces between the words in your filename), you can overwrite it using the following config in the top of your document.
```yaml
---
title: My Overwritten Name
weight: 2 # Order in the list
---
```
