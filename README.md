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
- **DockerHub Account** — images push hone ke liye

### Required Tools (Host/Bastion EC2 pe install karo)

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
# LOGOUT and LOGIN again for group to take effect

# Docker Compose Plugin (Ubuntu docker.io mein nahi aata)
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker compose version

# 5. kubectl + Helm
sudo snap install kubectl --classic
sudo snap install helm --classic

# 6. eksctl (EBS CSI Driver setup ke liye)
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

> ⚠️ **IMPORTANT:** 2 repos fork karo aur DockerHub username update karo

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

> This step is optional — production deployment ArgoCD se hoti hai. Yeh sirf local testing ke liye hai to verify app works before deploying to EKS.

**`docker-compose.yml` mein `build:` directive HAI** — yeh khud Dockerfile se images build karta hai (sirf pull nahi karta).

3 services hain: MongoDB → Migration (seed 516 products) → App (Next.js)

```bash
cd ~/Qualibytes-Ecommerce

# DockerHub login (optional — build ke liye zaruri nahi, push ke liye chahiye)
docker login

# .env.local file banao (Docker Compose isse read karta hai)
# EC2 pe test kar rahe ho toh EC2 ka PUBLIC IP daalo, localhost nahi
# Secrets generate karo pehle:
echo "NEXTAUTH_SECRET: $(openssl rand -base64 32)"
echo "JWT_SECRET: $(openssl rand -hex 32)"

cat > .env.local << 'EOF'
MONGODB_URI=mongodb://qbs-mongodb:27017/easyshop
NEXTAUTH_URL=http://<YOUR-EC2-PUBLIC-IP>:3000
NEXT_PUBLIC_API_URL=http://<YOUR-EC2-PUBLIC-IP>:3000/api
NEXTAUTH_SECRET=paste_generated_base64_here
JWT_SECRET=paste_generated_hex_here
EOF

# Edit karo aur actual values paste karo
nano .env.local

# Run karo (first time ~10-15 min build lagega)
docker compose up -d

# Verify
docker ps                     # 2 containers: qbs-mongodb, qbs-app
docker logs qbs-migration     # "Migrated 516 products" dikhna chahiye

# Browser: http://<EC2-IP>:3000
# EC2 security group mein port 3000 open karo

# Cleanup (EKS deploy se pehle)
docker compose down
```

> **Notes:**
> - `.env` file repo mein hai (common defaults), `.env.local` personal secrets ke liye hai (gitignored)
> - MONGODB_URI mein container name `qbs-mongodb` use karo — `localhost` docker network mein kaam nahi karega
> - Build time pe `ECONNREFUSED 127.0.0.1:27017` errors NORMAL hain — runtime pe docker network se connect hoga
> - `docker login` nahi kiya toh "pull access denied" warning aayegi but build se kaam chal jaayega

### Step 4 — Fix Jenkins on Jenkins EC2

> ⚠️ **KNOWN ISSUE:** `install_tools.sh` has 2 bugs:
> 1. Installs Java 17 — Jenkins 2.479+ requires **Java 21**
> 2. Jenkins GPG key method is outdated — keyserver method needed

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

# If restart limit hit:
sudo systemctl reset-failed jenkins
sudo systemctl start jenkins

# Docker permission for Jenkins
sudo usermod -aG docker jenkins
sudo chmod 666 /var/run/docker.sock
sudo systemctl restart jenkins

# Configure AWS CLI on Jenkins EC2 too (pipeline needs EKS access)
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
   - Payload URL: `http://<JENKINS-EC2-IP>:8080/github-webhook/`
   - Content type: `application/json`
   - Events: Just the push event
9. Click **Build Now** — all stages should be green

### Step 6 — EBS CSI Driver (Required for MongoDB Storage)

> ⚠️ **Without this, MongoDB pod will stay in Pending state**

```bash
# On Host/Bastion EC2:

# 1. Get node group name (Terraform adds dynamic suffix)
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

# 4. Install EBS CSI addon with role
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws eks create-addon \
  --cluster-name qualibytes-eks-cluster \
  --addon-name aws-ebs-csi-driver --region ap-south-1 \
  --service-account-role-arn arn:aws:iam::${ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole

# 5. Verify (wait 2-3 min)
kubectl get pods -n kube-system | grep ebs
# ebs-csi-controller: 6/6 Running
```

**If controller shows CrashLoopBackOff (trust policy mismatch):**
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
kubectl get svc -n ingress-nginx         # Note EXTERNAL-IP (LoadBalancer hostname)
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
kubectl get crds | grep cert-manager     # 6 CRDs
```

### Step 9 — ArgoCD (GitOps)

```bash
# Install
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd -w  # Wait for all Running

# Access
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
kubectl port-forward svc/argocd-server -n argocd 8085:443 --address=0.0.0.0 &

# Password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Browser: https://<HOST-EC2-IP>:8085
# Username: admin | Password: above output
```

**ArgoCD Password Reset (agar password bhool gaye ya login nahi ho raha):**

```bash
# Method 1 — Initial secret se password nikalo
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Method 2 — Agar secret delete ho gaya, naya password set karo
# argocd CLI install karo
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd && sudo mv argocd /usr/local/bin/

# Admin password reset karo
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "'$(htpasswd -nbBC 10 "" admin123 | tr -d ':\n' | sed 's/$2y/$2a/')'", "admin.passwordMtime": "'$(date +%FT%T%Z)'"}}'

# ArgoCD server restart karo
kubectl rollout restart deployment argocd-server -n argocd
sleep 60

# Ab login karo: admin / admin123

# htpasswd nahi hai toh install karo:
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

> ⚠️ **Job Immutable Error:** If ArgoCD fails to sync `db-migration` Job, run:
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

1. Get LoadBalancer hostname:
```bash
kubectl get svc -n ingress-nginx | grep LoadBalancer
# Copy EXTERNAL-IP hostname
```

2. In your domain registrar (GoDaddy/Hostinger), add CNAME:

| Type | Name | Value |
|------|------|-------|
| CNAME | qbshop | `xxxx.ap-south-1.elb.amazonaws.com` |

3. Wait 5-15 min for DNS propagation
4. Verify:
```bash
nslookup qbshop.yourdomain.com
kubectl get certificate -n qbshop   # READY: True
```

5. Browser: `https://qbshop.yourdomain.com`

### Step 11 — Monitoring (Optional)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install qbshop-monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword='qbshop@grafana123' \
  --set prometheus.prometheusSpec.retention=15d

# Grafana access
kubectl port-forward svc/qbshop-monitoring-grafana -n monitoring 3001:80 --address=0.0.0.0 &
# Browser: http://<HOST-EC2-IP>:3001
# Username: admin | Password: qbshop@grafana123
```

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
| ArgoCD Job `immutable` error | K8s Jobs can't be patched | `kubectl delete job db-migration -n qbshop` + SYNC |
| Jenkins CI loop (double builds) | Webhook re-triggers on Jenkins commit | Add "Polling ignores commits from certain users" → `Jenkins CI` |
| Ingress `404 Not Found` | Host mismatch in ingress rules | Verify ingress hosts match your domain |
| Certificate `READY: False` | DNS not propagated or challenge failed | Wait 15 min, check `kubectl describe challenge -n qbshop` |
| `git push rejected` | Jenkins pushed between your commits | `git pull origin dev --no-rebase` then push |
| Shared library overwrites domain | `update_k8s_manifests.groovy` has hardcoded domain sed | Remove ingress sed line from shared library |
| Node group name not found | Terraform adds dynamic suffix | Use `aws eks list-nodegroups` to get actual name |
| `eksctl iamserviceaccount` fails | CloudFormation stack already exists | Delete stack (disable termination protection first) then retry |
| EC2 IP changed after restart | No Elastic IP assigned | Assign Elastic IP or update webhook URL |
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
│   ├── app/              # Next.js App Router (pages + API routes)
│   ├── components/       # React UI components
│   ├── lib/
│   │   ├── models/       # MongoDB models (Product, User, Cart, Order)
│   │   ├── auth/         # JWT authentication utilities
│   │   ├── features/     # Redux slices (auth, cart, sidebar)
│   │   └── store.ts      # Redux store configuration
│   └── middleware.ts      # Route protection middleware
├── kubernetes/            # K8s manifests (ArgoCD monitors this folder)
├── terraform/             # AWS infrastructure (VPC, EC2, EKS)
├── scripts/               # Migration script + Dockerfile.migration
├── .db/                   # Seed data (516 products)
├── Dockerfile             # Production multi-stage build
├── Dockerfile.dev         # Development build
├── docker-compose.yml     # Local development (builds + runs app)
├── Jenkinsfile            # CI pipeline definition
└── next.config.js         # output: 'standalone' (required for Docker)
```

---

## 📝 Important Notes

- **Working branch is `dev`** — Jenkinsfile uses `GIT_BRANCH = "dev"`. Pipeline triggers on dev branch pushes only.
- **Shared Library name is `Shared`** (capital S) — must match `@Library('Shared')` in Jenkinsfile.
- **`03-mongodb-pvc.yaml` is an empty file** — StatefulSet creates its own PVC via `volumeClaimTemplates`.
- **`storageClassName: gp2` is commented out** in `07-mongodb-statefulset.yaml` — uncomment for EKS.
- **`05-secrets.yaml` has placeholder values** — change `change-this-in-production` before deploying.
- **`output: 'standalone'` in `next.config.js`** is required — without it, Docker image won't have `server.js`.
- **`docker-compose.yml` has `build:` directives** — it builds images locally, not just pulls.
- **Region is `ap-south-1`** (Mumbai) — README previously mentioned `eu-west-1` which was incorrect.
