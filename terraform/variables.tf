# ---------------------
# Project variables for terraform
# ---------------------

variable "jf_com_bucket_suffix" {
  type = string
  description = "The suffix for the S3 buckets to prevent name collision"
  default = "1934"
}

# Default is development. Override manually via .tfvars when deploying to prod.
variable "jf_com_environment" {
  type = string
  description = "The current environment being deployed"
  default = "Development"
}

variable "jf_com_region" {
  type = string
  description = "The AWS region to use"
  default = "us-east-1"
}

# Our actual sign-in profile
variable "jf_com_aws_profile" {
  type = string
  description = "The AWS profile to use to sign in."
}

# This will be for generating a random tag for the image based on git SHA
variable "jf_com_tag_random" {
  type = string
  description = "The git SHA to append to the image tag."
}