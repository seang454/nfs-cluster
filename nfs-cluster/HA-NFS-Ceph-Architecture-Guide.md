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
