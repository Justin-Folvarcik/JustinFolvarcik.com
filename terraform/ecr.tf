# ---------------------
# Elastic Container Registry configuration
# ---------------------

# Define our repository
resource "aws_ecr_repository" "jf_com_main_site" {
  name = "jf_com_main_site"
  # Tags cannot be overwritten
  image_tag_mutability = "IMMUTABLE"
  # Enable image scanning
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name        = "jf_com_main_site"
    Environment = var.jf_com_environment
  }
}

# Lifecycle policy to only keep 3 images
resource "aws_ecr_lifecycle_policy" "jf_com_main_site_policy" {
  repository = aws_ecr_repository.jf_com_main_site.name

  policy = jsonencode({

    rules = [
      {
        # If a push fails, an image could end up untagged. Kill these.
        rulePriority = 1,
        description  = "Remove untagged images",
        selection = {
          tagStatus   = "untagged",
          countType   = "imageCountMoreThan",
          countNumber = 1
        },
        action = {
          type = "expire"
        }
      },

      {
        rulePriority = 2,
        description  = "Only keep 3 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 3
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}
