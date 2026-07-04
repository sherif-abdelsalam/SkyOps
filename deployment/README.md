# 🚀 SkyOps — Deployment & Infrastructure

This document covers the full DevOps stack: infrastructure provisioning, Kubernetes manifests, GitOps pipeline, secrets management, networking, TLS, and CI/CD.

---

## 📁 Directory Structure

```
deployment/
├── terraform/
│   ├── main.tf                        # Root module — wires everything together
│   ├── variables.tf
│   ├── backend.tf                     # S3 remote state
│   ├── dev.tfvars                     # Local only (gitignored) — see dev.tfvars.example
│   ├── dev.tfvars.example
│   ├── provider.tf
│   ├── helm.tf                        # NGINX Ingress, ArgoCD, cert-manager
│   ├── helm_eso.tf                    # External Secrets Operator + IRSA
│   ├── values/
│   │   ├── argocd-values.yaml
│   │   ├── argocd-image-updater.yaml  # Reference values (updater not yet enabled in helm.tf)
│   │   └── ingress-nginx-values.yaml
│   └── modules/
│       ├── network/                   # VPC, subnets, IGW, NAT, route tables
│       ├── eks/                       # EKS cluster, node groups, EBS CSI driver
│       └── ecr/                       # ECR repositories (auth, ui, weather)
│
├── k8s/
│   ├── base/
│   │   ├── auth/                      # Deployment + Service + Kustomization
│   │   ├── weather/                   # Deployment + Service + ExternalSecret
│   │   ├── ui/                        # Deployment + Service
│   │   └── mysql/                     # StatefulSet + headless Service + ExternalSecret + init Job
│   ├── environments/
│   │   └── dev/                       # Dev overlays (namespace: skyops-apps-dev)
│   │       ├── auth/kustomization.yaml
│   │       ├── weather/kustomization.yaml
│   │       ├── mysql/kustomization.yaml
│   │       └── ui/
│   │           ├── kustomization.yaml
│   │           └── ingress.yaml       # NGINX Ingress + TLS (UI only)
│   └── infra/
│       ├── cluster-secret-store.yaml  # ESO ClusterSecretStore → AWS Secrets Manager
│       └── cluster-issuer.yaml        # cert-manager ClusterIssuer (Let's Encrypt)
│
└── argocd/
    ├── bootsrap.yaml                  # App-of-Apps bootstrap (note: filename typo)
    ├── cluster-secrets.yaml           # ArgoCD app for k8s/infra
    ├── auth-app.yaml
    ├── weather-app.yaml
    ├── ui-app.yaml
    └── mysql-app.yaml
```

---

## 🏗️ Terraform

All AWS infrastructure is managed via Terraform with a modular structure.

### Prerequisites

- Terraform ≥ 1.5
- AWS CLI v2 with credentials that can create VPC, EKS, ECR, IAM, and read/write the S3 state bucket
- kubectl, Helm ≥ 3.x

### Modules

| Module | Resources |
|---|---|
| `modules/network` | VPC, public/private subnets, Internet Gateway, NAT Gateway, route tables |
| `modules/eks` | EKS cluster, managed node groups, OIDC provider, EBS CSI driver |
| `modules/ecr` | ECR repos: `skyops-auth`, `skyops-ui`, `skyops-weather` |

MySQL uses the public `mysql:8.0` image — no ECR repository.

### Provision

```bash
cd deployment/terraform

# Copy and fill in your values (dev.tfvars is gitignored)
cp dev.tfvars.example dev.tfvars

terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

aws eks update-kubeconfig --name <eks_name> --region <region>
```

### ECR Repositories

```hcl
# modules/ecr/main.tf
locals {
  services = ["skyops-weather", "skyops-ui", "skyops-auth"]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(local.services)
  name     = each.value
}
```

CI pushes images tagged with the git SHA and `:latest` (see [CI/CD](#-cicd--github-actions)).

### Helm Releases (via Terraform)

| File | Installs |
|---|---|
| `helm.tf` | NGINX Ingress, ArgoCD, cert-manager |
| `helm_eso.tf` | External Secrets Operator (+ IRSA, app/ESO namespaces) |

Helm values:

- `values/argocd-values.yaml` — ArgoCD server + ingress
- `values/ingress-nginx-values.yaml` — NLB annotation, ingress class `nginx`
- `values/argocd-image-updater.yaml` — prepared for Image Updater (install currently commented out in `helm.tf`)

---

## ☸️ Kubernetes — Kustomize

Manifests follow a `base/` + `environments/dev/` overlay pattern. All dev workloads run in namespace **`skyops-apps-dev`**.

### Base

| Service | Manifests |
|---|---|
| `auth` | `deployment.yaml`, `service.yaml`, `kustomization.yaml` |
| `weather` | `deployment.yaml`, `service.yaml`, `external-secrets.yaml`, `kustomization.yaml` |
| `ui` | `deployment.yaml`, `service.yaml`, `kustomization.yaml` |
| `mysql` | `statefulset.yaml`, `headless-service.yaml`, `external-secrete.yaml`, `init-job.yaml`, `kustomization.yaml` |

K8s service DNS names used by the UI: `weatherapp-auth:8080`, `weatherapp-weather:5000`.

### Dev Overlay

Each overlay under `environments/dev/<service>/` references the matching `base/` directory and sets `namespace: skyops-apps-dev`.

| Overlay | Adds beyond base |
|---|---|
| `dev/auth` | Namespace only |
| `dev/weather` | Namespace only |
| `dev/mysql` | Namespace only |
| `dev/ui` | Namespace + `ingress.yaml` (host, TLS, cert-manager annotations) |

Deploy manifests are synced by ArgoCD — do not `kubectl apply` overlays manually unless debugging.

### Infra (`k8s/infra/`)

Synced by the ArgoCD app `cluster-secret-store`:

- **ClusterSecretStore** `aws-secrets` — ESO reads AWS Secrets Manager in `eu-north-1` via IRSA
- **ClusterIssuer** `letsencrypt-dev` — Let's Encrypt ACME HTTP-01 via NGINX ingress class

---

## 🔄 CI/CD — GitHub Actions

Workflow: [`.github/workflows/skyops-ci.yaml`](../.github/workflows/skyops-ci.yaml)

Triggered on push to `main` / `master` when files change under `apps/auth/`, `apps/UI/`, or `apps/weather/`.

| Job | Context | ECR image |
|---|---|---|
| `build-auth` | `./apps/auth` | `skyops-auth:<sha>` + `:latest` |
| `build-ui` | `./apps/UI` | `skyops-ui:<sha>` + `:latest` |
| `build-weather` | `./apps/weather` | `skyops-weather:<sha>` + `:latest` |

### Required GitHub Secrets

| Secret | Purpose |
|---|---|
| `AWS_ACCESS_KEY_ID` | ECR push |
| `AWS_SECRET_ACCESS_KEY` | ECR push |
| `AWS_REGION` | ECR login |
| `AWS_ACCOUNT_ID` | ECR registry URL |

### Pipeline Flow (current)

```
push to main (apps/* changed)
        │
        ▼
GitHub Actions — build & push to ECR (:latest + git SHA)
        │
        ▼
Deployments reference :latest in base manifests
        │
        ▼
ArgoCD sync (manual refresh or pod restart may be needed for :latest)
        │
        ▼
Rolling update on EKS
```

> **Note:** ArgoCD Image Updater is not fully enabled yet (Helm install commented out; only `auth-app.yaml` has updater annotations). Today, new `:latest` images require an ArgoCD sync or rollout restart to pick up changes.

---

## 🔁 ArgoCD — GitOps

ArgoCD is installed on EKS via Terraform and manages all application manifests from this repository.

### Bootstrap (App-of-Apps)

```bash
kubectl apply -f deployment/argocd/bootsrap.yaml -n argocd
```

`bootsrap.yaml` creates an ArgoCD `Application` named `bootstrap` that watches `deployment/argocd/`. That directory contains all other Application CRs — ArgoCD creates them automatically.

### Application CRs

| ArgoCD App | Source path | Purpose |
|---|---|---|
| `bootstrap` | `deployment/argocd` | App-of-Apps root |
| `auth` | `deployment/k8s/environments/dev/auth` | Auth deployment |
| `weather` | `deployment/k8s/environments/dev/weather` | Weather deployment |
| `ui` | `deployment/k8s/environments/dev/ui` | UI + Ingress |
| `mysql-db` | `deployment/k8s/environments/dev/mysql` | MySQL StatefulSet + init Job |
| `cluster-secret-store` | `deployment/k8s/infra` | ESO store + cert-manager ClusterIssuer |

All apps use automated sync with prune and self-heal.

---

## 🔐 Secrets — External Secrets Operator

Secrets live in **AWS Secrets Manager** and are synced into Kubernetes `Secret` objects by ESO. Nothing sensitive is committed to Git.

### Architecture

```
AWS Secrets Manager
        │  (IRSA — no static AWS keys in cluster)
        ▼
External Secrets Operator
        │
        ▼
Kubernetes Secret  →  Pod env vars
```

### Dev secrets (AWS Secrets Manager keys)

| Remote key | K8s secret | Keys |
|---|---|---|
| `skyops-dev/auth-password` | `skyops-db-auth` | `auth-password` |
| `skyops-dev/root-password` | `skyops-db-auth` | `root-password` |
| `skyops-dev/secret-key` | `skyops-db-auth` | `secret-key` |
| `skyops-dev/apikey` | `skyops-weather-auth` | `apikey` |

---

## 🌐 Networking — NLB + NGINX Ingress

```
Internet
   │
   ▼
AWS NLB  (Layer 4 — LoadBalancer Service annotation on ingress-nginx)
   │
   ▼
NGINX Ingress Controller  (ingress class: nginx)
   │
   └──▶  skyops.fortstak.online /  →  weatherapp-ui:3000
```

Internal service-to-service traffic stays inside the cluster (ClusterIP).

---

## 🔒 TLS — HTTPS

TLS is configured for the dev environment:

1. **cert-manager** installed via Terraform (`helm.tf`)
2. **ClusterIssuer** `letsencrypt-dev` in `k8s/infra/cluster-issuer.yaml` (synced by ArgoCD)
3. **UI Ingress** (`environments/dev/ui/ingress.yaml`):
   - Host: `skyops.fortstak.online`
   - Annotation: `cert-manager.io/cluster-issuer: letsencrypt-dev`
   - TLS secret: `skyops-tls`
   - SSL redirect enabled

```
Let's Encrypt (ACME)
      │
      ▼
cert-manager
      │
      ▼
Secret skyops-tls
      │
      ▼
NGINX Ingress (TLS termination)
      │
      ▼
UI pod (HTTP on port 3000)
```

---

## 🔗 Related

- [← Back to root README](../README.md)
- [📦 Applications documentation](../apps/README.md)
