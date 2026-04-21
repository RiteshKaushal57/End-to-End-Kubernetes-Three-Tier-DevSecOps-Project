

# 🚀 End-to-End DevSecOps on Kubernetes (EKS) — Jenkins + ArgoCD + Terraform

A production-grade DevSecOps implementation of a three-tier microservices application (Frontend, Backend, MongoDB) on AWS EKS, built using CI/CD pipelines and GitOps principles.

> Built as a hands-on project to demonstrate real-world DevOps, DevSecOps, and cloud-native deployment practices.

---

# 📌 What This Project Does

This project deploys a full-stack application using modern DevSecOps practices:

* Infrastructure is provisioned using **Terraform**
* Applications are containerized using **Docker**
* CI pipelines are built using **Jenkins (Kubernetes agents)**
* Security is integrated using **SonarQube and Trivy**
* Images are built using **Kaniko (Dockerless builds)**
* Deployment is managed using **ArgoCD (GitOps)**
* Applications are packaged using **Helm charts**
* Traffic is routed using **AWS ALB Ingress**

Everything is automated — no manual deployment steps.

---

# 🏗️ Architecture

```
User
  │
  ▼
AWS ALB (Ingress)
  │
  ├───────────────┬───────────────┐
  ▼               ▼               ▼
Frontend       Backend         MongoDB
  │               │
  └──────► /api ◄─┘

CI/CD Flow:
GitHub → Jenkins → DockerHub → ArgoCD → Kubernetes
```

---

# 📁 Project Structure

```
.
├── Application-Code/
│   ├── frontend/                # React application
│   └── backend/                 # Node.js API
│
├── ArgoCD/
│   ├── frontend/                # Helm chart (frontend)
│   └── backend/                 # Helm chart (backend)
│
├── k8/
│   ├── argocd/                  # ArgoCD setup
│   ├── jenkins/                 # Jenkins deployment
│   ├── sonarqube/               # SonarQube setup
│   └── ingress/                 # ALB ingress config
│
├── terraform/
│   ├── modules/                 # VPC, EKS modules
│   └── main.tf                  # Infra provisioning
│
└── Jenkinsfiles/
    ├── frontend.Jenkinsfile
    └── backend.Jenkinsfile
```

---

# ⚙️ DevSecOps Pipeline

## CI Pipeline (Jenkins)

* Checkout code from GitHub
* Install dependencies
* Run unit tests
* Perform SonarQube analysis
* Enforce Quality Gate
* Run Trivy filesystem scan
* Build Docker image using Kaniko
* Push image to DockerHub
* Update Helm values.yaml
* Commit and push changes to Git

---

## CD Pipeline (ArgoCD)

* Monitors Git repository
* Detects Helm value changes
* Syncs automatically with Kubernetes
* Deploys updated image
* Performs rolling updates

---

# 🔐 Security Implementation

* Static code analysis using **SonarQube**
* Vulnerability scanning using **Trivy**
* Docker images built securely using **Kaniko**
* Containers run as **non-root users**
* Sensitive data managed via **Kubernetes secrets**

---

# 🐳 Containerization

* Multi-stage Docker builds
* Optimized production images
* Frontend served via **Nginx**
* Backend built using **Node.js Alpine**
* Images stored in **DockerHub**

---

# ☸️ Kubernetes Deployment

* Deployed on **AWS EKS**
* **ALB Ingress Controller** for external access
* Path-based routing:

  * `/` → Frontend
  * `/api` → Backend
* Rolling updates with zero downtime

---

# 📦 Deployment Strategy

* Helm charts for application packaging
* Git as the single source of truth
* ArgoCD auto-sync enabled
* Fully automated deployments (no kubectl apply)

---

# 🚀 How to Run This Project

## Prerequisites

* AWS account
* Terraform installed
* kubectl configured
* Docker installed
* Jenkins & ArgoCD setup

---

## Step 1 — Provision Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

---

## Step 2 — Deploy Jenkins & SonarQube

```bash
kubectl apply -f k8/jenkins/
kubectl apply -f k8/sonarqube/
```

---

## Step 3 — Setup ArgoCD

```bash
kubectl apply -f k8/argocd/
```

Access UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

## Step 4 — Run Jenkins Pipelines

* Create pipelines for frontend and backend
* Connect GitHub repository
* Trigger builds

---

## Step 5 — Access Application

```bash
kubectl get ingress -n dev
```

Open ALB DNS in browser.

---

## Step 6 — Destroy Resources

```bash
terraform destroy
```

Always destroy resources to avoid AWS charges.

---

# 🧠 Key Learnings

* CI/CD pipelines must integrate **security, not just automation**
* Dockerfile mistakes can break entire pipelines
* GitOps simplifies Kubernetes deployments significantly
* Debugging is a critical DevOps skill
* Small misconfigurations (permissions, paths, auth) cause real failures

---

# 🛠️ Tools Used

| Tool                | Purpose                 |
| ------------------- | ----------------------- |
| AWS (EKS, ALB, VPC) | Cloud infrastructure    |
| Terraform           | Infrastructure as Code  |
| Kubernetes          | Container orchestration |
| Docker              | Containerization        |
| Jenkins             | CI pipeline             |
| ArgoCD              | GitOps CD               |
| Helm                | Package management      |
| SonarQube           | Code quality            |
| Trivy               | Security scanning       |
| Kaniko              | Image build             |
| MongoDB             | Database                |
| Node.js             | Backend                 |
| React               | Frontend                |

---

# 💰 Cost Note

This setup includes:

* EKS cluster
* ALB
* Multiple workloads

👉 Always clean up:

```bash
terraform destroy
```
