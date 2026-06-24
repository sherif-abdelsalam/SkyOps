# ☁️ SkyOps

> A production-grade, cloud-native weather platform deployed on AWS EKS using a full GitOps workflow.

SkyOps is a cloud-native weather application built with a microservices architecture. It provides user authentication and real-time weather information through a modern web interface while showcasing production-grade DevOps practices including Kubernetes, GitOps, CI/CD automation, Infrastructure as Code, and secure secrets management on AWS.

## 🏗️ Architecture Overview

![skyops-aws-arch.png](./skyops-aws-arch.png)


---

## 📁 Repository Structure

```
SkyOps/
├── apps/
│   ├── auth/                # Auth service (Go)
│   ├── UI/                  # Frontend (Node.js/JS)
│   ├── weather/             # Weather backend (Python)
│   ├── mysql-init/          # MySQL init SQL scripts
│   └── README.md            # ← Microservices documentation
│
├── deployment/
│   ├── terraform/           # AWS infra (EKS, ECR, VPC, ESO, NGINX, ArgoCD)
│   ├── k8s/                 # Kustomize manifests (base + dev overlay)
│   ├── argocd/              # ArgoCD Application + bootstrap
│   └── README.md            # ← DevOps & deployment documentation
│
└── README.md                # ← Project documentation
```

---

## 📖 Documentation

| Section | Description |
|---|---|
| [📦 Applications](./apps/README.md) | Services overview, local dev, environment variables, API references |
| [🚀 Deployment & Infrastructure](./deployment/README.md) | Terraform, EKS, ArgoCD, GitOps pipeline, Image Updater, TLS, secrets |

---

## ⚙️ Tech Stack

**Application**
- Go (auth) · Python (weather) · Node.js/JS (UI) · MySQL 8

**Infrastructure**
- Terraform · AWS EKS · Amazon ECR · AWS VPC · AWS Secrets Manager 

**GitOps & CI/CD**
- ArgoCD · ArgoCD Image Updater · GitHub Actions · Kustomize

**Networking & Security**
- NGINX Ingress Controller · AWS NLB · External Secrets Operator · AWS Secrets Manager

**Observability** *(planned)*
- Prometheus · Grafana