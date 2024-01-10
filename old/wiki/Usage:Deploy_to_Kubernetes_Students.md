<span id="introduction"></span>

## Introduction

Deploying to Kubernetes is a way of managing applications. It is
essentially just a computer running your code, but in a much more
scalable manner.

In order to deploy your application to Kubernetes you should first
understand the principle of working with Docker images. In order to be
able to host any kind of app, Kubernetes runs Docker images. This is
just a standardized way of packaging virtually any kind of application,
much like a container on a cargo ship. 

In kthcloud, a Kubernetes cluster is dedicated for your application.
However, this cluster must know where your image exists, since it does
not store images itself. Therefore, your image must be pushed to a
storage called *registry* before you can create your application in
Kubernetes. See Image below.

[960x540px| (png)](/File:Without-github_large.png "wikilink")

The next step is to automate the image building process through Actions
in GitHub. This just adds an extra step in the pipeline.

[960x540px| (png)](/File:With-github_large.png "wikilink")

<span id="requirements"></span>

### Requirements

\- Docker installed locally
You must be able to use it in your command line

\- Know your group name and credentials (given by teacher)

\- Harbor robot account to authenticate to the Docker registry (given by
teacher)

<span id="examples"></span>

### Examples

|          |                                                      |
| -------- | ---------------------------------------------------- |
| Frontend | <https://github.com/Makerspace-KTH/frontend-example> |
| Api 1    | <https://github.com/Makerspace-KTH/api1-example>     |
| Api 2    | <https://github.com/Makerspace-KTH/api2-example>     |

<span id="your-public-urls"></span>

### Your public URLs

Each of your application will receive a public URL.

Frontend: *<group name>.dev.kthcloud.com* (<span>for example
data2.dev.kthcloud.com</span>)

Backends: api\<1-5\>.<group name>.kthcloud.com (for example
api2.data4.dev.kthcloud.com)

<span id="start-by-building-an-image-locally"></span>

## Start by building an image locally

<span id="create-your-dockerfile"></span>

### 1\. Create your Dockerfile

Start by creating a file called Dockerfile in your app directory, and
add the instructions for how to build your Docker image.  

<span id="build-your-image"></span>

### 2\. Build your image

Building your image might require you to edit things such as environment
variables in order for your app to work with your public URLs. Do not
try to proceed this step before your image is building. 

Open a terminal and navigate to your app directory and run:

*docker build ./ -t registry.kthcloud.com/ht2022/<group name>-<app>*

<span id="authenticate-to-the-registry"></span>

### 3\. Authenticate to the registry

Use the credentials supplied by your teacher, such as *robot$...* and a
long password

*docker login registry.kthcloud.com*

<span id="push-to-the-docker-registry"></span>

### 4\. Push to the Docker registry

*docker push registry.kthcloud.com/data-ht2022/<group name>-<app>*

<span id="create-your-app-in-kubernetes"></span>

## Create your app in Kubernetes

<span id="login-to-the-kubernetes-dashboard"></span>

### 1\. Login to the Kubernetes dashboard

Go to ''''<https://k8s.dev.kthcloud.com/> and sign in with your group
credentials. 

Go to your group's namespace by clicking the drop-down menu in the
top-left corner.

<span id="fill-in-the-app-form"></span>

### 2\. Fill in the app form

Click the '+' in the top-right corner and go the form. The name must be
according to the standard below.

<span id="app-name"></span>

#### App name

Frontend: *frontend*

Backends: *ap1,* *api2*, *api3* or *api4*

<span id="container-image"></span>

#### Container image

registry.kthcloud.com/ht2022/*<group name>-<app>*

<span id="number-of-pods"></span>

#### Number of pods

1

<span id="service"></span>

#### Service

Internal with *Port* 8080 and *Target port* should be your app's port

**Advanced settings**

\- Namespace

Select your group's namespace

[730x475px| (png)](/File:K8s-fill-form_large.png "wikilink")

<span id="verify-that-a-deployment-and-service-is-created"></span>

### 3\. Verify that a deployment and service is created

[454x287px|
(png)](/File:k8s-check-deployment-status_large.png "wikilink")

<span id="try-to-access-your-app-through-your-public-url"></span>

### 4\. Try to access your app through your public URL

<span id="section"></span>

##

<span id="setup-automation-using-github-actions"></span>

## Setup automation using GitHub Actions

<span id="setup-secrets-in-your-repository"></span>

### 1\. Setup secrets in your repository

Go to your GitHub repository's settings, and navigate
to *Secrets/Actions*

Create two secrets called *DOCKER_USERNAME* and *DOCKER_PASSWORD* and
supply the robot account credentials you logged in with before
using *docker login*.

[803x650px| (png)](/File:gh-view-secrets_large.png "wikilink")

<span id="create-a-workflow"></span>

### 2\. Create a workflow

Go to the *Actions* tab in your repository and create workflow by
clicking *set up a workflow yourself*

Remember to use your secrets in your workflow\! 

*[417x138px|
(png)](/File:gh-click-create-workflow_large.png "wikilink")*

Either inspect the example applications or do your own research how to
create a workflow that builds a Docker image.

<span id="make-sure-your-workflow-passes"></span>

### 3\. Make sure your workflow passes

If your workflow failed, you can click on it to reveal the logs.

[1000x264px| (png)](/File:gh-check-workflow-result_large.png "wikilink")

<span id="tips-and-tricks"></span>

## Tips and tricks

<span id="apply-changes"></span>

### Apply changes

Every time you push new code to your repository, a Docker image will be
created. However, Kubernetes will **not** automatically fetch this new
image. You need to manually go to the Kubernetes dashboard and restart
the deployment. 

[599x498px| (png)](/File:k8s-restart-deployment_large.png "wikilink")