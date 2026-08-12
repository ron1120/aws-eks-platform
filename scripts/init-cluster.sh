#!/usr/bin/env bash
#
# Brings the whole platform up from scratch (or resumes if already partially
# up): VPC + EKS + RDS + ECR repos + app namespace/Secret via Terraform,
# kubeconfig, ingress-nginx, ArgoCD, and any ArgoCD Application manifests in
# argocd/apps/.
#
# Safe to re-run — every step is idempotent (terraform apply, helm upgrade
# --install, kubectl apply).
#
# Usage:
#   ./scripts/init-cluster.sh
#
# Companion script: scripts/destroy-cluster.sh tears everything back down.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$REPO_ROOT/terraform"
ARGOCD_APPS_DIR="$REPO_ROOT/argocd/apps"

AWS_REGION="${AWS_REGION:-us-east-1}"

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

for cmd in terraform aws kubectl helm; do
  require_cmd "$cmd"
done

log "Checking AWS credentials"
aws sts get-caller-identity >/dev/null

log "Terraform init"
terraform -chdir="$TERRAFORM_DIR" init -input=false

log "Terraform apply (VPC + EKS + RDS + ECR + app namespace/Secret)"
terraform -chdir="$TERRAFORM_DIR" apply -auto-approve

CLUSTER_NAME="$(terraform -chdir="$TERRAFORM_DIR" output -raw cluster_name)"
log "Cluster name: $CLUSTER_NAME"

log "Updating kubeconfig"
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"

log "Waiting for nodes to be Ready"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

log "Adding Helm repos"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update >/dev/null

log "Installing/upgrading ingress-nginx"
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --wait

log "Installing/upgrading ArgoCD"
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --wait

if [ -d "$ARGOCD_APPS_DIR" ] && [ -n "$(ls -A "$ARGOCD_APPS_DIR" 2>/dev/null)" ]; then
  log "Applying ArgoCD Application manifests from argocd/apps/"
  kubectl apply -f "$ARGOCD_APPS_DIR"
else
  log "No ArgoCD Application manifests found in argocd/apps/, skipping"
fi

log "ArgoCD admin password"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" 2>/dev/null | base64 -d && echo || \
  echo "(secret not found — admin password may already have been changed)"

log "Done. Cluster nodes:"
kubectl get nodes

log "ECR repository URLs"
terraform -chdir="$TERRAFORM_DIR" output -json ecr_repository_urls

cat <<'EOF'

Next steps:
  - Access ArgoCD UI:
      kubectl port-forward svc/argocd-server -n argocd 8080:443
      open https://localhost:8080

  - Check ingress-nginx external address:
      kubectl get svc -n ingress-nginx

  - Build + push app images (first time / after code changes), then apply
    argocd/apps/backend.yaml and argocd/apps/frontend.yaml — see the repo
    README for exact docker build/push and Helm values.yaml steps.

  - Remember to run ./scripts/destroy-cluster.sh when done for the day
    to avoid paying for the cluster + NAT gateway + RDS instance overnight.
EOF
