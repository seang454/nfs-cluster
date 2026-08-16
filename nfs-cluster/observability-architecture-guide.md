# 🏗️ Master Production Deployment & Placement Guide
## HA Ceph + NFS-Ganesha + Kubernetes Observability Stack

This document details **WHERE** each component of the 5-tool observability stack is deployed and **WHY it MUST be installed in that specific location**.

---

## 🗺️ Complete Deployment Placement & Justification Map

```text
==================================================================================================================
📍 LOCATION 1: HA STORAGE HOST NODES (`haproxy-1`, `haproxy-2`, `haproxy-3`)
👉 WHY HERE? Ceph, NFS-Ganesha, Pacemaker, and raw hard drives (/dev/sdb) run directly on the host Linux OS,
             OUTSIDE of Kubernetes. Monitoring tools MUST run on the host OS to access hardware & log files.
==================================================================================================================
  1. 🟢 ceph-mgr-prometheus ───► Ceph Manager Module (Port 9283)
                                 └─► WHY: Reads Ceph OSD health, IOPS & pool space directly from Ceph daemon.
  2. 🟢 node_exporter       ───► Linux Host OS Systemd Service (Port 9100)
                                 └─► WHY: Reads physical host CPU, RAM, network & disk SMART health.
  3. 🚀 Grafana Alloy (Host)───► Linux Host OS Systemd Service
                                 └─► WHY: Tails host log files (/var/log/ganesha/ganesha.log & journald).

==================================================================================================================
📍 LOCATION 2: KUBERNETES CLUSTER (Namespace: `monitoring`)
👉 WHY HERE? Kubernetes provides automated container management, persistent storage (NFS PVCs), high availability,
             and single-URL web ingress for central databases and dashboards.
==================================================================================================================
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

==================================================================================================================
📍 LOCATION 3: INSIDE APPLICATION SOURCE CODE (K8s App Pods)
👉 WHY HERE? Application performance (file write speed to NFS, API latency, custom app errors) can ONLY be
             captured from inside the application code execution process.
==================================================================================================================
  9. 🔌 OpenTelemetry SDK   ───► Library inside App Code (Spring Boot / Node.js / Python)
                                 └─► WHY: Emits custom application OTLP metrics and logs over ports 4317/4318.
==================================================================================================================
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
# Install node_exporter (Exposes host metrics on port 9100)
sudo apt-get update && sudo apt-get install -y prometheus-node-exporter

# Install Grafana Alloy host service
sudo apt-get install -y alloy
sudo systemctl enable --now alloy
```

### 3. On Kubernetes Master Node (`k8s-master-1`):
```bash
# 1. Create monitoring namespace
kubectl create namespace monitoring

# 2. Add Official Helm Repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 3. Deploy Prometheus + Grafana + Alertmanager Stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=nfs-client \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi

# 4. Deploy Loki + Grafana Alloy Log Stack
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set loki.persistence.enabled=true \
  --set loki.persistence.storageClassName=nfs-client \
  --set loki.persistence.size=50Gi \
  --set alloy.enabled=true
```
