module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project_name}-cluster"
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Keep the API endpoint public for learning/dev so kubectl works from your
  # laptop without a VPN or bastion. Lock this down in production.
  endpoint_public_access = true

  # Adds the identity running `terraform apply` as a cluster admin via an
  # EKS access entry, so `kubectl` works immediately after apply.
  enable_cluster_creator_admin_permissions = true

  # Required: the EKS module sets bootstrap_self_managed_addons = false, so
  # these must be installed explicitly or nodes stay NotReady forever.
  addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
    }
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      subnet_ids = var.private_subnet_ids
    }
  }
}
