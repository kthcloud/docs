---
title: secd
---

# secd

## About

The secure cluster is a sister project to kthcloud aiming to provide
secured machine learning pipelines for all your research needs.

[Official website](https://secd.app.cloud.cbh.kth.se/)

Relevant contact persons: Reine Bergström \<reineb@kth.se\>

Please see the flowchart below before getting started.

<img src="../../images/secd_overview.png" width="100%">

### Abstract

In the shifting sand that is machine learning research, there is an
ongoing balancing act between keeping sensitive data and optimizing
workflow. As the AI gold rush is in full force, the demand for secure
and efficient workflows has been steadily increasing. Today, workflows
are often based on either too restrictive practices that worsen the
quality of research, e.g. complicated policies designed for large
corporations with dedicated teams, or forgo the security aspect
altogether, breaking regulations and the trust of data owners. This
paper addresses ways to conduct machine learning training on real
medical records in a safe environment. The result of the project is a
prototype implementation of a secure workflow with a custom code runner
which facilitates machine learning projects that use sensitive data
while ensuring secure data storage. Field expert interviews provided
insights into the workflow's effectiveness, highlighting the trade-offs
between security and usability, and the need for future enhancements to
address potential data leakage issues.

Read the full
[paper](https://secd.app.cloud.cbh.kth.se/media/secd-paper.pdf)

## Getting started

This guide assumes that you have received credentials for both OpenVPN
and secd, and an OpenVPN configuration file (ends with .ovpn)

### Setup
In order to use the system, there is some one-time configuration needed.

#### 1. *(optional)* Import certificate authority
Since the secure cluster is completely isolated, we need to self-sign
our certificates. If you don't want your browser to scream at you every time you visit any
of the webpages, you can import our certificate authority
  1. Download the CA-file
      [here](https://secd.app.cloud.cbh.kth.se/media/secd.pem)
  2. Trust it on your computer
      - Linux
        Follow [this
        guide](https://ubuntu.com/server/docs/security-trust-store) to
        install the CA certificate in Ubuntu (and many other distros)
      - MacOS
        Follow [this
        guide](https://support.apple.com/guide/keychain-access/add-certificates-to-a-keychain-kyca2431/mac)
        to install the CA certificate
      - Windows
        Follow
        [this guide](https://learn.microsoft.com/en-us/skype-sdk/sdn/articles/installing-the-trusted-root-certificate) to install the CA certificate

#### 2. Create a GPG-key
In order to sign commits that our GitLab can trust, you need to
create your own GPG key. If you already have a GPG key, you can skip this step.

- Linux
  1. Install gpg using apt: `apt install gnupg` (or the package
  manager for your distro)
  2. Follow [these
  steps](https://docs.gitlab.com/ee/user/project/repository/signed_commits/gpg.html#create-a-gpg-key)
  to generate a GPG key

- MacOS\
  Follow [this
  guide](https://gist.github.com/troyfontaine/18c9146295168ee9ca2b30c00bd1b41e)
  to generate a GPG key

- Windows
  1. Install WSL using [this
  guide](https://learn.microsoft.com/en-us/windows/wsl/install)
  2. Follow the steps for Linux
  Follow [this
  guide](https://docs.gitlab.com/ee/user/project/repository/signed_commits/gpg.html#associate-your-gpg-key-with-git)
  to set up Git to use it
#### 3. Setup VPN
To access our services inside the secure cluster you must connect to the VPN

- Linux
  1. Import the *.ovpn* in your VPN settings
  2. Connect to it using you VPN credentials (**NOT** your secd credentials)

- MacOS
  1. Download and install OpenVPN client [here](https://openvpn.net/client-connect-vpn-for-mac-os/)
  2. Import the *.ovpn* file in the client
  3. Connect to it using you VPN credentials (NOT your secd  credentials)

- Windows
  1. Download and install OpenVPN client [here](https://openvpn.net/client-connect-vpn-for-mac-os/)
  2. Import the *.ovpn* file in the client
  3. Connect to it using you VPN credentials (NOT your secd credentials)


#### 4. GitLab
1. Go to our [GitLab](https://gitlab.secd/)
2. Sign in with your secd account by clicking "Login in with yoursecd account" under *or sign in with*.
3. Create a clone password to be able to push your code (or pull private projects)
    1. Navigate to your profile
    2. Go to *Password* and set a password
4. Upload your GPG key
      Follow [this
      guide](https://docs.gitlab.com/ee/user/project/repository/signed_commits/gpg.html#add-a-gpg-key-to-your-account)
      to upload your public GPG key to your profile

5. Create a project
  1. Choose one of our example projects at the bottom of this
  page
  2. Fork it and create a public project
  3. Copy the URL under 'Clone with HTTPS'
  4. Run ` git clone  `<clone url>
  5. Enter your secd email-address and your GitLab clone password [1] [2]

### Workflow
After the setup is done, all you need to do is the following.\
Edit ➜ Push ➜ Check result in GitLab ➜ Edit ➜ Push ➜ Check result in GitLab ...

#### Push code
1. Open the project in an editor, such as Visual Studio Code
2. Edit something the repository (so Git can push something to
GitLab)
3. Run `git add . && git commit -S -m "some changes" && git push` [2] [3]

#### Check results
After some time your results are available in a folder
*/outputs* in a new branch of your repository.
The branch name contains the date of the run.

### Notes
- [1] Inside WSL on Windows
- [2] If you did not import the certificate authority, you need to add `-c http.sslVerify=false`
- [3] On Windows you might need to run the commands separately (without &&)

## Next steps

### Base Docker image

To use a prebuilt Docker image with the correct NVIDIA drivers
preinstalled, the **registry.secd/secd/base** provides drivers, python
and pytorch.

### Outputting results

During a run, you may want to save some logs of what is happening, as
well as outputting models and other results. It is crucial that you save
these inside the specified path, as only the files inside that directory
will be pushed to GitLab. If you would like to save stdout and stderr,
these must be piped to files inside the specified output directory. In
python, this can be done using:

    with open(f'{secd.get_output_path()}/output.txt', 'w') as sys.stdout:

The path is available as an environment variable as **OUTPUT_PATH**,
and using the secd Python package as **secd.get_output_path()**

### Caching function calls

If you are used to the workflow provided by Jupyter Notebooks, a python
package is available which emulates the behavior of caching results for
previous functions. The package can be installed with **pip install
secd** and used by tagging expensive functions with **@secd.cache**.

When caching, it is important that you specify the cache_dir and
mount_path variables in secd.yml. **cache_dir** is a directory with
the name of your choosing, will be created upon first run and persisted
thereafter. If you want to reset the cache entirely, change this
variable and a new directory will be created.

The cache is saved for each function, and depends on input parameters
and source code. If any of these change, the function will be recomputed
and cached.

The **mount_path** variable tells Kubernetes where to mount the cache
inside your container. The example below uses /app/cache. It is
important that this directory exists in the container. You can create it
in your Dockerfile using

    RUN mkdir -p /app/cache

An example project can be found at:
<https://gitlab.secd/pierrelf/small-docker/-/blob/main/server.py?ref_type=heads>

### Configuring the run

In your repository, include a file named *secd.yml* Supported
configuration:

  - **runfor** - number of hours before the run is terminated, can be a
    float - example 0.1 = 6 minutes. Default is 3
  - **gpu** - choose whether a GPU is attached during run (may delay
    start if all GPUs are in use). Default is false
  - **cache_dir** - path inside storage bucket. If not specified,
    caching will not be used.
  - **mount_path** - mount path inside container, default is "/cache"

If you use only some parameters, or do not have a *secd.yml* file, the
default values will be used for missing parameters.

Example:

    runfor: 0.1
    gpu: false
    cache_dir: "small-docker"
    mount_path: "/app/cache"

### Adding datasets

Datasets must be added physically. Load your dataset onto a portable
hard disk, USB 3.0 compatible, and request a data insertion time slot
from one of the contact persons.

We currently support MySQL and NFS filesystem.

## Example projects

If you are unsure where to start, take a look at the example projects:

  - <https://gitlab.secd/pierrelf/machine-learning>
  - <https://gitlab.secd/pierrelf/small-docker>
  - <https://gitlab.secd/emilk2/simple-stdout>

## Flowchart

[2000px](/File:Secure_tutorial.png "wikilink")