# Namespace + Secret for the TM-Project app. Created here (not by ArgoCD)
# so the DB credentials never have to be written to values.yaml / git — the
# Helm charts just reference this Secret by name via `envFrom`.
#
# Because Terraform owns this namespace, the ArgoCD Applications for
# backend/frontend must NOT use `CreateNamespace=true` (that would race with
# this resource, the same class of conflict we hit earlier with the vpc-cni
# add-on).
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace
  }

  # Wait for the cluster (and the admin access entry) to be ready.
  depends_on = [module.eks]
}

# Signs the backend's JWTs. Generated once and stored only in the cluster.
resource "random_password" "backend_secret_key" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "backend" {
  metadata {
    name      = "tm-project-backend-secrets"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    # Matches backend/app/core/config.py: Settings.DATABASE_URL
    DATABASE_URL = "postgresql://${module.rds.db_username}:${module.rds.db_password}@${module.rds.db_address}:${module.rds.db_port}/${module.rds.db_name}"
    SECRET_KEY   = random_password.backend_secret_key.result
    # The frontend is reached through the same Ingress/host as the backend
    # (path-based routing: "/" -> frontend, "/api" -> backend), so browser
    # requests are same-origin and CORS doesn't really come into play. Left
    # permissive here; tighten if you ever expose the API on its own domain.
    CORS_ORIGINS = "*"
  }

  type = "Opaque"
}
