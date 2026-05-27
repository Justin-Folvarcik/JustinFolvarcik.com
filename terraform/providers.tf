# ---------------------
# Base provider configuration
# ---------------------

# Set our region and management profile
provider "aws" {
  region = var.jf_com_region
  profile = var.jf_com_aws_profile
}
