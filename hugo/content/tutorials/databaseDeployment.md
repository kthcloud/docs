---
title: Deploy a database
---

# Creating a database deployment

Setting up a database deployment can be tricky, especially when dealing with persistent storage and configurations. This tutorial will guide you through the process of creating a database deployment on kthcloud.

> ### Accessing db deployments from outside the cloud is not possible
> 
> Directly accessing a database deployment from outside the cloud is not possible. Only HTTP traffic is routed to deployments via the Nginx proxy. If you need external access to your database, consider creating a Virtual Machine (VM) for that purpose.

Most popular databases (e.g., PostgreSQL, MongoDB, MySQL) have container images available. In this tutorial, I will focus on PostgreSQL, but you can follow a similar approach for other databases.

## Step by step guide

### Setting up storage

1. Go to [`deploy`](https://cloud.cbh.kth.se/deploy) 
2. Click on the button labeled `Manage Storage` to open the storage manager.

In the storage manager, create a new directory called `postgres-example`, and inside it, create two subdirectories: `init` and `data`. These will serve the following purposes:

- **Data directory (`data`)**: This will store your database data and ensure that the data persists even if the container is restarted or moved between nodes.
- **Init directory (`init`)**: This will hold SQL scripts used to initialize the database (e.g., creating tables, creating users or setting up schemas).

<div align="center" >

<img src="../../images/tutorial_database_deployment_sm_create_directory.png" >

<img src="../../images/tutorial_database_deployment_sm_name_directory.png" >

</div>

It should look like this inside your main directory.

<div>

<img src="../../images/tutorial_database_deployment_sm_data_and_init_created.png">

</div>

Make sure to note the paths for these directories, as you’ll need them later.

### Creating the deployment

Start by heading over to [create deployment](https://cloud.cbh.kth.se/create?type=deployment) on kthcloud.
Select a name for your database deployment,

<div>

<img src="../../images/tutorial_database_deployment_name.png">

</div>

Select the image of your desired database, eg [`postgres:15-alpine`](https://hub.docker.com/layers/library/postgres/15-alpine/images/sha256-0fb72c0bd71845e685f4c39afa3e1c56dfb5b22084df5652c69fb76de64c66c2?context=explore)

<div>

<img src="../../images/tutorial_database_deployment_select_image.png">

</div>

Set up the environment variables for your database. Most databases, including PostgreSQL, allow you to set up a user, password, and database by using environment variables. For PostgreSQL, you can set the following environment variables:

| Key | Description |
| --- | ----------- |
| POSTGRES_USER | The user that should be created. |
| POSTGRES_PASSWORD | The password for the created user.|
| POSTGRES_DB | The database that will be created. |

Example configuration:

<img src="../../images/tutorial_database_deployment_environment_variables.png">

#### Setting up persistent storage

Since your database will be running inside a Kubernetes cluster, it can be moved between nodes during restarts. If this happens, the container may be recreated, and any data stored inside the container will be lost. To persist your data, you'll need to mount persistent volumes to the container.

In the Persistent Storage section, you can mount the directories created earlier to the container.

* Data Volume: Mount the data directory to a path inside the container where your database will store its data.
For postgres it saves its data under `/var/lib/postgresql/data` so that is what I will mount to my `postgres-example/data` directory I created earlier.

* Init Volume: Mount the init directory to a path inside the container to use SQL scripts (e.g., for creating schemas) during initialization. It is pretty common for containerized dbs to use `/docker-entrypoint-initdb.d` for this, which is the case with postgres, so I will mount it to my `postgres-example/init` directory.

> TIP: If you have multiple scripts you can specify the order by naming them `1-<name>.sql`, `2-<name>.sql` and so on, to make sure they get executed in the correct order.

<img src="../../images/tutorial_database_deployment_persistent_storage.png">

In the example above I have mounted the directories created at [Setting up storage](#setting-up-storage) to the container. The purpose of the data volume is to persist all the database data, and the purpose of the init volume is to be able to mount `sql` scripts to run when initializing the db.

> NOTE: The scripts inside the `init` directory will only run when the database is empty, so if you want to add them after initial start or modify them, you need to delete all data inside the `data` directory and restart the deployment to run the scripts.

Press Create.

You should see logs like this after a while, if you have added scripts inside the `init` directory they will be run and you should see output logs from the db running them.

<img src="../../images/tutorial_database_deployment_created_logs.png">

### After creation

Since the database doesnt expose any HTTP endpoint you can change the `Visibility` of the deployment to `Private`.

<img src="../../images/tutorial_database_deployment_visibility.png">

### How do I access the database?

To access the database from another deployment you can connect to it by specifying the deployments name as the hostname.

For this example the connectionstring when using `jdbc` would be:

```properties
jdbc:postgres//postgres-example:5432/mydb?user=myuser&password=mypassword
```

### Done

Congratulations you have set up a database deployment! 🎉


### Troubleshooting

If you have problems connecting to the database you can try the following troubleshooting steps

#### Test database connection

You can try to connect to your database deployment using an image that tries to connect and then logs the result. Such an image exists at `ghcr.io/phillezi/test-psql-conn:latest` and can be run with the following configuration, (for this tutorial im using the connection settings specified earlier).

<img src="../../images/tutorial_database_deployment_troubleshoot_test_connection_configuration.png">

The image serves an status page at `/` on the deployment, (you can check it out by clicking the visit button on the test connection deployment) which has information about if it is connected and all the tables and their row counts.

> ### Restart the deployment to retry
> 
> The image only tries to connect once, so to retry connecting a restart of the deployment is required.

Here is an example on how it can look like, for this example I have used a sql script to create some tables and fill them.

<div align="center" >

<img src="../../images/tutorial_database_deployment_troubleshoot_testpsql_image.png">

</div>

If you dont get "Connection: Sucessful" there might be an issue with the credentials. Recheck the environment variables to make sure they match, empty the data directory on the `Storage Manager`, reboot the database and test connection image to try again.
