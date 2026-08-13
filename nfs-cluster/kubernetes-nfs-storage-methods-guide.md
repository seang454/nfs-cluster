# 📚 Complete Guide: Kubernetes NFS Storage Methods Comparison

This guide explains and compares the **3 different ways** to connect and use NFS storage in Kubernetes, ranging from manual host-level mounts to automated dynamic provisioning with `StorageClass`.

---

## 🔍 Summary Comparison Matrix

| Feature | Method 1: Manual `sudo mount` (`hostPath`) | Method 2: Direct Inline `volumes.nfs` | Method 3: Dynamic `StorageClass` (`nfs-client`) |
| :--- | :--- | :--- | :--- |
| **How it's configured** | SSH into node OS, run `sudo mount` manually, use `hostPath` | Hardcode NFS IP & Export Path directly in Pod YAML | Request storage via a `PersistentVolumeClaim` (PVC) |
| **Who manages it?** | System Administrator / DevOps | Application Developer in YAML | Kubernetes (`nfs-client-provisioner`) |
| **Automatic Node Mount?** | ❌ **No** (Fails if Pod moves to another node) | ✅ **Yes** (Kubernetes handles OS mount automatically) | ✅ **Yes** (Kubernetes handles OS mount automatically) |
| **Directory Isolation** | ❌ **None** (All pods share 1 single folder) | ❌ **None** (All pods share 1 single folder) | ✅ **Yes** (Each PVC gets its own private subfolder) |
| **Hardcoded IPs in Pods?** | N/A (`hostPath`) | ❌ **Yes** (Must put `10.148.0.12` in every Pod manifest) | ✅ **No** (Developers never need to know the NFS IP) |
| **Lifecycle Cleanup** | ❌ Manual file deletion | ❌ Manual file deletion | ✅ Automated (Clean up or archive on PVC deletion) |
| **Best Used For** | Quick manual host testing / OS debugging | Legacy apps or simple fixed static shares | **Production Kubernetes Workloads** |

---

## 🛠️ Detailed Breakdown of the 3 Methods

### 1️⃣ Method 1: Manual SSH + `sudo mount` (Host-Level `hostPath`)

In this approach, you manually SSH into the Kubernetes worker node OS and mount the NFS share onto the node file system.

#### Execution Steps:
1. SSH into **Worker Node 1**:
   ```bash
   sudo mkdir -p /opt/nfs/data
   sudo mount 10.148.0.12:/opt/nfs/data /opt/nfs/data
   ```
2. Create a test file:
   ```bash
   echo "hello from host" > /opt/nfs/data/test.txt
   ```
3. Reference the local directory in Pod YAML using `hostPath`:
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: manual-mount-pod
   spec:
     containers:
       - name: app
         image: nginx
         volumeMounts:
           - name: host-vol
             mountPath: /usr/share/nginx/html
     volumes:
       - name: host-vol
         hostPath:
           path: /opt/nfs/data
   ```

#### ❌ Why this is BAD for Kubernetes:
* **No Mobility**: If Kubernetes reschedules your Pod to **Worker Node 2** where you forgot to run `sudo mount`, the container will fail to start or point to an empty local folder.
* **High Maintenance**: You must SSH into every node in the cluster to set up mounts manually.
* **No Safety/Isolation**: All containers mounted to `/opt/nfs/data` read/write to the exact same folder.

---

### 2️⃣ Method 2: Direct Inline NFS (`volumes.nfs`)

Kubernetes has a built-in NFS volume driver. Instead of mounting NFS on the host OS manually, you specify the NFS server IP and export path directly inside the Pod YAML manifest.

#### Pod YAML Example:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: direct-nfs-pod
spec:
  containers:
    - name: web-app
      image: nginx
      volumeMounts:
        - name: register-vol
          mountPath: /app/data
  volumes:
    - name: register-vol
      nfs:
        server: 10.148.0.12     # Hardcoded NFS Server IP
        path: /opt/nfs/data      # Hardcoded NFS Export Path
```

#### How it works:
When Kubernetes schedules this Pod onto any worker node, the node's `kubelet` uses the host's **`nfs-common`** driver to automatically mount `10.148.0.12:/opt/nfs/data` directly for the Pod. You **do not** need to run `sudo mount` via SSH.

#### ✅ Pros & ❌ Cons:
* ✅ **Pros**: Fully automated host mounting by Kubernetes. Pods can move to any worker node seamlessly.
* ❌ **Cons**: 
  1. **Hardcoded Configuration**: If your NFS IP changes from `10.148.0.12` to `10.148.0.20`, you must update dozens of application YAML files.
  2. **Shared Overwrite Hazard**: Every Pod mounting `/opt/nfs/data` shares the exact same root directory. If App A writes `data.log`, it can overwrite App B's `data.log`.

---

### 3️⃣ Method 3: Dynamic Provisioning with `StorageClass` (`nfs-client`) ⭐ *(Recommended Best Practice)*

This is the cloud-native, production standard. You decouple storage infrastructure from application code using a **StorageClass** and **PersistentVolumeClaim (PVC)**.

#### How it works:
1. The Cluster Administrator installs the `nfs-client-provisioner` pod once.
2. Application developers request storage by creating a `PersistentVolumeClaim` (PVC).
3. The provisioner automatically creates a dedicated, isolated subfolder on the NFS server (e.g. `/opt/nfs/data/default-register-pvc-pvc-8f92a1/`).
4. Kubernetes binds the PV to the PVC and mounts it to the Pod.

#### Step-by-Step Manifests:

##### Step 1: Create a PVC (`pvc.yaml`)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: register-pvc
spec:
  accessModes:
    - ReadWriteMany  # Multiple pods can read/write simultaneously
  storageClassName: nfs-client  # Uses your nfs-client provisioner
  resources:
    requests:
      storage: 5Gi
```

##### Step 2: Reference PVC in your Pod (`pod.yaml`)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: register-app-pod
spec:
  containers:
    - name: register-app
      image: nginx
      volumeMounts:
        - name: register-vol
          mountPath: /app/data
  volumes:
    - name: register-vol
      persistentVolumeClaim:
        claimName: register-pvc  # References the PVC name above
```

#### ✅ Why Method 3 is the Best Practice:
1. **100% Automated Subdirectories**: App A and App B get completely isolated subfolders automatically. They will never overwrite each other's data.
2. **No Hardcoded IPs**: Developers don't need to know `10.148.0.12` or `/opt/nfs/data`. If the storage infrastructure IP changes, admins only update the `StorageClass` / Provisioner deployment **once**.
3. **Automated Lifecycle**: When a PVC is deleted, the `StorageClass` can automatically clean up or archive the deleted storage folder according to its `reclaimPolicy`.

---

## 🏗️ Architecture Visualization

```text
==================================================================================================
METHOD 1: Manual hostPath (Fragile & Manual)
==================================================================================================
[ Admin SSH ] ──> `sudo mount` ──> [ Host OS: /opt/nfs/data ] <── [ Pod hostPath ] (Node Specific!)

==================================================================================================
METHOD 2: Direct Inline NFS (Automated Mount, Hardcoded IPs)
==================================================================================================
[ Pod Manifest (server: 10.148.0.12) ] ──> Kubelet + nfs-common ──> [ NFS Export: /opt/nfs/data ]

==================================================================================================
METHOD 3: Dynamic Provisioner + StorageClass (Production Standard)
==================================================================================================
[ App PVC Manifest ] ──> [ StorageClass: nfs-client ]
                               │
                               ▼ (Auto-creates subfolder)
                 [ nfs-client-provisioner Pod ]
                               │
                               ▼
        [ NFS Export: /opt/nfs/data/default-register-pvc-pvc-12345/ ]
```

---

## 🌐 Component Location Matrix: Client vs. Server vs. Network Bridge

To clearly understand where each component lives and operates:

### 1. 💻 CLIENT SIDE ONLY (Kubernetes Worker Nodes & Workload Pods)
These components run **only** on the Kubernetes client nodes:
* **`nfs-common` package**: Linux kernel drivers (`mount.nfs4`, `rpcbind`) installed on worker node OS.
* **Workload Container Mounts**: Mount paths inside application containers (e.g., `/usr/share/nginx/html`, `/app/data`).
* **Local Node Mount Directory**: Local folder on node OS if mounted manually (e.g., `/mnt/nfs` or `/opt/nfs/data`).
* **`nfs-client-provisioner` Pod**: Controller pod running in K8s (namespace `kube-system`).

---

### 2. 🖥️ SERVER SIDE ONLY (Storage Nodes & Gateways)
These components run **only** on your Storage Cluster nodes (`haproxy-1`, `haproxy-2`, `haproxy-3`):
* **`nfs-ganesha` Daemon**: The NFS server process running in user-space listening for incoming NFS connections.
* **`nfs-ganesha-ceph` Plugin**: Translates NFS file requests directly into CephFS API calls.
* **Ceph Storage Cluster**: Daemons (`ceph-mon`, `ceph-mgr`, `ceph-osd`, `ceph-mds`) managing raw disks (`/dev/sdb`).
* **High Availability Stack**: `pacemaker`, `corosync`, and `pcsd` managing the cluster state and failovers.
* **Physical Disks & Files**: The physical storage media where your actual files are written and preserved.

---

### 3. 🤝 NETWORK BRIDGE (Interacts Between Client & Server)
These parameters bridge the communication between Client and Server:
* **Virtual IP (VIP)**: E.g., `10.146.0.11` (or `10.148.0.12`). Managed by Pacemaker on the server, targeted by Kubelet/NFS drivers on the client.
* **NFS Protocol & Port**: NFSv4 protocol communicating over **TCP Port 2049**.
* **NFS Pseudo Export Path**: The shared top-level export folder defined on the server (e.g., `/data` or `/opt/nfs/data`) and mounted by clients.

---

## 🔄 End-to-End Step-by-Step Execution Sequence (From User Request to Disk Write)

Below is the exact step-by-step lifecycle showing **who triggers the command**, **which tool executes it**, and **where it is processed**:

```text
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: Cluster Setup & Groundwork (DevOps Admin)                                                                │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 [1. Admin runs Ansible/Terraform] ──> Installs Ceph + NFS-Ganesha on Servers & nfs-common on K8s Worker Nodes
                                   ──> Deploys StorageClass (nfs-client) & Provisioner Pod into K8s

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: Application Developer Requests Storage                                                                  │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 [2. Developer] ──> Runs: `kubectl apply -f pvc.yaml` (Requests 5GB storage via storageClassName: nfs-client)

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: Dynamic Provisioning (Kubernetes Controller)                                                             │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 [3. K8s API] ──> Notifies `nfs-client-provisioner` Pod
 [4. Provisioner Pod] ──> Connects to NFS Server VIP (10.146.0.11) over TCP 2049
                      ──> Creates folder: `/data/default-my-pvc-pvc-12345/`
                      ──> Registers PV object in K8s and binds it to PVC

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: Application Pod Mount & Scheduling (Kubelet & OS)                                                       │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 [5. Developer] ──> Runs: `kubectl apply -f pod.yaml` (References PVC)
 [6. K8s Scheduler] ──> Assigns Pod to `Worker-Node-2`
 [7. Kubelet on Worker-Node-2] ──> Calls Linux Kernel via `nfs-common` (`mount.nfs4`)
                                ──> Mounts `10.146.0.11:/data/default-my-pvc-pvc-12345` onto node file system
                                ──> Passes mount into container at `/app/data`

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: Application File Write (Client -> Network)                                                               │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 [8. App Container] ──> Executes write: `echo "hello" > /app/data/file.txt`
 [9. Host Linux Kernel] ──> `nfs-common` driver converts file write into NFSv4 RPC packets
                        ──> Transmits TCP packets over port 2049 to VIP `10.146.0.11`

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 6: Server Persistence (NFS Gateway -> CephFS -> Disk)                                                       │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 [10. Pacemaker VIP] ──> Forwards TCP 2049 packets to Active Gateway (`haproxy-1`)
 [11. nfs-ganesha] ──> Receives NFSv4 write request
 [12. nfs-ganesha-ceph] ──> Translates NFS write call to CephFS C-library (`libcephfs.so`)
 [13. Ceph MDS] ──> Updates directory metadata for `/default-my-pvc-pvc-12345/file.txt`
 [14. Ceph OSD Daemons] ──> Writes 3x replicated BlueStore data blocks directly to `/dev/sdb` physical disks!
```

### 📋 Phase-by-Phase Details Table

| Phase | Who / What triggers it? | Which Tool / Software executes it? | Where does it execute? | Action Output |
| :--- | :--- | :--- | :--- | :--- |
| **Phase 1: Setup** | DevOps Admin | Ansible / `cephadm` / `apt install` | Storage Nodes & K8s Master | NFS-Ganesha & Ceph cluster ready; `nfs-common` installed |
| **Phase 2: PVC Request** | Developer | `kubectl apply -f pvc.yaml` | K8s Control Plane API | Unbound PVC created in K8s API |
| **Phase 3: Provisioning** | K8s API | `nfs-client-provisioner` Pod | `kube-system` namespace | Subfolder created on NFS export; PV created & bound |
| **Phase 4: Node Mounting** | K8s Kubelet | Linux `nfs-common` (`mount.nfs4`) | K8s Worker Node OS | Remote NFS folder attached to local node file system |
| **Phase 5: Client Write** | Application Code | Linux Kernel Network Stack | Container -> Worker Node | NFSv4 TCP RPC packets sent over network to `10.146.0.11:2049` |
| **Phase 6: Disk Persistence**| Pacemaker VIP | `nfs-ganesha` -> `nfs-ganesha-ceph` -> Ceph OSD | Storage Gateway Tier (`haproxy-1`) | Data written across 3x replicated BlueStore `/dev/sdb` disks |

