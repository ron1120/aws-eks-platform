# ECR repositories for the app images (built locally / by CI, pulled by the
# EKS nodes at deploy time). One repo per image, named in var.ecr_repositories.
resource "aws_ecr_repository" "app" {
  for_each = toset(var.ecr_repositories)

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  # Lets `terraform destroy` remove the repo even if it still has images —
  # important since we tear this stack down/up regularly while learning.
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Keep only the most recent images so old ones don't accumulate storage cost.
resource "aws_ecr_lifecycle_policy" "app" {
  for_each   = aws_ecr_repository.app
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
