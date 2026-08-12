#!/usr/bin/env bash
#
# Tears down everything created by scripts/init-cluster.sh: Helm releases
# (ArgoCD, ingress-nginx) and the full Terraform stack (VPC + EKS + RDS + ECR
# repos + app namespace/Secret).
#
# Run this when you're done for the day to avoid paying for the EKS control
# plane, worker nodes, NAT gateway, and RDS instance overnight.
#
# Usage:
#   ./scripts/destroy-cluster.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$REPO_ROOT/terraform"

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found in PATH" >&2
  exit 1
fi

log "Uninstalling Helm releases (best-effort, ignored if already gone)"
helm uninstall argocd -n argocd 2>/dev/null || true
helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || true

log "Terraform destroy (VPC + EKS + RDS + ECR + app namespace/Secret)"
terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve

log "Done. Verify nothing billable is left running:"
cat <<'EOF'
  aws eks list-clusters --region us-east-1
  aws ec2 describe-nat-gateways --filter "Name=state,Values=available" --region us-east-1
  aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --region us-east-1
EOF
