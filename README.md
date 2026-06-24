# ☁️ SkyOps

> A production-grade, cloud-native weather platform deployed on AWS EKS using a full GitOps workflow.

SkyOps is a multi-service application built as a real-world DevOps portfolio project. It demonstrates end-to-end infrastructure automation — from infrastructure provisioning with Terraform, to GitOps-driven continuous delivery with ArgoCD, to automated image updates via ArgoCD Image Updater.

---

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

---

## 🚀 Quick Start

1. **Provision infrastructure** → [Terraform](./deployment/README.md#terraform)
2. **Bootstrap ArgoCD** → [ArgoCD Setup](./deployment/README.md#argocd-setup)
3. **Run apps locally** → [Local Development](./apps/README.md#local-development)
