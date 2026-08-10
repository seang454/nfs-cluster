# 🚀 Complete High-Availability Ceph + NFS-Ganesha Architecture & Deployment Guide

This document provides a comprehensive technical reference for the **High-Availability (HA) Ceph + NFS-Ganesha + Pacemaker/Corosync Storage Cluster** integrated with a **5-Node Kubernetes Cluster** on Google Cloud Platform (GCP).

---

## 🏗️ Unified 15-Tool ASCII Architecture Diagram

```text
==============================================================================================================
                                ☸️ KUBERNETES COMPUTE LAYER (Pods & Workloads)
==============================================================================================================
[ K8s Control Plane Nodes ]                                                [ K8s Worker Nodes ]
  • nfs-common (Linux Kernel Driver)                                         • nfs-common (Linux Kernel Driver)
  • k8s-nfs-provisioner (StorageClass)                                      • Pods (Nextcloud / Spring Apps)
         │                                                                          │
         └────────────────────────────────────┬─────────────────────────────────────┘
                                              │ (NFSv4 Write Requests to 10.140.0.5:2049)
                                              ▼
==============================================================================================================
                     ⚡ HIGH-AVAILABILITY & NFS GATEWAY LAYER (Pacemaker + Ganesha)
==============================================================================================================
                         [ ⚡ Floating Virtual IP: 10.140.0.5 (Pacemaker Managed) ]
                                              │
                 ┌────────────────────────────┴────────────────────────────┐
                 ▼                                                         ▼
    ┌─────────────────────────┐                               ┌─────────────────────────┐
    │ 🟢 Server 1 (haproxy-1) │                               │ 🟡 Server 2 (haproxy-2) │
    │    [ ACTIVE GATEWAY ]   │                               │    [ STANDBY GATEWAY ]  │
    ├─────────────────────────┤                               ├─────────────────────────┤
    │ 🌐 nfs-ganesha          │                               │ 🌐 nfs-ganesha          │
    │ 🔌 nfs-ganesha-ceph     │                               │ 🔌 nfs-ganesha-ceph     │
    │ ⚡ pacemaker & pcsd     │ <══ UDP 5404/5405 Heartbeats ═>│ ⚡ pacemaker & pcsd     │
    │ 💓 corosync             │   (Totem Token Protocol)      │ 💓 corosync             │
    │ 📜 resource-agents-extra│                               │ 📜 resource-agents-extra│
    └────────────┬────────────┘                               └────────────┬────────────┘
                 │                                                         │
=================│=========================================================│==================================
                 ▼                                                         ▼
==============================================================================================================
                         💾 DISTRIBUTED STORAGE LAYER (Ceph Quincy + BlueStore)
==============================================================================================================
┌──────────────────────────────┐ ┌──────────────────────────────┐ ┌──────────────────────────────┐
│ [ Server 1: haproxy-1 ]      │ │ [ Server 2: haproxy-2 ]      │ │ [ Server 3: haproxy-3 ]      │
├──────────────────────────────┤ ├──────────────────────────────┤ ├──────────────────────────────┤
│ ⏱️ chrony (NTP Time Sync)    │ │ ⏱️ chrony (NTP Time Sync)    │ │ ⏱️ chrony (NTP Time Sync)    │
│ 🔓 ufw (Ports 2049,6789,2224)│ │ 🔓 ufw (Ports 2049,6789,2224)│ │ 🔓 ufw (Ports 2049,6789,2224)│
│ 🛠️ curl, wget, net-tools    │ │ 🛠️ curl, wget, net-tools    │ │ 🛠️ curl, wget, net-tools    │
├──────────────────────────────┤ ├──────────────────────────────┤ ├──────────────────────────────┤
│ 🐳 docker.io Containers:     │ │ 🐳 docker.io Containers:     │ │ 🐳 docker.io Containers:     │
│   • ceph-mon (Cluster Mon)   │ │   • ceph-mon (Cluster Mon)   │ │   • ceph-mon (Cluster Mon)   │
│   • ceph-mgr (Manager)       │ │   • ceph-mgr (Manager)       │ │   • ceph-mds (Metadata)      │
│   • ceph-osd (Storage)       │ │   • ceph-osd (Storage)       │ │   • ceph-osd (Storage)       │
├──────────────────────────────┤ ├──────────────────────────────┤ ├──────────────────────────────┤
│ 🧰 cephadm & ceph-common     │ │ 🧰 cephadm & ceph-common     │ │ 🧰 cephadm & ceph-common     │
│   (libcephfs.so C Library)   │ │   (libcephfs.so C Library)   │ │   (libcephfs.so C Library)   │
├──────────────────────────────┤ ├──────────────────────────────┤ ├──────────────────────────────┤
│ 💾 lvm2 -> Disk /dev/sdb     │ │ 💾 lvm2 -> Disk /dev/sdb     │ │ 💾 lvm2 -> Disk /dev/sdb     │
│   (50GB Ceph OSD Storage)    │ │   (50GB Ceph OSD Storage)    │ │   (50GB Ceph OSD Storage)    │
└──────────────┬───────────────┘ └──────────────┬───────────────┘ └──────────────┬───────────────┘
               │                                │                               │
               └────────────────────────────────┴───────────────────────────────┘
                                                ▼
                             [ 🔒 Unified 3x Replicated CephFS Storage Pool ]
==============================================================================================================
```

---

## 🛠️ Complete 15-Tool Inventory & Layer Placements

| Category | Tool / Package Name | Layer Placement | Technical Purpose & Function |
| :--- | :--- | :--- | :--- |
| **K8s Integration** | **`nfs-common`** | K8s Master & Worker Nodes | Linux kernel drivers (`mount.nfs4`, `rpcbind`) allowing nodes to mount NFS. |
| | **`k8s-nfs-provisioner`** | K8s Control Plane | Dynamic StorageClass controller (`nfs-client`) automating PVC subdirectory creation. |
| **HA & Failover** | **`pacemaker`** | Storage Tier (`haproxy-1..3`) | Cluster resource manager governing Virtual IP (`10.140.0.5`) failover. |
| | **`corosync`** | Storage Tier (`haproxy-1..3`) | Totem single-ring messaging engine running UDP 5404/5405 heartbeat pings. |
| | **`pcs` & `pcsd`** | Storage Tier (`haproxy-1..3`) | Management CLI and daemon (Port 2224) for cluster administration. |
| | **`resource-agents-extra`**| Storage Tier (`haproxy-1..3`) | OCF script library (`IPaddr2`) executing `ip addr add` & Gratuitous ARPs. |
| **NFS Gateway** | **`nfs-ganesha`** | Gateway Tier (`haproxy-1..3`) | User-space multi-threaded NFSv4 server daemon listening on TCP 2049. |
| | **`nfs-ganesha-ceph`** | Gateway Tier (`haproxy-1..3`) | FSAL plugin bridge translating NFS calls directly to CephFS. |
| **Storage Engine** | **`cephadm`** | Storage Tier (`haproxy-1..3`) | Master Ceph orchestrator managing container daemons and cluster topology. |
| | **`ceph-common`** | Storage Tier (`haproxy-1..3`) | `ceph` CLI tool and native `libcephfs.so` user-space C libraries. |
| | **`docker.io`** | Storage Tier (`haproxy-1..3`) | Container runtime running isolated Ceph daemons (`MON`, `MGR`, `OSD`, `MDS`). |
| | **`lvm2`** | Storage Tier (`haproxy-1..3`) | Formats `/dev/sdb` disks into raw BlueStore volume groups for OSD storage. |
| **Groundwork** | **`chrony`** | Infrastructure Base | NTP time sync daemon maintaining sub-millisecond clock alignment across nodes. |
| | **`ufw`** | Infrastructure Base | Linux firewall (configured disabled by default for unblocked cluster traffic). |
| | **`curl, wget, net-tools`**| Infrastructure Base | Package fetching, key verification, and socket debugging (`netstat`, `ifconfig`). |

---

## ⚡ High-Availability Failover Sequence

When `haproxy-1` crashes or loses power:

1. **`corosync`** detects missed token rotations on UDP 5404/5405 within **1000ms**.
2. **`pacemaker`** re-evaluates cluster membership and assigns Virtual IP `10.140.0.5` to `haproxy-2`.
3. **`resource-agents-extra`** (`IPaddr2`) executes `ip addr add 10.140.0.5/32 dev ens4` on `haproxy-2` and fires a **Gratuitous ARP (`arping -U 10.140.0.5`)** to update the GCP VPC router.
4. **`nfs-common`** on Kubernetes worker nodes automatically retries the TCP connection.
5. **`nfs-ganesha`** on `haproxy-2` handles the request, accessing identical mirrored data in **CephFS**.

---

## ☸️ Kubernetes Usage Guide

### Option 1: Dynamic PVC Approach (Recommended)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-client
  resources:
    requests:
      storage: 10Gi
```

### Option 2: Direct Inline NFS Mount (Legacy / Spring Apps)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spring-register-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: spring-register
  template:
    metadata:
      labels:
        app: spring-register
    spec:
      containers:
        - name: register-cont
          image: xeng/spring-register:7
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: register-vol
              mountPath: /src/main/resources/images
      volumes:
        - name: register-vol
          nfs:
            server: 10.140.0.5    # 👈 Active HA Virtual IP
            path: /data           # 👈 Ceph NFS Export Path
```

---

## 🔍 Deep-Dive Technical Reference: Why Each Tool Is Important

### 1. `corosync`
- **What it is**: High-frequency cluster messaging engine running on **UDP ports 5404 & 5405**.
- **Why it is important**:
  - **Prevents Split-Brain Catastrophe**: Uses the **Totem Single-Ring Token Protocol** to pass a virtual token in a continuous circle between `haproxy-1`, `haproxy-2`, and `haproxy-3`.
  - **Enforces Quorum**: Requires a majority vote (at least 2 out of 3 nodes alive). If a node loses quorum, Corosync immediately blocks it from touching storage, guaranteeing that two nodes never write to the disk at the same time.

---

### 2. `pacemaker`
- **What it is**: High-availability cluster resource manager (The Brain).
- **Why it is important**:
  - **Virtual IP Migration**: Automatically moves Virtual IP `10.140.0.5` from a crashed server to a healthy standby server in under 2 seconds.
  - **Service Dependencies**: Enforces ordering rules (e.g. *Virtual IP must start BEFORE NFS-Ganesha*) and colocation rules (*NFS-Ganesha must run on the SAME node holding the Virtual IP*).
  - **Continuous Self-Healing**: Checks port 2049 every 15 seconds to ensure NFS-Ganesha is healthy, restarting or migrating services automatically if an app fails.
  - **STONITH / Fencing**: Forcefully reboots unresponsive nodes to keep the storage pool 100% safe.

---

### 3. `resource-agents-extra` (`IPaddr2`)
- **What it is**: Standardized OCF script library executed by Pacemaker.
- **Why it is important**:
  - **Executes Operating System Commands**: Pacemaker is just a decision-maker; `resource-agents-extra` contains the actual `IPaddr2` script that runs Linux networking commands:
    1. `ip addr add 10.140.0.5/32 dev ens4` (Binds IP to NIC).
    2. `arping -U -c 5 -I ens4 10.140.0.5` (Fires Gratuitous ARP broadcast).
  - **Gratuitous ARP Broadcasting**: Notifies all GCP VPC routers and network switches that `10.140.0.5` has moved to the new MAC address.

---

### 4. `nfs-ganesha`
- **What it is**: User-space multi-threaded NFSv4 server daemon listening on TCP port 2049.
- **Why it is important**:
  - **Replaces Slow Kernel NFS**: Bypasses traditional `nfs-kernel-server` limitations, allowing multi-threaded user-space file transfers.
  - **Cloud Scale Concurrency**: Employs dynamic worker thread pools and an in-memory metadata cache (`mdcache`) to handle thousands of concurrent `ReadWriteMany` requests from Kubernetes pods.
  - **Graceful Lock Recovery**: Integrates with Pacemaker via DBus so NFSv4 file locks are gracefully reclaimed during failovers without throwing `Stale File Handle` (`ESTALE`) errors.

---

### 5. `nfs-ganesha-ceph`
- **What it is**: The FSAL (FileSystem Abstraction Layer) plugin bridge (`libganesha_fsal_ceph.so`).
- **Why it is important**:
  - **Direct RAM-to-Ceph I/O**: Translates NFS network requests directly into native `libcephfs` C function calls (`ceph_ll_write()`), streaming data from RAM into Ceph without touching the local server disk.
  - **Preserves Permissions**: Maps NFS file locks directly to Ceph MDS inode locks and preserves Linux `uid`, `gid`, and POSIX permissions across the cluster.

---

### 6. `cephadm`
- **What it is**: Official master Ceph cluster orchestrator.
- **Why it is important**:
  - **Automated Container Lifecycle**: Manages `ceph-mon`, `ceph-mgr`, `ceph-osd`, and `ceph-mds` as Docker containers (`quay.io/ceph/ceph`), restarting them automatically if they fail.
  - **Automated SSH Discovery**: Automatically connects to new nodes (`ceph orch host add`) and provisions daemons over SSH.
  - **Automated Disk Setup**: Detects raw attached disks like `/dev/sdb` (`ceph orch device ls`) and automatically formats them as BlueStore Ceph OSDs.
  - **Zero-Downtime Upgrades**: Executes rolling container image upgrades node-by-node without taking storage offline.

---

### 7. `ceph-common`
- **What it is**: Administrative CLI tools (`ceph`) and native user-space libraries (`libcephfs.so`).
- **Why it is important**:
  - Provides the essential C libraries required by `nfs-ganesha-ceph` to communicate directly with Ceph MDS/OSDs in memory.
  - Gives administrators status visibility (`ceph -s`, `ceph health`).

---

### 8. `docker.io`
- **What it is**: Linux container runtime engine.
- **Why it is important**:
  - Provides Linux kernel cgroups v2 (`memory.max`, `cpu.max`) and namespace isolation (`pid`, `net`, `mnt`) so Ceph daemons run cleanly isolated from host OS library conflicts.

---

### 9. `lvm2`
- **What it is**: Logical Volume Manager.
- **Why it is important**:
  - Formats physical block storage `/dev/sdb` into raw LVM Volume Groups so Ceph **BlueStore** can write raw data blocks directly (using **RocksDB** for metadata/WAL and **BlueFS** for block allocation) without Linux filesystem overhead.

---

### 10. `chrony`
- **What it is**: NTP time synchronization daemon.
- **Why it is important**:
  - Maintains sub-millisecond clock accuracy across all 8 nodes. If system clocks drift >0.05s, Ceph locks metadata mutations to prevent block timestamp corruption.

---

### 11. `ufw`
- **What it is**: Linux Uncomplicated Firewall.
- **Why it is important**:
  - Configured disabled by default on remote VMs to guarantee that cluster communication ports (2049, 6789, 2224, 5404/5405) operate with zero packet drops or netfilter delays.

---

### 12. `curl, wget, net-tools`
- **What it is**: System prerequisites and network debugging utilities.
- **Why it is important**:
  - Essential for fetching GPG signing keys, fetching repository packages, and inspecting raw socket listeners (`netstat`, `ifconfig`).

---

### 13. `nfs-common`
- **What it is**: Linux OS kernel NFS client utilities (`mount.nfs4`, `rpcbind`).
- **Why it is important**:
  - Installed on all Kubernetes master and worker nodes to provide the underlying Linux kernel drivers required to mount NFS shares over TCP port 2049.

---

### 14. `k8s-nfs-provisioner`
- **What it is**: Kubernetes dynamic `nfs-client` StorageClass controller.
- **Why it is important**:
  - Listens to Kubernetes PVC events and automatically provisions dynamic subdirectories on `10.140.0.5:/data`, eliminating the need to manually SSH into servers to create folders for new applications.
