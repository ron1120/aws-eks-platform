# AWS EKS Platform

Production-style AWS platform for deploying and operating applications on Kubernetes using **Terraform**, **Amazon EKS**, **Helm**, and **ArgoCD**.

This repository focuses on **infrastructure and GitOps**. The application source code lives in a separate repository.

## Project Goals

* Provision AWS infrastructure using Terraform
* Deploy and manage an Amazon EKS cluster
* Use GitOps with ArgoCD for continuous deployment
* Deploy applications with Helm
* Monitor the platform with Prometheus, Grafana, and Loki
* Demonstrate production-oriented DevOps and Platform Engineering practices

## Architecture

```
Application Repository
        │
GitHub Actions (CI)
        │
Build Docker Images
        │
Push Images to Amazon ECR
        │
Update Deployment Configuration
        │
ArgoCD
        │
Amazon EKS
        │
Frontend + Backend
        │
Amazon RDS PostgreSQL
```

## Technology Stack

| Layer | Tools |
|---|---|
| Cloud | AWS |
| Infrastructure as Code | Terraform |
| Container orchestration | Amazon EKS |
| Container registry | Amazon ECR |
| Database | Amazon RDS PostgreSQL |
| Package manager | Helm |
| GitOps | ArgoCD |
| Ingress | NGINX Ingress Controller |
| Observability | Prometheus, Grafana, Loki |
| CI | GitHub Actions |

## Repository Structure

```
.
├── terraform/              # AWS infrastructure (Terraform)
│   ├── main.tf             # Root module — wires child modules together
│   ├── variables.tf        # Input variable declarations
│   ├── outputs.tf          # Values exposed via `terraform output`
│   ├── providers.tf        # AWS + Kubernetes provider configuration
│   ├── versions.tf         # Explicit provider version requirements
│   ├── ecr.tf               # ECR repositories for the app images
│   ├── app-secrets.tf       # App namespace + Secret (DB creds, JWT key)
│   ├── example.tfvars      # Example variable values (safe to commit)
│   └── modules/
│       ├── vpc/             # VPC, subnets, NAT gateway, IGW
│       ├── eks/              # EKS cluster + managed node group
│       └── rds/               # RDS PostgreSQL instance
├── helm/                   # Helm charts for applications
│   ├── backend/            # FastAPI backend chart
│   └── frontend/           # React/Vite frontend chart (+ Ingress)
├── argocd/apps/            # ArgoCD Application manifests (GitOps)
├── monitoring/             # Prometheus / Grafana / Loki config (planned)
├── scripts/                # init-cluster.sh / destroy-cluster.sh
├── docs/                   # Additional documentation (planned)
└── .github/                # GitHub Actions workflows (planned)
```

## Current Status

| Phase | Component | Status |
|---|---|---|
| 1 | VPC (subnets, NAT, IGW) | Done |
| 2 | EKS cluster + node group | Done |
| 3 | NGINX Ingress + ArgoCD | Done |
| 4 | RDS PostgreSQL | Done |
| 5 | ECR repos + app namespace/Secret | Done |
| 6 | Application Helm charts (backend/frontend) | Done |
| 7 | CI/CD (GitHub Actions → ECR) | Planned |
| 8 | Monitoring stack | Planned |

## Prerequisites

Install the following tools locally:

| Tool | Purpose | Verify |
|---|---|---|
| [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | Authenticate and interact with AWS | `aws --version` |
| [Terraform](https://developer.hashicorp.com/terraform/install) | Provision infrastructure | `terraform version` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Manage Kubernetes (needed for EKS phase) | `kubectl version --client` |
| [Helm](https://helm.sh/docs/intro/install/) | Package manager for Kubernetes (later phases) | `helm version` |

### AWS credentials

Configure credentials with access to your target region:

```bash
aws configure
aws sts get-caller-identity
```

Ensure your IAM policy allows the region you deploy into (this project defaults to **us-east-1**).

## Getting Started — Terraform (VPC)

### 1. Configure variables

Variable values are **not** committed to git. Copy the example file and edit it:

```bash
cd terraform
cp example.tfvars terraform.tfvars
```

Key settings in `terraform.tfvars`:

| Variable | Description | Default |
|---|---|---|
| `project_name` | Prefix for resource names and tags | `aws-eks-platform` |
| `aws_region` | AWS region | `us-east-1` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `availability_zones` | AZs for subnet placement | `us-east-1a`, `us-east-1b` |
| `public_subnets` | Public subnet CIDRs (one per AZ) | `10.0.1.0/24`, `10.0.2.0/24` |
| `private_subnets` | Private subnet CIDRs (EKS nodes, RDS) | `10.0.10.0/24`, `10.0.20.0/24` |

### 2. Initialize Terraform

Downloads providers and modules:

```bash
terraform init
```

### 3. Preview changes

```bash
terraform plan
```

### 4. Apply infrastructure

```bash
terraform apply
```

This creates the VPC stack: VPC, public/private subnets across two AZs, Internet Gateway, and a single NAT Gateway (cost-optimized for dev/lab).

### 5. Read outputs

Root `outputs.tf` re-exports values from the VPC module:

```bash
terraform output
terraform output vpc_id
terraform output private_subnet_ids
terraform output -json
```

### 6. Tear down (when finished experimenting)

```bash
terraform destroy
```

Run destroy when you are not actively using the environment — the NAT Gateway incurs hourly charges.

## Terraform Layout

Understanding how configuration flows through the repo:

```
terraform.tfvars          →  actual values (local, gitignored)
       ↓
variables.tf              →  declares inputs (var.project_name, etc.)
       ↓
main.tf                   →  calls modules (creates infrastructure)
       ↓
modules/vpc/outputs.tf    →  module exposes vpc_id, subnet IDs, etc.
       ↓
outputs.tf                →  re-exports selected values for the CLI
```

**`main.tf`** defines *what to build*. **`outputs.tf`** defines *what to display* after apply.

## VPC Module Details

The VPC module wraps [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) and configures:

* **Public subnets** — resources that need direct internet access (load balancers)
* **Private subnets** — EKS worker nodes and RDS (outbound via NAT)
* **Single NAT Gateway** — one shared NAT for all private subnets (lower cost for dev; set `single_nat_gateway = false` in the module for HA in production)
* **EKS subnet tags** — `kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb` so the AWS Load Balancer Controller can discover subnets later

## Verify with AWS CLI

After `terraform apply`, cross-check resources in AWS:

```bash
# VPC
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=aws-eks-platform" \
  --region us-east-1 \
  --output table

# Subnets
aws ec2 describe-subnets \
  --filters "Name=tag:Project,Values=aws-eks-platform" \
  --region us-east-1 \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' \
  --output table

# NAT Gateways (billable while running)
aws ec2 describe-nat-gateways \
  --filter "Name=state,Values=available" \
  --region us-east-1 \
  --output table
```

## Responsibilities

This repository is responsible for:

* AWS infrastructure provisioning
* Kubernetes platform configuration
* GitOps configuration
* Application deployment configuration
* Monitoring and observability

This repository does **not** contain application source code.

## Deployment Flow

1. The application repository builds and tests the application.
2. Docker images are pushed to Amazon ECR.
3. Deployment configuration is updated in this repository.
4. ArgoCD detects the change.
5. ArgoCD deploys the new version to Amazon EKS.

## Deploying the App (TM-Project)

The `helm/backend` and `helm/frontend` charts deploy a Task Manager app
(FastAPI + Postgres + React/Vite, source in a separate local repo) into the
`tm-project` namespace. The Ingress in the frontend chart routes `/api` to
the backend Service and `/` to the frontend Service, so both are reached
through the **same** host — meaning the frontend must be built with the API
URL set to a relative path, not `localhost`.

**One-time setup**, after `terraform apply` has created the EKS cluster, ECR
repos, and the `tm-project-backend-secrets` Secret:

```bash
# 1. Get the ECR repository URLs
cd terraform
terraform output -json ecr_repository_urls
# {"tm-project-backend": "403113723064.dkr.ecr.us-east-1.amazonaws.com/tm-project-backend", ...}

# 2. Log in to ECR
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin 403113723064.dkr.ecr.us-east-1.amazonaws.com

# 3. Build + push the backend
cd /Users/ron/Desktop/TM-Project/backend
docker build -t 403113723064.dkr.ecr.us-east-1.amazonaws.com/tm-project-backend:latest .
docker push 403113723064.dkr.ecr.us-east-1.amazonaws.com/tm-project-backend:latest

# 4. Build + push the frontend — note the build arg: since the Ingress
#    serves both frontend and backend from the same host, the API URL must
#    be a relative path baked in at build time, not localhost.
cd ../frontend
docker build --build-arg VITE_API_URL=/api \
  -t 403113723064.dkr.ecr.us-east-1.amazonaws.com/tm-project-frontend:latest .
docker push 403113723064.dkr.ecr.us-east-1.amazonaws.com/tm-project-frontend:latest
```

Then update `image.repository` in `helm/backend/values.yaml` and
`helm/frontend/values.yaml` to the URLs above, commit and push (ArgoCD reads
these charts straight from this git repo), and apply the Applications:

```bash
kubectl apply -f argocd/apps/backend.yaml -f argocd/apps/frontend.yaml
```

(`scripts/init-cluster.sh` already applies everything in `argocd/apps/`, so
this step is only needed if you add these apps after the initial run.)

Find the app's public URL via the ingress-nginx load balancer:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
# open http://<EXTERNAL-IP-hostname>/
```

To ship a new version later: rebuild + push a new image tag, bump
`image.tag` in the relevant `values.yaml`, commit — ArgoCD's automated sync
picks it up (self-heal is on, so manual `kubectl edit` changes get reverted).

## Cost Awareness

Resources that incur ongoing charges even when idle:

| Resource | Approximate cost |
|---|---|
| NAT Gateway | ~$32+/month per gateway + data transfer |
| EKS control plane | ~$73/month |
| EC2 worker nodes | `t3.medium` × 2 ≈ $60/month (or ~$0.08/hr while running) |
| RDS PostgreSQL | `db.t4g.micro` ≈ $12/month (or ~$0.016/hr while running) |
| ECR storage | Negligible for a few images; lifecycle policy keeps only the last 10 |

Use `./scripts/destroy-cluster.sh` (or `terraform destroy`) to remove the whole stack when not in use — this is the main lever for cost control while learning. Set an [AWS Budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-create.html) alert on your account.

## Git and Secrets

The following are **gitignored** and must stay local:

* `terraform.tfvars` — your environment-specific values
* `*.tfstate` — Terraform state (contains resource IDs and metadata)
* `.terraform/` — downloaded providers and modules

**Committed** to git:

* `terraform/example.tfvars` — template for teammates
* `terraform/.terraform.lock.hcl` — pins provider versions

## Roadmap

1. **EKS** — cluster, managed node group, IRSA
2. **Ingress + GitOps** — NGINX Ingress Controller, ArgoCD bootstrap
3. **Applications** — Helm charts, ArgoCD Applications
4. **Data** — RDS PostgreSQL in private subnets
5. **CI/CD** — GitHub Actions pipeline in the application repo
6. **Observability** — kube-prometheus-stack, Loki, Grafana dashboards
7. **Remote state** — S3 backend + DynamoDB locking for team use

## License

See repository license file (if applicable).
