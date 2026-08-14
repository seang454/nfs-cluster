# 📘 Kubernetes NFS Provisioner Architecture & Data Flow Guide

This document provides a comprehensive breakdown of how **`nfs-client-provisioner`** works in Kubernetes, how and where directory paths are created, and the exact step-by-step path data takes from an application container to the physical NFS storage server.

---

## 1. 💡 Core Concept: Control Plane vs. Data Plane

Before tracing paths, it is vital to understand the separation of duties:

* **`nfs-client-provisioner` (Control Plane Only):**
  This pod (e.g. `nfs-client-provisioner-bddf6655d-2g68h`) **ONLY** handles management and dynamic provisioning. When a user creates a `PersistentVolumeClaim` (PVC), it connects briefly to the NFS server to create a subfolder and registers a `PersistentVolume` (PV) in Kubernetes.
  
  > ⚠️ **IMPORTANT:** Application data **NEVER** flows through or gets stored inside the `nfs-client-provisioner` pod!
  
* **Worker Node Kernel (Data Plane):**
  Application data travels directly from the **Worker Node hosting your application pod** over the network to the **NFS Storage Server**. If the provisioner pod crashes or restarts, existing running application pods continue reading and writing to the NFS server without interruption.

---

## 2. 🗺️ Path Overview: The 4 Paths (2 Client + 2 Server)

```text
=================================== CLIENT SIDE ===================================

  [ 1st Path ]  Inside Container ──────> /app/data/file.txt
                                             │ (Linux Bind Mount)
                                             ▼
  [ 2nd Path ]  Worker Node Host OS ───> /var/lib/kubelet/pods/<POD-UUID>/volumes/kubernetes.io~nfs/<PV-NAME>/file.txt

==================================== NETWORK (TCP 2049) ===========================

  [ 3rd Path ]  NFS Server Subfolder ──> /data/default-my-app-pvc-pvc-12345-6789/file.txt
                                             │ (Subfolder inside Export)
                                             ▼
  [ 4th Path ]  NFS Main Server Export ─> /data ──> [ Physical Disks (/dev/sdb) ]

=================================== SERVER SIDE ===================================
```

### Detailed Path Table

| Location | Path # | Path Name | Real Example Path | Who Creates It & When? | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Client** | **1st** | **App Container Path** | `/app/data` | **Developer** (defined in `pod.yaml` under `volumeMounts.mountPath`) | The path inside the container that application code writes to. |
| **Client** | **2nd** | **Worker Node Host OS** | `/var/lib/kubelet/pods/b5ac88e8.../volumes/kubernetes.io~nfs/pvc-efc064c3...` | **`kubelet`** (on Worker Node OS when Pod is scheduled) | The local host directory on the worker node where `kubelet` runs `mount -t nfs4` to attach the remote NFS subfolder. |
| **Server** | **3rd** | **NFS PVC Subfolder** | `/data/default-web-pvc-pvc-12345...` | **`nfs-client-provisioner`** (automatically created when PVC is submitted) | The isolated directory created specifically for that individual PVC to store its files. |
| **Server** | **4th** | **Main NFS Export** | `/data` | **DevOps / Admin** (configured in [`ganesha.conf`](file:///home/seang/nfs-cluster/ansible-nfs-cluster-genesha/roles/nfs_ganesha/templates/ganesha.conf.j2#L6-L26) on server setup) | The top-level root shared folder published by the NFS server over the network. |

---

## 3. 🏗️ Phase 1: How & Where Paths Are Created (Path Setup)

### Step 1: Server Setup (4th Path Created)
* Admin installs `nfs-ganesha` or kernel NFS on storage nodes.
* Server exposes main export path: **`/data`** (Network export path: `10.146.0.11:/data`).

### Step 2: Developer Applies PVC (3rd Path Created)
* Developer runs `kubectl apply -f pvc.yaml`.
* `nfs-client-provisioner` intercepts the request and creates a subfolder on the NFS server formatted as:
  $$\text{Folder Name} = \text{\{namespace\}}-\text{\{pvc-name\}}-\text{\{pv-name\}}$$
* Real path created on NFS Server: **`/data/default-my-app-pvc-pvc-12345/`**.

### Step 3: Developer Applies Pod (1st & 2nd Paths Created)
* Developer runs `kubectl apply -f pod.yaml`.
* K8s scheduler places Pod on **`Worker-Node-2`**.
* `kubelet` on `Worker-Node-2` creates the host directory on the worker node OS:
  ```bash
  mkdir -p /var/lib/kubelet/pods/<POD-UUID>/volumes/kubernetes.io~nfs/<PV-NAME>
  ```
* `kubelet` executes the Linux kernel NFS mount:
  ```bash
  mount -t nfs4 10.146.0.11:/data/default-my-app-pvc-pvc-12345 \
    /var/lib/kubelet/pods/<POD-UUID>/volumes/kubernetes.io~nfs/<PV-NAME>
  ```
* Container engine (`containerd`/`Docker`) uses a **Linux Bind Mount** (`mount --bind`) to overlay the host path into the container at **`/app/data`**.

---

## 4. 🚀 Phase 2: End-to-End Data Write Journey (1st to 4th Path)

When your application writes a file (e.g. `echo "data" > /app/data/file.txt`):

```text
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ 1st Path: App Container Path (/app/data/file.txt)                                           │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
  App process executes write() syscall inside container.
                               │
                               ▼ (Linux Kernel Bind Mount)
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ 2nd Path: Worker Node Host OS (/var/lib/kubelet/pods/.../kubernetes.io~nfs/.../file.txt)    │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
  Data is stored in Worker Node RAM (Linux Page Cache) as "dirty pages".
                               │
                               ▼ (Flushed on close(), fsync(), or dirty_writeback timer)
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ Network Bridge (TCP Port 2049)                                                              │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
  Worker Node kernel (nfs-common) packages dirty pages into NFSv4 RPC TCP Packets and sends    │
  them to NFS Server VIP (10.146.0.11:2049).                                                  │
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ 3rd Path: NFS Server PVC Subfolder (/data/default-my-app-pvc-pvc-12345/file.txt)            │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
  NFS daemon (nfs-ganesha) receives packets and places file inside the PVC directory.          │
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ 4th Path: Main Server Export (/data) ──> Physical Storage Disks (/dev/sdb)                   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
  Data blocks are written to physical SSD/HDD media (or CephFS cluster) and ACK sent to client!│
```

---

## 5. 🛡️ Buffering & Failure Handling

* **Close-to-Open Consistency:** NFS guarantees that when an application closes a file (`close()`), all pending data in Worker Node RAM (Path 2) is forcibly flushed across the network to the NFS Server (Path 3 & 4).
* **Network Outages (`hard` mount):** If the network or NFS server drops while writing, the worker node kernel keeps dirty data safely in **Worker Node RAM** and retries endlessly until the server returns.

---

## 6. 🛠️ How to Verify Everything on Your Nodes

### On the Worker Node OS (Client Side):
```bash
# 1. Verify active kubelet NFS mount
mount | grep kubernetes.io~nfs

# 2. Inspect files directly on the worker node OS
ls -la /var/lib/kubelet/pods/*/volumes/kubernetes.io~nfs/*
```

### On the Storage Server OS (Server Side):
```bash
# 1. Show all active NFS network exports
showmount -e localhost

# 2. Inspect the physical folder created by nfs-client-provisioner
ls -la /data/
```
