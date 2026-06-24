# 🚀 SkyOps — Deployment & Infrastructure

This document covers the full DevOps stack: infrastructure provisioning, Kubernetes manifests, GitOps pipeline, secrets management, networking, and CI/CD.

---

## 📁 Directory Structure

```
deployment/
├── terraform/
│   ├── main.tf                        # Root module — wires everything together
│   ├── variables.tf
│   ├── backend.tf                     # S3 remote state
│   ├── dev.tfvars
│   ├── provider.tf
│   ├── helm.tf                        # ArgoCD + NGINX Ingress via Helm
│   ├── helm_eso.tf                    # External Secrets Operator via Helm
│   ├── values/
│   │   ├── argocd-values.yaml
│   │   ├── argocd-image-updater.yaml
│   │   └── ingress-nginx-values.yaml
│   └── modules/
│       ├── network/                   # VPC, subnets, IGW, NAT, route tables
│       ├── eks/                       # EKS cluster, node groups, CSI storage
│       └── ecr/                       # ECR repositories (one per service)
│
├── k8s/
│   ├── base/
│   │   ├── auth/                      # Deployment + Service + Kustomization
│   │   ├── weather/                   # Deployment + Service + ExternalSecret
│   │   ├── ui/                        # Deployment + Service
│   │   └── mysql/                     # StatefulSet + headless Service + ExternalSecret + init Job
│   ├── environments/
│   │   └── dev/
│   │       ├── auth/kustomization.yaml
│   │       ├── weather/kustomization.yaml
│   │       ├── mysql/kustomization.yaml
│   │       └── ui/
│   │           ├── kustomization.yaml
│   │           └── ingress.yaml       # NGINX Ingress resource (UI only)
│   └── infra/
│       └── cluster-secret-store.yaml  # ESO ClusterSecretStore → AWS Secrets Manager
│
└── argocd/
    ├── bootsrap.yaml                  # ArgoCD App-of-Apps bootstrap
    ├── cluster-secrets.yaml           # Cluster connection secret
    ├── auth-app.yaml
    ├── weather-app.yaml
    ├── ui-app.yaml
    └── mysql-app.yaml
```

---

## 🏗️ Terraform

All AWS infrastructure is managed via Terraform with a modular structure.

### Prerequisites

```bash
terraform >= 1.5
aws-cli v2, configured with appropriate IAM permissions
kubectl
helm >= 3.x
```

### Modules

| Module | Resources |
|---|---|
| `modules/network` | VPC, public/private subnets, Internet Gateway, NAT Gateway, route tables |
| `modules/eks` | EKS cluster, managed node groups, OIDC provider, EBS CSI driver |
| `modules/ecr` | One ECR repo per service |

### Provision

```bash
cd deployment/terraform

terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# Update kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

### ECR — One Repo Per Service

The ECR module creates one repository per service using `for_each`:

```hcl
# modules/ecr/main.tf
variable "services" {
  default = ["weather", "auth", "ui", "mysql"]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(var.services)
  name     = "skyops-${each.key}"
}
```

### Helm Releases (in Terraform)

ArgoCD, ArgoCD Image Updater, and NGINX Ingress are all installed via Terraform's Helm provider:

- `helm.tf` — ArgoCD + ArgoCD Image Updater
- `helm_eso.tf` — External Secrets Operator
- `values/argocd-values.yaml` — ArgoCD Helm values
- `values/argocd-image-updater.yaml` — Image Updater Helm values
- `values/ingress-nginx-values.yaml` — NGINX Ingress values (NLB annotations)

---

## ☸️ Kubernetes — Kustomize

Manifests follow a `base/` + `environments/` overlay pattern.

### Base

Each service under `base/` contains the core manifests that are environment-agnostic:

| Service | Manifests |
|---|---|
| `auth` | `deployment.yaml`, `service.yaml`, `kustomization.yaml` |
| `weather` | `deployment.yaml`, `service.yaml`, `external-secrets.yaml`, `kustomization.yaml` |
| `ui` | `deployment.yaml`, `service.yaml`, `kustomization.yaml` |
| `mysql` | `statefulset.yaml`, `headless-service.yaml`, `external-secrete.yaml`, `init-job.yaml`, `kustomization.yaml` |

### Dev Overlay

  `environments/dev/`



---

## 🔄 CI/CD — GitHub Actions

Each service has a workflow triggered on push to `main`. The pipeline builds, tags, and pushes the Docker image to ECR. ArgoCD Image Updater then picks up the new tag automatically.

### Pipeline Flow

```
push to main
    │
    ▼
Build Docker image
    │
    ▼
Login to ECR 
    │
    ▼
Push image → ECR  (tagged: git SHA)
    │
    ▼
ArgoCD Image Updater detects new digest/tag
    │
    ▼
Auto-commits updated tag → kustomization.yaml
    │
    ▼
ArgoCD syncs → rolling update on EKS
```

## 🔁 ArgoCD — GitOps

ArgoCD is deployed inside EKS (via Terraform Helm) and watches `deployment/k8s/environments/dev/` for changes.

### Bootstrap (App-of-Apps)

```bash
# Apply the bootstrap App-of-Apps
kubectl apply -f deployment/argocd/bootsrap.yaml -n argocd
```

`bootsrap.yaml` is an ArgoCD `Application` that points to the `argocd/` directory — ArgoCD then creates all other Application CRs automatically.

### Application CRs

Each service has its own ArgoCD `Application` in `deployment/argocd/`:



---

## 🖼️ ArgoCD Image Updater

Image Updater polls ECR for new image tags and commits the updated tag back to `kustomization.yaml`, triggering an ArgoCD sync automatically.

### How It Works

```
New image pushed to ECR
        │
        ▼
Image Updater polls ECR (newest-build strategy)
        │
        ▼
Commits new tag → kustomization.yaml in Git
        │
        ▼
ArgoCD detects Git diff → syncs → rolling update
```


## 🔐 Secrets — External Secrets Operator

Secrets are stored in **AWS Secrets Manager** and synced into Kubernetes `Secret` objects by ESO. No secrets are stored in Git.

### Architecture

```
AWS Secrets Manager
        │  (IRSA — no static keys)
        ▼
External Secrets Operator
        │
        ▼
Kubernetes Secret  →  Pod env vars
```


---

## 🌐 Networking — NLB + NGINX Ingress

External traffic flows through an AWS Network Load Balancer → NGINX Ingress Controller → services.

```
Internet
   │
   ▼
AWS NLB  (Layer 4 — provisioned by AWS via Service annotation)
   │
   ▼
NGINX Ingress Controller  (Layer 7 — path-based routing)
   │
   └──▶  /      →  ui-service:80
```

---

## 🔒 TLS — HTTPS *(coming soon)*

TLS termination will be added at the NGINX Ingress layer using **cert-manager** with Let's Encrypt.

### Planned Setup

```
Let's Encrypt (ACME)
      │
      ▼
cert-manager (in-cluster)
      │  auto-issues & renews certificates
      ▼
Kubernetes TLS Secret
      │
      ▼
NGINX Ingress (TLS termination)
      │
      ▼
Services (plain HTTP internally)
```

## 🔗 Related

- [← Back to root README](../README.md)
- [📦 Applications documentation](../apps/README.md)