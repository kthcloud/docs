# System Apps

While most of the apps run on kthcloud should be hosted using deploy, there are a few exceptions, such as the dependecies of deploy itself.
These apps are referred to as *System apps* and should be deployed manually in the sys-cluster.
This guide describes the entire process to get an system app started, and is thus for system admins only.

## 1. (Optional) Persistent storage
If your apps requires persistent storage, you need to first identify what paths you need to mount.
Normally this is documented in the app's or image's documentation, such as `/etc/grafana` and `/var/lib/grafana` for grafana.

Once you have identified the paths, you need to create the storage pool in the NAS.

1. Go to the [NAS](https://nas.cloud.cbh.kth.se) and log in.
2. Go to `Storage` and click *Create Pool*.
3. Give the pool a name, such as `grafana`. This will be the name of the folder in the shared file system.
<img src="../../images/true_nas_create_pool.png" width="100%">

4. Go to `Sharing/NFS` and click *Add*. Input the required permissions for your app, and point the path to the pool you just created.
<img src="../../images/true_nas_add_nfs.png" width="80%">

5. Go to [File Browser](https://drive.cloud.cbh.kth.se) and log in.
6. Go to the folder you just created and create the subfolders you need. With the previous Grafana example it could be *config* to map to `/etc/grafana` and *db* or *data* to map to `/var/lib/grafana`. 
<img src="../../images/filebrowser_create_folders.png" width="80%">

## 2. Create the app
To deploy the app in the sys-cluster you will need access to the [k8s GitHub repo](https://github.com/kthcloud/k8s).
If you don't have access, ask a system admin to add you. 

1. *(Preferrable)* Create a branch for your changes.
2. Clone the repo and go to the `apps/sys` folder.
3. Create a yaml file for your app, such as `grafana.yaml`.
4. Add all the manifests required for your app. This includes the *namespace*, *service*, *deployment* and *ingress* (and *persistent volume claim* with *persistent volume* if you need persistent storage).
\
When creating the *persistent volume claim*, make sure to point the path to the NFS share you created in the previous step. You can make use of the templates provided in the repo to locate the NFS server. Please look at the other apps in the repo for examples, or look at the bottom of this page.
5. Commit and push your changes to the repo. It will automatically be deployed to the sys-cluster.

## Example: cicd-manager
```yaml
---
kind: Namespace
apiVersion: v1
metadata:
  name: cicd-manager
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: pv-cicd-manager-config
  namespace: cicd-manager
spec:
  capacity:
    storage: 10Gi
  nfs:
    server: {{ nfs_server }}
    path: "{{ nfs_base_path }}/cicd-manager/config"
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  volumeMode: Filesystem
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-cicd-manager-config
  namespace: cicd-manager
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  volumeName: pv-cicd-manager-config
  storageClassName: nfs
  volumeMode: Filesystem
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: cicd-manager
  namespace: cicd-manager
  labels:
    app.kubernetes.io/name: cicd-manager
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: cicd-manager
  template:
    metadata:
      labels:
        app.kubernetes.io/name: cicd-manager
    spec:
      volumes:
        - name: vol-cicd-manager-config
          persistentVolumeClaim:
            claimName: pvc-cicd-manager-config
      containers:
        - name: cicd-manager
          image: registry.cloud.cbh.kth.se/cicd-manager/cicd-manager
          env:
            - name: CONFIG_FILE
              value: /etc/cicd-manager/config.yml
            - name: PYTHONUNBUFFERED
              value: "1"
          volumeMounts:
            - name: vol-cicd-manager-config
              mountPath: /etc/cicd-manager
          imagePullPolicy: Always
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  name: cicd-manager
  namespace: cicd-manager
  labels:
    app.kubernetes.io/name: cicd-manager
spec:
  ports:
    - name: http-cicd-manager
      port: 8080
      targetPort: 8080
  selector:
    app.kubernetes.io/name: cicd-manager
```