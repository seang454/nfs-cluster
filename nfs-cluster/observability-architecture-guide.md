# 🏗️ Complete Production Observability & Monitoring Architecture Guide
## HA Ceph + NFS-Ganesha + Kubernetes Cluster

This guide defines the end-to-end production observability architecture combining **Prometheus**, **Grafana**, **Grafana Loki**, **Grafana Alloy**, and **OpenTelemetry** for the **HA Ceph + NFS-Ganesha + Kubernetes Storage Infrastructure**.

---

## 📐 Unified System Architecture Diagram

```text
================================================================================================------------------
                                       🖥️ VISUALIZATION & ALERTING LAYER
================================================================================================------------------
                                          ┌─────────────────────────────┐
                                          │ 📊 GRAFANA UNIFIED DASHBOARD │
                                          │    (Single Web Interface)   │
                                          └──────────────┬──────────────┘
                                                         │ (PromQL / LogQL Queries)
                          ┌──────────────────────────────┴──────────────────────────────┐
                          ▼                                                             ▼
           ┌─────────────────────────────┐                               ┌─────────────────────────────┐
           │ 📈 PROMETHEUS SERVER        │                               │ 📜 GRAFANA LOKI             │
           │ (Metrics DB - Bytes, IOPS)  │                               │ (Log Engine - Ceph & Apps)  │
           └──────────────▲──────────────┘                               └──────────────▲──────────────┘
                          │                                                             │
                          │ (Scrape / Remote Write)                                     │ (Loki HTTP Push / OTLP)
==========================│=============================================================│=========================
                          │                    🛰️ TELEMETRY COLLECTION LAYER             │
==========================│=============================================================│=========================
                          │                                              ┌──────────────┴──────────────┐
                          │                                              │ 🚀 GRAFANA ALLOY AGENT      │
                          │                                              │ 🔌 (Built on OpenTelemetry   │
                          │                                              │      Collector Engine)      │
                          │                                              └──────────────▲──────────────┘
                          │                                                             │
        ┌─────────────────┴─────────────────┐                          ┌────────────────┴──────────────┐
        │ • ceph-mgr-prometheus (Port 9283) │                          │ • OTLP Data (Ports 4317/4318) │
        │ • node_exporter (Port 9100)       │                          │ • /var/log/ganesha/ganesha.log│
        │ • kube-state-metrics (Port 8080)  │                          │ • /var/log/messages & journald│
        └─────────────────▲─────────────────┘                          └────────────────▲──────────────┘
                          │                                                             │
==========================│=============================================================│=========================
                          │               💾 INFRASTRUCTURE & APPLICATION WORKLOADS     │
==========================│=============================================================│=========================
   [ 📦 HA Ceph + NFS Storage Host Nodes ]                         [ ☸️ K8s Worker Nodes & App Workloads ]
   • haproxy-1 (10.140.0.2)                                       • k8s-worker-1 .. 5
   • haproxy-2 (10.140.0.3)                                       • 🔌 App Pods with OPENTELEMETRY SDK
   • haproxy-3 (10.140.0.4)                                         (Spring/Node.js/Python apps emitting
   • VIP: 10.140.0.5 (Pacemaker)                                     OTLP logs & metrics to Grafana Alloy)
================================================================================================------------------
```

---

## 🧱 Component Breakdown & Architecture Roles

### 1. Visualization & Alerting Layer
* **Grafana (Central Dashboard)**: Provides single-pane-of-glass visibility into metrics, storage space, and system logs.
* **Alertmanager**: Evaluates threshold rules and dispatches alerts via **Slack**, **PagerDuty**, or **Email** when storage is low or services fail.

### 2. Central Data Storage Layer
* **Prometheus Server**: Scrapes and stores raw numeric metrics (CPU, RAM, Disk Bytes, IOPS, Latency, OSD health).
* **Grafana Loki**: Indexing log database that stores and correlates log lines from systemd, NFS-Ganesha, Ceph daemons, and Kubernetes pods.

### 3. Collection & Agent Layer (Grafana Alloy & Exporters)
* **Grafana Alloy (DaemonSet & Systemd Service)**: Operates as the unified collector (using OpenTelemetry collector engine). Ships system journal logs, `/var/log/ganesha/ganesha.log`, `/var/log/ceph/ceph.log`, and container stdout to **Loki**.
* **Ceph Prometheus Plugin (`ceph-mgr-prometheus`)**: Native Ceph module exporting OSD latency, pool bytes, PG statuses, and cluster health directly.
* **Node Exporter**: Deployed on all bare-metal/VM storage hosts to capture OS disk usage, inode limits, and network throughput.
* **Kube-State-Metrics**: Exposes Kubernetes storage metrics (PVC capacity requested vs consumed, PV binding status).

---

## 📊 Telemetry Data Flow Matrix

| Source Component | Data Type | Collector Agent | Target Backend | Primary Metric / Log Key |
| :--- | :--- | :--- | :--- | :--- |
| **Ceph Storage Cluster** | Metrics | Direct Scrape | Prometheus | `ceph_pool_bytes_used`, `ceph_osd_up` |
| **NFS-Ganesha Daemon** | Logs | Grafana Alloy | Grafana Loki | `/var/log/ganesha/ganesha.log` |
| **Linux Host OS** | Host Metrics | Node Exporter | Prometheus | `node_filesystem_free_bytes` |
| **Pacemaker / Corosync** | Cluster HA | Node Exporter | Prometheus | `node_systemd_unit_state` (VIP status) |
| **Kubernetes PVCs** | Storage Metrics | Kube-State-Metrics| Prometheus | `kubelet_volume_stats_used_bytes` |
| **App Pods (Nextcloud/Spring)**| OTLP Metrics & Logs| 🔌 OpenTelemetry SDK | Prometheus & Loki | Container stdout/stderr & OTLP |

---

## 🚨 Production Threshold & Alerting Rules

| Alert Rule Name | Condition | Severity | Description | Action Required |
| :--- | :--- | :--- | :--- | :--- |
| `CephPoolNearFull` | Pool storage > 80% | ⚠️ Warning | Storage pool reaching capacity limit. | Add new OSD disk or clean unused files. |
| `CephPoolCritical` | Pool storage > 90% | 🚨 Critical | High risk of Ceph read-only freeze. | Immediate expansion or deletion of old snapshots. |
| `NFSGaneshaDown` | Ganesha process inactive | 🚨 Critical | NFS service crashed on active gateway node. | Pacemaker failover check / restart service. |
| `CephOSDDown` | `ceph_osd_up == 0` | 🚨 Critical | One or more storage physical drives offline. | Inspect host disk `/dev/sdb` & replace drive. |
| `K8sPVCFull` | PVC usage > 85% | ⚠️ Warning | Pod volume filling up. | Expand PVC size in K8s StorageClass. |

---

## 🗺️ Complete Deployment Placement & Justification Map

```text
================================================================================================------------------
📍 LOCATION 1: HA STORAGE HOST NODES (`haproxy-1`, `haproxy-2`, `haproxy-3`)
👉 WHY HERE? Ceph, NFS-Ganesha, Pacemaker, and raw hard drives (/dev/sdb) run directly on the host Linux OS,
             OUTSIDE of Kubernetes. Monitoring tools MUST run on the host OS to access hardware & log files.
================================================================================================------------------
  1. 🟢 ceph-mgr-prometheus ───► Ceph Manager Module (Port 9283)
                                 └─► WHY: Reads Ceph OSD health, IOPS & pool space directly from Ceph daemon.
  2. 🟢 node_exporter       ───► Linux Host OS Systemd Service (Port 9100)
                                 └─► WHY: Reads physical host CPU, RAM, network & disk SMART health.
  3. 🚀 Grafana Alloy (Host)───► Linux Host OS Systemd Service
                                 └─► WHY: Tails host log files (/var/log/ganesha/ganesha.log & journald).

================================================================================================------------------
📍 LOCATION 2: KUBERNETES CLUSTER (Namespace: `monitoring`)
👉 WHY HERE? Kubernetes provides automated container management, persistent storage (NFS PVCs), high availability,
             and single-URL web ingress for central databases and dashboards.
================================================================================================------------------
  4. 📈 Prometheus Server   ───► K8s StatefulSet (Stores metrics on NFS PVC)
                                 └─► WHY: Central database aggregating all cluster metrics with automated storage.
  5. 📜 Grafana Loki        ───► K8s StatefulSet (Stores logs on NFS PVC)
                                 └─► WHY: Central log indexing engine attached to persistent NFS storage.
  6. 📊 Grafana Web UI      ───► K8s Deployment (Exposed via Ingress/NodePort on Port 3000)
                                 └─► WHY: Unified web dashboard accessible to all developers & DevOps engineers.
  7. 🚀 Grafana Alloy (K8s) ───► K8s DaemonSet (Runs 1 pod on every node for OTLP & container logs)
                                 └─► WHY: K8s container stdout logs (/var/log/pods) exist on worker node hosts.
  8. ⚙️ Kube-State-Metrics  ───► K8s Deployment
                                 └─► WHY: Queries the Kubernetes API directly for PVC, PV, and Pod statuses.

================================================================================================------------------
📍 LOCATION 3: INSIDE APPLICATION SOURCE CODE (K8s App Pods)
👉 WHY HERE? Application performance (file write speed to NFS, API latency, custom app errors) can ONLY be
             captured from inside the application code execution process.
==================================================================================================================
  9. 🔌 OpenTelemetry SDK   ───► Library inside App Code (Spring Boot / Node.js / Python)
                                 └─► WHY: Emits custom application OTLP metrics and logs over ports 4317/4318.
================================================================================================------------------
```

---

## 📋 Comprehensive Placement Matrix & Architectural Rationale

| Tool | Where to Deploy | Installation Method | Why It MUST Be Installed There |
| :--- | :--- | :--- | :--- |
| **1. `ceph-mgr-prometheus`** | HA Storage Nodes (`haproxy-1..3`) | CLI: `ceph mgr module enable prometheus` | Ceph Quincy runs directly on storage node hosts. Only the Ceph Manager daemon has direct access to internal OSD pool math. |
| **2. `node_exporter`** | HA Storage Nodes (`haproxy-1..3`) | Linux `systemd` service or Docker container | Kubernetes cannot measure bare-metal OS disk SMART health, CPU temperatures, or `/var/log` partition space. `node_exporter` must run on the host kernel. |
| **3. Grafana Alloy (Host Agent)** | HA Storage Nodes (`haproxy-1..3`) | Linux `apt/dnf` package as `systemd` service | NFS-Ganesha writes its error log to `/var/log/ganesha/ganesha.log` on the host OS filesystem. Alloy must run locally to tail this file. |
| **4. Prometheus Server** | Kubernetes Cluster (`monitoring`) | Helm: `kube-prometheus-stack` | Kubernetes manages persistent volume mounts (`NFS PVC`) so Prometheus data is safely stored even if a monitoring pod restarts or moves. |
| **5. Grafana Loki** | Kubernetes Cluster (`monitoring`) | Helm: `loki-stack` | Central log storage requires scalable persistent disk storage (`NFS PVC`) and automated container restart policies provided by K8s. |
| **6. Grafana Web UI** | Kubernetes Cluster (`monitoring`) | Helm: `kube-prometheus-stack` | Running inside K8s allows Grafana to be exposed cleanly via K8s Ingress or NodePort (`http://<K8S_IP>:3000`) with SSL certificates. |
| **7. Grafana Alloy (K8s DaemonSet)**| Kubernetes Worker Nodes (All 5) | K8s DaemonSet (via Helm) | Kubernetes container log files (`/var/log/pods/*/*/*.log`) live on the worker node OS. Running Alloy as a DaemonSet ensures 1 collector runs on every worker. |
| **8. OpenTelemetry SDK** | Inside App Code (K8s Pods) | App dependency (`npm`, `pip`, `maven`) | Internal function timers (e.g. *"How fast did my Java app write to `/mnt/nfs/data`?"*) can only be measured inside the application runtime process. |

---

## 🚀 Complete Step-by-Step Execution Commands

### 1. On Ceph Manager Nodes (`haproxy-1`):
```bash
# Enable native Ceph Prometheus exporter (Exposes metrics on port 9283)
ceph mgr module enable prometheus

# Verify service is running
ceph mgr services
```

### 2. On HA Storage Host Nodes (`haproxy-1`, `haproxy-2`, `haproxy-3`):
```bash
# Install node_exporter for OS hardware metrics (Port 9100)
sudo apt-get update && sudo apt-get install -y prometheus-node-exporter

# Install Grafana Alloy for host NFS/Ceph logs
sudo apt-get install -y alloy
sudo systemctl enable --now alloy
```

### 3. On Kubernetes Master Node (`k8s-master-1`):
```bash
# 1. Create monitoring namespace
kubectl create namespace monitoring

# 2. Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 3. Deploy Prometheus + Grafana Stack (Using NFS StorageClass for persistent metrics)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=nfs-client \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi

# 4. Deploy Loki + Alloy Log Stack (Using NFS StorageClass for persistent logs)
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set loki.persistence.enabled=true \
  --set loki.persistence.storageClassName=nfs-client \
  --set loki.persistence.size=50Gi \
  --set alloy.enabled=true
```
