---
title: "Resource: Deployments"
---

# Create a Web app
Deployment is a service type offering hosted Docker containers at
kthcloud. Starting with a repo with a Dockerfile, you can be up and
running in minutes.

## Creating a Deployment

Open the **Create** page with one of these buttons:

<img src="../../images/create_button.png" /> 

<img src="../../images/create_button_small.png" />

#### Name

<img src="../../images/deployment_name.png" />

This is globally unique and will determine your personal URL and how
your app is accessed.  Choose something nice and short, as your users
will see this.

`https://[deployment_name].app.cloud.cbh.kth.se`

The name must follow [RFC 1035](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#rfc-1035-label-names) as it will be used in Kubernetes and as a subdomain.


#### Connect GitHub repository

<img src="../../images/deployment_login_with_github.png" />

kthcloud deployments provide two options for CI/CD. You can either:

-  Connect a GitHub repository and have your code built and deployed automatically when you push to your repo
-  Omit the GitHub repo, and receive configuration for GitHub Actions and Docker CLI

We recommend skipping the GitHub repo and setting up GitHub Actions if you feel comfortable with that, as it will give you more control over your build process.

#### Environment variables

<img src="../../images/deployment_envs.png" />

Environment variables are accessible from inside your app. There is
always one env available: **$PORT**, which indicates which port your app
should listen for HTTP traffic on.

Feel free to set any necessary envs for your app.

#### Persistent storage

<img src="../../images/deployment_storage.png" />

Persistent storage allows your deployment to save state between restarts
and when pushing a new version.

You'll need to provide

  - **Name**: A friendly name to remember what this is for
  - **App path**: The path inside your Docker container, eg
    **/mnt/db_data**
  - **Storage path**: Path inside your kthcloud storage bucket, eg
    **/my_db_data**

Once your deployment is created, you will find a button to **Manage Storage**

<img src="../../images/deployment_manage_storage.png" /> 

Here you can browse your files and create folders. You might have to create the folder structure specified by your container, and restart it for it to work.

<img src="../../images/filebrowser.png" />

#### That's all :)

Any questions? Reach out on our Discord\!

## Access your deployment

Click on your deployment in the resource list shown when logging in

<img src="../../images/deploy_deployment_operations.png" width="50%">

View your deployment by clicking on **Visit page**

Your deployment's page allows you to change envs, create and delete
persistent storage, view logs, get Docker push commands and GitHub
Actions configuration. You can also use it to specify a custom domain.

## FAQ

### I'm lost, are there any examples?

Yes\! We have template repos for:

  - Showcase repo: <https://github.com/kthcloud/showcase>
  - Frontend app: <https://github.com/kthcloud/go-deploy-placeholder>
  - VM proxy: <https://github.com/kthcloud/vm-nginx-proxy>
  - API example: <https://github.com/Makerspace-KTH/api1-example>

### How do I reach my backend deployment from my frontend?

Your deployments are available at
<https://your-deployment-name.app.cloud.cbh.kth.se>. Simply connect your
other deployment to this URL. Please remember that deployments only
support HTTPS through **$PORT**, for other protocols, you should use a
VM.

### Can I use this for a database?

Use persistent storage for your DB data files, to ensure nothing gets
lost. Remember that only HTTPS is available on deployments, so unless
your docker container contains both DB and backend API, you'd be better
off with a VM for the database.

### How do I get my code to the deployment?

Your app is automatically updated whenever you push a Docker image to
our Docker registry.

This can be done in three ways:

  - If you linked a GitHub repo, the code will automatically be built on
    our servers using your Dockerfile when you push to your repo.
  - Using the GitHub actions file, you can create a custom build process
    on GitHub which then pushes to our registry.
  - Using Docker CLI you can manually update the live code.

All necessary config YAML and/or Docker CLI commands are available on
your deployment's page, unless you linked a GitHub repo when creating
it.
