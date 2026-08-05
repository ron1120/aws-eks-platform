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
│   ├── providers.tf        # AWS provider configuration
│   ├── example.tfvars      # Example variable values (safe to commit)
│   └── modules/
│       └── vpc/            # VPC, subnets, NAT gateway, IGW
├── helm/                   # Helm charts for applications (planned)
├── argocd/                 # ArgoCD Application manifests (planned)
├── monitoring/             # Prometheus / Grafana / Loki config (planned)
├── scripts/                # Helper scripts (planned)
├── docs/                   # Additional documentation (planned)
└── .github/                # GitHub Actions workflows (planned)
```

## Current Status

| Phase | Component | Status |
|---|---|---|
| 1 | VPC (subnets, NAT, IGW) | Done |
| 2 | EKS cluster + node group | Planned |
| 3 | NGINX Ingress + ArgoCD | Planned |
| 4 | Application Helm charts | Planned |
| 5 | RDS PostgreSQL | Planned |
| 6 | CI/CD (GitHub Actions → ECR) | Planned |
| 7 | Monitoring stack | Planned |

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

## Cost Awareness

Resources that incur ongoing charges even when idle:

| Resource | Approximate cost |
|---|---|
| NAT Gateway | ~$32+/month per gateway + data transfer |
| EKS control plane | ~$73/month (when added) |
| EC2 worker nodes | Depends on instance type and count |
| RDS PostgreSQL | Depends on instance class (when added) |

Use `terraform destroy` to remove the VPC stack when not in use. Set an [AWS Budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-create.html) alert on your account.

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
