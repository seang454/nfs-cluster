# 📁 NFS FileBrowser Storage Test Helm Chart

This Helm chart uses the ultra-lightweight **FileBrowser** image (`filebrowser/filebrowser:v2.27.0`, **~15MB**) to test your High-Availability NFS Cluster. 

It provides an **interactive Web UI** where you can create, edit, upload, download, and preview files directly on your NFS volume in real-time!

---

## 🚀 How to Run & Test

### Step 1: Deploy with Helm
```bash
helm install nfs-test ./helm-nfs-test
```

---

### Step 2: Verify Storage Provisioning
Check that your `nfs-client` StorageClass dynamically created the PV:
```bash
kubectl get pvc nfs-test-pvc
kubectl get pv
```

---

### Step 3: Access the Web File Manager UI

#### Method A: Via Port Forwarding
```bash
kubectl port-forward svc/nfs-test-nfs-storage-test 8080:80
```
Open your browser at: **`http://localhost:8080`**

#### Method B: Via NodePort
Open your browser at: **`http://<WORKER-NODE-IP>:30080`**

---

### 🔑 Login Credentials

* **Username**: `admin`
* **Password**: `admin`

---

### 🧪 What You Can Test in the UI

1. **Read/Preview**: Open `welcome-test.txt` (automatically generated inside your NFS volume).
2. **Edit/Update**: Modify text inside `welcome-test.txt` directly in the browser editor and save it.
3. **Upload/Delete**: Drag and drop new files or images onto your browser to test real-time NFS disk writes.

---

### 🧹 Clean Up
```bash
helm uninstall nfs-test
```
