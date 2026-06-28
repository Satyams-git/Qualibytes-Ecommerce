# 🛍️ QualiBytesShop — Modern E-Commerce Platform

[![Next.js](https://img.shields.io/badge/Next.js-14.1.0-black?style=flat-square&logo=next.js)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0.0-blue?style=flat-square&logo=typescript)](https://www.typescriptlang.org/)
[![MongoDB](https://img.shields.io/badge/MongoDB-8.1.1-green?style=flat-square&logo=mongodb)](https://www.mongodb.com/)
[![Redux](https://img.shields.io/badge/Redux-2.2.1-purple?style=flat-square&logo=redux)](https://redux.js.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

QualiBytesShop is a production-grade, full-stack e-commerce platform built with **Next.js 14**, **TypeScript**, and **MongoDB**. This project demonstrates a complete **DevOps pipeline** — from code to live HTTPS deployment on AWS EKS.

---

## ✨ Features

- 🎨 Modern responsive UI with dark mode (Tailwind CSS)
- 🔐 Custom JWT authentication (jose library, HTTP-only cookies, 30-day expiry)
- 🛒 Real-time cart management with Redux Toolkit (persisted to localStorage)
- 📱 Mobile-first design
- 🔍 Advanced product search, filtering, and sorting
- 💳 Secure checkout process
- 📦 9 product categories (516 products): Bags, Bakery, Books, Clothing, Furniture, Gadgets, Grocery, Makeup, Medicine
- 👤 User profiles, order history, role-based access (user/admin)

---

## 🏗️ Architecture

**3-Tier Architecture:**

| Tier | Technology | Details |
|------|-----------|---------|
| Frontend | Next.js 14 React, Redux Toolkit, Tailwind CSS | App Router, client-side routing, 3 Redux slices (auth, cart, sidebar) |
| Backend | Next.js API Routes | REST endpoints for auth, products, cart, orders. Middleware for route protection |
| Database | MongoDB + Mongoose ODM | 4 models: Product, User (bcrypt hashed passwords), Cart, Order |

**DevOps Pipeline:**

```
Code Push (GitHub dev branch)
    → Jenkins CI (build, test, scan, push images)
    → ArgoCD (GitOps auto-deploy)
    → AWS EKS (Kubernetes)
    → Nginx Ingress + Cert-Manager (HTTPS)
    → Prometheus + Grafana (Monitoring)
```

**2-Server Architecture:**

| Server | Purpose | Created By |
|--------|---------|-----------|
| Host/Bastion EC2 | Terraform, kubectl, helm, ArgoCD access | Manual or separate Terraform |
| Jenkins-Automate EC2 | CI pipeline (Jenkins, Docker, Trivy) | Terraform (`ec2.tf` + `install_tools.sh`) |

---

## 📋 Prerequisites

> **OS: Ubuntu 24.04 LTS recommended**

### Required Accounts
- **AWS Account** with IAM user (programmatic access, AdministratorAccess for demo)
- **GitHub Account** — fork both repos (app + shared library)
- **DockerHub Account** — required for pushing Docker images

### Required Tools (Install on Host/Bastion EC2)

```bash
# 1. AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
aws --version

aws configure
# Access Key ID, Secret Access Key, Region: ap-south-1, Output: json

# 2. Terraform
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y
terraform -v

# 3. Git
sudo apt install git -y
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# 4. Docker + Docker Compose
sudo apt-get install docker.io -y
sudo usermod -aG docker $USER
# LOGOUT and LOGIN again for the group change to take effect

# Docker Compose Plugin (not included in Ubuntu's docker.io package)
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker compose version

# 5. kubectl + Helm
sudo snap install kubectl --classic
sudo snap install helm --classic

# 6. eksctl (required for EBS CSI Driver setup)
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz"
tar -xzf eksctl_Linux_amd64.tar.gz
sudo mv eksctl /usr/local/bin/
eksctl version

# 7. Verify all tools
aws --version && terraform -v && git --version
docker --version && docker compose version
kubectl version --client && helm version --short && eksctl version
```

---

## 🚀 Getting Started

### Step 1 — Fork & Configure Repos

> ⚠️ **IMPORTANT:** Fork both repos and update the DockerHub username

**Fork App Repo:**
1. Fork: `https://github.com/Satyams-git/Qualibytes-Ecommerce`
2. Edit `Jenkinsfile` — change `DOCKER_IMAGE_NAME` and `DOCKER_MIGRATION_IMAGE_NAME` to your DockerHub username
3. Edit `kubernetes/08-qbshop-deployment.yaml` — change image name to your DockerHub username
4. Edit `kubernetes/12-migration-job.yaml` — change image name to your DockerHub username
5. Edit `kubernetes/07-mongodb-statefulset.yaml` — uncomment `storageClassName: gp2`
6. Edit `kubernetes/10-ingress.yaml` — change domain to yours
7. Edit `kubernetes/04-configmap.yaml` — change domain URLs to yours

**Fork Shared Library Repo:**
1. Fork: `https://github.com/Satyams-git/jenkins-shared-library`
2. Edit `vars/update_k8s_manifests.groovy`:
   - Change DockerHub username to yours
   - **Remove or update** the Ingress host sed line (it overwrites your domain with `asriv.shop` on every build)

### Step 2 — Terraform: Create Infrastructure

```bash
cd Qualibytes-Ecommerce/terraform

# Generate SSH key
ssh-keygen -f qualibytes-key
chmod 400 qualibytes-key

# Deploy infrastructure (~15 min for EKS)
terraform init
terraform plan
terraform apply  # type 'yes'

# Note the outputs
terraform output
# public_ip       = Jenkins EC2 IP
# eks_cluster_name = qualibytes-eks-cluster
```

### Step 3 — Configure kubeconfig (Host EC2)

```bash
aws eks --region ap-south-1 update-kubeconfig --name qualibytes-eks-cluster
kubectl get nodes  # 2 nodes, STATUS: Ready
```

### Step 3.5 — Local Testing with Docker Compose (Optional)

> This step is optional — production deployment is handled by ArgoCD. This is only for verifying the app works locally before deploying to EKS.

**`docker-compose.yml` includes `build:` directives** — it builds images locally from Dockerfiles (not just pulling from DockerHub).

3 services run in order: MongoDB → Migration (seeds 516 products) → App (Next.js)

```bash
cd ~/Qualibytes-Ecommerce

# DockerHub login (optional — not required for build, only for push)
docker login

# Create .env.local file (Docker Compose reads from this)
# If testing on EC2, use the EC2 PUBLIC IP instead of localhost
# Generate secrets first:
echo "NEXTAUTH_SECRET: $(openssl rand -base64 32)"
echo "JWT_SECRET: $(openssl rand -hex 32)"

cat > .env.local << 'EOF'
MONGODB_URI=mongodb://qbs-mongodb:27017/easyshop
NEXTAUTH_URL=http://<YOUR-EC2-PUBLIC-IP>:3000
NEXT_PUBLIC_API_URL=http://<YOUR-EC2-PUBLIC-IP>:3000/api
NEXTAUTH_SECRET=paste_generated_base64_here
JWT_SECRET=paste_generated_hex_here
EOF

# Edit and paste actual values
nano .env.local

# Start all services (first run takes ~10-15 min to build)
docker compose up -d

# Verify
docker ps                     # 2 containers: qbs-mongodb, qbs-app
docker logs qbs-migration     # Should show "Migrated 516 products"

# Browser: http://<EC2-IP>:3000
# Make sure port 3000 is open in EC2 security group

# Cleanup (before deploying to EKS)
docker compose down
```

> **Notes:**
> - `.env` is in the repo (common defaults), `.env.local` is for personal secrets (gitignored)
> - Use container name `qbs-mongodb` in MONGODB_URI — `localhost` won't work inside the Docker network
> - `ECONNREFUSED 127.0.0.1:27017` errors during build are NORMAL — the app connects via Docker network at runtime
> - If `docker login` is skipped, you'll see "pull access denied" warnings, but the build will still work

### Step 4 — Fix Jenkins on Jenkins EC2

> ⚠️ **KNOWN ISSUE:** `install_tools.sh` has 2 bugs:
> 1. Installs Java 17 — Jenkins 2.479+ requires **Java 21**
> 2. Jenkins GPG key method is outdated — keyserver method is needed

```bash
# SSH into Jenkins EC2
ssh -i qualibytes-key ubuntu@$(terraform output -raw public_ip)

# Check if Jenkins is running
sudo systemctl status jenkins

# If Jenkins failed (likely), fix manually:
sudo apt install -y openjdk-21-jre
sudo update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java

# Fix GPG key
sudo gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68
sudo gpg --export 7198F4B714ABFC68 | sudo tee /usr/share/keyrings/jenkins-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update && sudo apt-get install -y jenkins
sudo systemctl start jenkins && sudo systemctl enable jenkins

# If restart limit is hit:
sudo systemctl reset-failed jenkins
sudo systemctl start jenkins

# Grant Docker permission to Jenkins user
sudo usermod -aG docker jenkins
sudo chmod 666 /var/run/docker.sock
sudo systemctl restart jenkins

# Configure AWS CLI on Jenkins EC2 (pipeline needs EKS access)
aws configure
aws eks --region ap-south-1 update-kubeconfig --name qualibytes-eks-cluster

# Get Jenkins initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 5 — Jenkins Setup (Browser)

Open: `http://<JENKINS-EC2-IP>:8080`

1. Enter initial admin password
2. Install suggested plugins
3. Create admin user
4. **Plugins:** Manage Jenkins → Plugins → Install: `Docker Pipeline`, `Pipeline View`
5. **Credentials:** Manage Jenkins → Credentials → Global → Add:
   - GitHub: Kind=Username+Password, ID=`github-credentials`, Password=GitHub Personal Access Token
   - DockerHub: Kind=Username+Password, ID=`docker-hub-credentials`
6. **Shared Library:** Manage Jenkins → System → Global Pipeline Libraries → Add:
   - Name: **`Shared`** (capital S — must match `@Library('Shared')` in Jenkinsfile)
   - Default version: `main`
   - Repository URL: `https://github.com/<your-username>/jenkins-shared-library`
7. **Pipeline Job:** New Item → Name: `qb-ecom` → Pipeline:
   - General: ✅ GitHub project → URL: your repo
   - Triggers: ✅ GitHub hook trigger for GITScm polling
   - Pipeline: SCM=Git, URL=your repo, Credentials=github-credentials, Branch=`*/dev`
   - **Additional Behaviours → "Polling ignores commits from certain users" → `Jenkins CI`** (prevents CI loop)
   - Script Path: `Jenkinsfile`
8. **Webhook:** GitHub repo → Settings → Webhooks → Add:
   - Payload URL: `http://<JENKINS-EC2-IP>:8080/github-webhook/` (use Jenkins EC2 IP, not Host EC2)
   - Content type: `application/json`
   - Events: Just the push event
9. Click **Build Now** — all stages should be green

### Step 6 — EBS CSI Driver (Required for MongoDB Storage)

> ⚠️ **Without this, the MongoDB pod will remain in Pending state**

```bash
# Run on Host/Bastion EC2:

# 1. Get the node group name (Terraform adds a dynamic suffix)
aws eks list-nodegroups --cluster-name qualibytes-eks-cluster --region ap-south-1
# Copy the full name (e.g., qualibytes-demo-ng-2026062014293236510000000a)

# 2. Associate OIDC provider
eksctl utils associate-iam-oidc-provider \
  --cluster qualibytes-eks-cluster --region ap-south-1 --approve

# 3. Create IAM role for EBS CSI
eksctl create iamserviceaccount \
  --cluster qualibytes-eks-cluster --region ap-south-1 \
  --name ebs-csi-controller-sa --namespace kube-system \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve --role-only --role-name AmazonEKS_EBS_CSI_DriverRole

# 4. Install EBS CSI addon with the IAM role
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws eks create-addon \
  --cluster-name qualibytes-eks-cluster \
  --addon-name aws-ebs-csi-driver --region ap-south-1 \
  --service-account-role-arn arn:aws:iam::${ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole

# 5. Verify (wait 2-3 minutes)
kubectl get pods -n kube-system | grep ebs
# ebs-csi-controller: 6/6 Running
```

**If the controller shows CrashLoopBackOff (trust policy mismatch):**
```bash
OIDC_URL=$(aws eks describe-cluster --name qualibytes-eks-cluster --region ap-south-1 \
  --query "cluster.identity.oidc.issuer" --output text | sed 's|https://||')
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_URL}"},
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "${OIDC_URL}:aud": "sts.amazonaws.com",
        "${OIDC_URL}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
      }
    }
  }]
}
EOF

aws iam detach-role-policy --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy 2>/dev/null
aws iam delete-role --role-name AmazonEKS_EBS_CSI_DriverRole 2>/dev/null
aws iam create-role --role-name AmazonEKS_EBS_CSI_DriverRole \
  --assume-role-policy-document file://trust-policy.json
aws iam attach-role-policy --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy

aws eks delete-addon --cluster-name qualibytes-eks-cluster --addon-name aws-ebs-csi-driver --region ap-south-1
sleep 30
aws eks create-addon --cluster-name qualibytes-eks-cluster --addon-name aws-ebs-csi-driver --region ap-south-1 \
  --service-account-role-arn arn:aws:iam::${ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole
```

### Step 7 — Nginx Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer

kubectl get pods -n ingress-nginx        # 1/1 Running
kubectl get svc -n ingress-nginx         # Note the EXTERNAL-IP (LoadBalancer hostname)
```

### Step 8 — Cert-Manager

```bash
# Install CRDs first (Helm sometimes misses them)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=false

kubectl get pods -n cert-manager         # 3 pods Running
kubectl get crds | grep cert-manager     # 6 CRDs should appear
```

### Step 9 — ArgoCD (GitOps)

```bash
# Install
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd -w  # Wait until all pods are Running

# Expose the server
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
kubectl port-forward svc/argocd-server -n argocd 8085:443 --address=0.0.0.0 &

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Browser: https://<HOST-EC2-IP>:8085
# Username: admin | Password: output from above command
```

**ArgoCD Password Reset (if password is forgotten or login fails):**

```bash
# Method 1 — Retrieve password from initial secret
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Method 2 — If the secret was deleted, set a new password
# Install argocd CLI
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd && sudo mv argocd /usr/local/bin/

# Reset admin password (new password: admin123)
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "'$(htpasswd -nbBC 10 "" admin123 | tr -d ':\n' | sed 's/$2y/$2a/')'", "admin.passwordMtime": "'$(date +%FT%T%Z)'"}}'

# Restart ArgoCD server
kubectl rollout restart deployment argocd-server -n argocd
sleep 60

# Login with: admin / admin123

# If htpasswd is not installed:
# sudo apt install apache2-utils -y
```

**Create Application (GUI):**

| Field | Value |
|-------|-------|
| Application Name | qbshop |
| Project Name | default |
| Sync Policy | Automatic |
| ENABLE AUTO-SYNC | ✅ |
| SELF HEAL | ✅ |
| Repository URL | Your forked repo URL |
| Revision | dev |
| Path | kubernetes |
| Cluster URL | https://kubernetes.default.svc |
| Namespace | qbshop |

> ⚠️ **Job Immutable Error:** If ArgoCD fails to sync the `db-migration` Job, run:
> ```bash
> kubectl delete job db-migration -n qbshop
> ```
> Then click SYNC in ArgoCD. **Permanent fix:** Add these annotations to `12-migration-job.yaml`:
> ```yaml
> annotations:
>   argocd.argoproj.io/hook: PostSync
>   argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
> ```

### Step 10 — DNS Setup

1. Get the LoadBalancer hostname:
```bash
kubectl get svc -n ingress-nginx | grep LoadBalancer
# Copy the EXTERNAL-IP hostname
```

2. In your domain registrar (GoDaddy/Hostinger), add a CNAME record:

| Type | Name | Value |
|------|------|-------|
| CNAME | qbshop | `xxxx.ap-south-1.elb.amazonaws.com` |

3. Wait 5-15 minutes for DNS propagation
4. Verify:
```bash
nslookup qbshop.yourdomain.com
kubectl get certificate -n qbshop   # READY: True
```

5. Open in browser: `https://qbshop.yourdomain.com`

### Step 11 — Monitoring (Prometheus + Grafana)

**Components installed by `kube-prometheus-stack`:**

| Component | Purpose |
|-----------|---------|
| Prometheus | Collects metrics — CPU, memory, pod status, network |
| Grafana | Visualization dashboards — real-time graphs and alerts |
| Alertmanager | Alert routing — email/Slack notifications |
| Node Exporter | Node-level metrics for each K8s worker node |
| Kube State Metrics | Kubernetes object status — pods, deployments, HPA |
| Prometheus Operator | Kubernetes-native Prometheus deployment and configuration |

**Install (on Host EC2):**

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install qbshop-monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword='qbshop@grafana123' \
  --set prometheus.prometheusSpec.retention=15d \
  --set prometheus.prometheusSpec.retentionSize='5GB'

# Wait 3-5 minutes — creates ~35 Kubernetes objects
kubectl get pods -n monitoring -w
# Press Ctrl+C when all pods show Running
```

**Access Grafana:**

```bash
kubectl port-forward svc/qbshop-monitoring-grafana \
  -n monitoring 3001:80 --address=0.0.0.0 &

# Browser: http://<HOST-EC2-IP>:3001
# Username: admin | Password: qbshop@grafana123
# Make sure port 3001 is open in EC2 security group
```

**Explore Dashboards in Grafana:**
- Navigate to: Left panel → Dashboards → Browse
- Search: `Kubernetes / Compute Resources / Namespace (Pods)` → select namespace `qbshop`
- Other useful dashboards:
  - `Kubernetes / Compute Resources / Cluster` — full cluster overview
  - `Node Exporter / Nodes` — EC2 node disk/network/CPU metrics

**Verify:**

```bash
kubectl get pods -n monitoring        # prometheus, grafana, alertmanager, node-exporter should be Running
helm list -n monitoring               # qbshop-monitoring should show as deployed
```

**Upgrade / Uninstall:**

```bash
# To update settings (e.g., change password):
helm upgrade qbshop-monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword='newpassword'

# To uninstall:
helm uninstall qbshop-monitoring -n monitoring
```

### Monitoring Files — Custom Setup (Advanced)

> The `kube-prometheus-stack` Helm chart provides complete out-of-the-box monitoring.
> If you need custom dashboards, alerts, or app-specific metrics, add these files to the project:

**Where to place monitoring files in the project:**

```
Qualibytes-Ecommerce/
├── monitoring/                          # ← Create this new folder
│   ├── Chart.yaml                       # Helm chart definition
│   ├── values.yaml                      # Prometheus/Grafana configuration
│   └── templates/
│       ├── servicemonitor.yaml          # Scrape QBShop app metrics via Prometheus
│       ├── prometheusrule.yaml          # Custom alert rules
│       └── grafana-dashboard-cm.yaml    # Pre-built QBShop Grafana dashboard
```

**1. ServiceMonitor — Scrape App Metrics (`monitoring/templates/servicemonitor.yaml`):**

```yaml
# Tells Prometheus to collect metrics from the QBShop app
# Requires a /api/metrics endpoint in the app (using prom-client library)
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: qbshop-monitor
  namespace: qbshop
  labels:
    app: qbshop
spec:
  selector:
    matchLabels:
      app: qbshop
  endpoints:
    - port: http
      path: /api/metrics
      interval: 30s
  namespaceSelector:
    matchNames:
      - qbshop
```

**2. PrometheusRule — Custom Alerts (`monitoring/templates/prometheusrule.yaml`):**

```yaml
# Custom alert rules for QBShop
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: qbshop-alerts
  namespace: qbshop
spec:
  groups:
    - name: qbshop.availability
      rules:
        - alert: QBShopPodDown
          expr: kube_deployment_status_replicas_available{deployment="qbshop", namespace="qbshop"} < 1
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: "All QBShop pods are down!"

        - alert: QBShopHighCPU
          expr: |
            sum(rate(container_cpu_usage_seconds_total{namespace="qbshop", container="qbs-app"}[5m]))
            / sum(kube_pod_container_resource_limits{namespace="qbshop", container="qbs-app", resource="cpu"}) > 0.85
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "QBShop CPU usage is above 85%"

        - alert: MongoDBPodNotReady
          expr: kube_statefulset_status_replicas_ready{statefulset="mongodb", namespace="qbshop"} < 1
          for: 3m
          labels:
            severity: critical
          annotations:
            summary: "MongoDB pod is not ready!"

        - alert: QBShopAtMaxReplicas
          expr: |
            kube_horizontalpodautoscaler_status_current_replicas{namespace="qbshop"}
            >= kube_horizontalpodautoscaler_spec_max_replicas{namespace="qbshop"}
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "HPA is at maximum replicas — scaling limit reached"
```

**3. Expose Metrics in Next.js App (required if using ServiceMonitor):**

```bash
# Install prom-client in the app
cd Qualibytes-Ecommerce
npm install prom-client
```

```typescript
// src/app/api/metrics/route.ts — create this new file
import { NextResponse } from 'next/server';
import client from 'prom-client';

const register = new client.Registry();
client.collectDefaultMetrics({ register });

export async function GET() {
  const metrics = await register.metrics();
  return new NextResponse(metrics, {
    headers: { 'Content-Type': register.contentType },
  });
}
```

**4. Deploy Custom Monitoring:**

```bash
# Option A — Apply directly with kubectl
kubectl apply -f monitoring/templates/servicemonitor.yaml
kubectl apply -f monitoring/templates/prometheusrule.yaml

# Option B — Install as a Helm chart
cd monitoring/
helm dependency update .
helm install qbshop-monitoring . --namespace monitoring --values values.yaml
```

> **Note:** For basic monitoring, the `kube-prometheus-stack` installed in Step 11 is sufficient.
> Custom files (ServiceMonitor, PrometheusRule, dashboard) are only needed for app-specific metrics.

---

## ⚠️ Known Issues & Fixes

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| `jenkins: command not found` | `install_tools.sh` GPG key outdated + Java 17 | Install Java 21 + use keyserver method (see Step 4) |
| `Jenkins: Java 17 too old` | Jenkins 2.479+ requires Java 21 | `sudo apt install openjdk-21-jre` |
| `systemctl restart jenkins` fails | Restart limit hit from failed attempts | `sudo systemctl reset-failed jenkins && sudo systemctl start jenkins` |
| Docker `permission denied` in Jenkins | Jenkins user not in docker group | `sudo chmod 666 /var/run/docker.sock && sudo systemctl restart jenkins` |
| `docker compose: unknown flag -d` | Docker Compose plugin missing | Install docker-compose binary manually (see Prerequisites) |
| MongoDB Pod `Pending` | EBS CSI Driver not installed / storageClassName missing | Install EBS CSI Driver (Step 6) + uncomment `storageClassName: gp2` |
| EBS CSI `CrashLoopBackOff` | IAM trust policy mismatch | Recreate role with correct OIDC trust policy (see Step 6) |
| ArgoCD `ClusterIssuer` CRD error | Cert-Manager CRDs not installed | `kubectl apply -f cert-manager.crds.yaml` manually |
| ArgoCD Job `immutable` error | Kubernetes Jobs cannot be patched | `kubectl delete job db-migration -n qbshop` + SYNC |
| Jenkins CI loop (double builds) | Webhook re-triggers on Jenkins commit | Add "Polling ignores commits from certain users" → `Jenkins CI` |
| Ingress `404 Not Found` | Host mismatch in ingress rules | Verify ingress hosts match your domain |
| Certificate `READY: False` | DNS not propagated or challenge failed | Wait 15 min, check `kubectl describe challenge -n qbshop` |
| `git push rejected` | Jenkins pushed between your commits | `git pull origin dev --no-rebase` then push |
| Shared library overwrites domain | `update_k8s_manifests.groovy` has hardcoded domain sed | Remove the ingress sed line from the shared library |
| Node group name not found | Terraform adds a dynamic suffix | Use `aws eks list-nodegroups` to get the actual name |
| `eksctl iamserviceaccount` fails | CloudFormation stack already exists | Delete stack (disable termination protection first) then retry |
| EC2 IP changed after restart | No Elastic IP assigned | Assign an Elastic IP or update the webhook URL |
| `helm repo not found` | Helm repos are session-scoped | Re-run `helm repo add` after EC2 restart |

---

## 🧹 Cleanup

```bash
# 1. Helm releases
helm uninstall qbshop-monitoring -n monitoring 2>/dev/null
helm uninstall nginx-ingress -n ingress-nginx
helm uninstall cert-manager -n cert-manager

# 2. ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. EBS CSI addon
aws eks delete-addon --cluster-name qualibytes-eks-cluster --addon-name aws-ebs-csi-driver --region ap-south-1

# 4. Terraform DESTROY (most important — stops billing)
cd terraform/
terraform destroy  # type 'yes', takes ~15 min
```

---

## 📁 Project Structure

```
Qualibytes-Ecommerce/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── api/                # Backend API routes
│   │   │   ├── auth/           #   login, register, logout, me, check
│   │   │   ├── products/       #   CRUD, search, filter, featured, books
│   │   │   ├── cart/           #   add, remove, get cart
│   │   │   └── orders/         #   create, list, get by id
│   │   ├── (auth)/             # Auth pages (login, register)
│   │   ├── shops/              # Shop category pages
│   │   ├── products/           # Product detail pages
│   │   ├── checkout/           # Checkout + success page
│   │   ├── profile/            # User profile, orders, wishlists
│   │   └── page.tsx            # Homepage
│   ├── components/             # React UI components (Navbar, Cards, Filters, etc.)
│   ├── lib/
│   │   ├── models/             # MongoDB Mongoose models
│   │   │   ├── product.ts      #   Product (title, price, categories, images, rating)
│   │   │   ├── user.ts         #   User (email, bcrypt password, role: user/admin)
│   │   │   ├── cart.ts         #   Cart (user ref, items[], auto-calculated total)
│   │   │   └── order.ts        #   Order (items, status, shippingAddress, paymentStatus)
│   │   ├── auth/utils.ts       # JWT create/verify (jose, HS256, 30-day expiry)
│   │   ├── db.ts               # MongoDB connection (Mongoose)
│   │   ├── features/           # Redux Toolkit slices
│   │   │   ├── auth/authSlice.ts    # isAuthenticated, currentUser (persisted to localStorage)
│   │   │   ├── cart/cartSlice.ts    # cartItems, wishlists, selectedSize (persisted to localStorage)
│   │   │   └── sidebar/sidebarSlice.ts  # sidebar open/close (not persisted)
│   │   └── store.ts            # Redux store configuration
│   ├── middleware.ts            # Route protection (JWT check, role-based, runs on edge runtime)
│   └── data/                   # Static data (categories, colors, shops list)
│
├── kubernetes/                  # Kubernetes manifests — ArgoCD monitors this folder (dev branch)
│   ├── 00-cluster-issuer.yml   #   Let's Encrypt ACME ClusterIssuer
│   ├── 01-namespace.yaml       #   qbshop namespace
│   ├── 02-mongodb-pv.yaml      #   PersistentVolume (hostPath — local only, skip on EKS)
│   ├── 03-mongodb-pvc.yaml     #   EMPTY FILE — StatefulSet creates its own PVC
│   ├── 04-configmap.yaml       #   Non-secret env vars (MONGODB_URI, URLs, NODE_ENV)
│   ├── 05-secrets.yaml         #   JWT_SECRET, NEXTAUTH_SECRET (change default values!)
│   ├── 06-mongodb-service.yaml #   MongoDB ClusterIP service (port 27017)
│   ├── 07-mongodb-statefulset.yaml  # MongoDB pod (uncomment storageClassName: gp2 for EKS)
│   ├── 08-qbshop-deployment.yaml    # App deployment (2 replicas, health probes, resource limits)
│   ├── 09-qbshop-service.yaml  #   App NodePort service (80→3000, NodePort 30000)
│   ├── 10-ingress.yaml         #   Nginx Ingress rules + TLS (UPDATE YOUR DOMAIN!)
│   ├── 11-hpa.yaml             #   HorizontalPodAutoscaler (CPU 70%, 2-5 replicas)
│   └── 12-migration-job.yaml   #   One-time Job — seeds 516 products into MongoDB
│
├── terraform/                   # AWS infrastructure
│   ├── provider.tf             #   AWS provider, region: ap-south-1
│   ├── variables.tf            #   instance_type, region, environment
│   ├── vpc.tf                  #   Custom VPC for EKS (public + private + intra subnets)
│   ├── ec2.tf                  #   Jenkins EC2 (Ubuntu 24.04, t2.medium, 25GB, default VPC)
│   ├── eks.tf                  #   EKS cluster + node group (t2.large SPOT, 2-3 nodes)
│   ├── outputs.tf              #   public_ip, eks_cluster_name, vpc_id
│   └── install_tools.sh        #   EC2 bootstrap script (⚠️ has bugs — see Step 4)
│
├── monitoring/                  # Custom monitoring (OPTIONAL — create if needed)
│   ├── Chart.yaml              #   Helm chart definition + kube-prometheus-stack dependency
│   ├── values.yaml             #   Prometheus/Grafana/Alertmanager configuration
│   └── templates/
│       ├── servicemonitor.yaml      # Scrape QBShop app /api/metrics endpoint
│       ├── prometheusrule.yaml      # Custom alerts (pod down, high CPU, MongoDB down, HPA max)
│       └── grafana-dashboard-cm.yaml # Pre-built QBShop Grafana dashboard
│
├── scripts/
│   ├── Dockerfile.migration    #   Docker image for seeding MongoDB
│   ├── migrate-data.ts         #   Reads .db/db.json → inserts products into MongoDB
│   └── tsconfig.json           #   TypeScript config for migration script
│
├── .db/
│   ├── db.json                 #   516 products data (all categories)
│   └── routes.json             #   URL routing rules (legacy json-server)
│
├── Dockerfile                   # Production multi-stage build (builder → runner ~200MB)
├── Dockerfile.dev               # Development build
├── docker-compose.yml           # Local development — builds + runs MongoDB, migration, app
├── Jenkinsfile                  # CI pipeline (7 stages, dev branch, Shared library)
├── next.config.js               # output: 'standalone' (REQUIRED for Docker)
├── .env                         # Default env vars (committed to repo, non-secret)
├── .env.local                   # Personal secrets (gitignored, read by docker-compose)
└── .dockerignore                # Files excluded from Docker build context
```

---

## 📝 Important Notes

- **Working branch is `dev`** — Jenkinsfile uses `GIT_BRANCH = "dev"`. Pipeline triggers only on dev branch pushes.
- **Shared Library name is `Shared`** (capital S) — must match `@Library('Shared')` in Jenkinsfile.
- **`03-mongodb-pvc.yaml` is an empty file** — the StatefulSet creates its own PVC via `volumeClaimTemplates`.
- **`storageClassName: gp2` is commented out** in `07-mongodb-statefulset.yaml` — uncomment it for EKS deployment.
- **`05-secrets.yaml` has placeholder values** — replace `change-this-in-production` before deploying.
- **`output: 'standalone'` in `next.config.js`** is required — without it, Docker image won't contain `server.js`.
- **`docker-compose.yml` includes `build:` directives** — it builds images locally from Dockerfiles, not just pulls.
- **Region is `ap-south-1`** (Mumbai) — the README previously mentioned `eu-west-1` which was incorrect.
- **EC2 public IPs change on restart** — assign an Elastic IP for a fixed address, or update webhook URLs after restart.
- **Helm repos are session-scoped** — re-run `helm repo add` commands after EC2 restart.
