# ---------------------
# Terraform versioning and base configuration
# ---------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.46.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
  }
  required_version = ">= 1.15"
}