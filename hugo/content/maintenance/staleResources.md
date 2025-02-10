---
title: "Stale resources"
description: "Learn how to prevent system applications from being disabled due to inactivity in go-deploy."
---

## Understanding Stale Resources

In **kthcloud**, resources such as **deployments** and virtual machines (**VMs**) are automatically disabled if their owners remain inactive for more than **three months**. This helps free up system resources from inactive loads.

However, some system applications must remain **always active**, even if their owner is inactive. This guide explains how administrators can prevent system applications from being disabled by the stale resource cleaner.

## Preventing Automatic Disabling for System Apps

### Steps for Admins

1. **Log in** to [kthcloud](https://cloud.cbh.kth.se/) with an account that has **admin privileges**.
2. **Navigate to the resource's edit page**:
   - Find the deployment or VM that needs to remain **always active**.
   - Click on the **Edit** button (or pen if you are on the `/deploy` page).
3. **Scroll down** to the bottom of the edit page, right above the **danger zone**.
4. **Enable "Always Active" Mode**:
   - Locate the **"Always Active Option"** switch.
   - Toggle the switch to **on** to ensure the resource remains active permanently.
   ![enabled always active switch](../../images/maintenance_edit_resource_always_active_option.png)
5. **Enable disabled resource**:
    If the resource cleaner already disabled the resource, you need to re-enable it. This can be done by doing:
    - Update replicas from `0` to whatever non zero value you require, at the time of writing this there is a bug [here](https://github.com/kthcloud/go-deploy/issues/683) that makes deployment not get re-enabled by just changing back replicas, so you will also need to update another spec, such as **cores** or **ram** for the replica change to take effect. You can change it back after it has started.

### What Happens Next?
Once the "Always Active" option is enabled, the **stale resource cleaner worker** in [go-deploy](https://github.com/kthcloud/go-deploy/blob/e71a76f52dbc78fd2b84f78313dddb3a20041836/pkg/services/cleaner/stale_resource_cleaner.go#L25) will ignore this resource, preventing it from being disabled due to inactivity.
