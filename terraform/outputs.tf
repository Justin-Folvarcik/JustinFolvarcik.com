# ---------------------
# Post-run outputs
# Tells terraform to print relevant information after a run
# ---------------------

output "jf_com_lambda_function_url" {
  description = "The actual website invocation URL"
  value = aws_lambda_function_url.jf_com_main_site_url.function_url
}

output "jf_com_ecr_url" {
  description = "The URL of the ECR store where the docker images live"
  value = aws_ecr_repository.jf_com_main_site.repository_url
  sensitive = true
}

output "jf_com_rds_endpoint" {
  description = "The Aurora database endpoint"
  value = aws_rds_cluster.jf_com_main_site_db.endpoint
  sensitive = true
}

output "jf_com_assets_bucket" {
  description = "The assets bucket"
  value = aws_s3_bucket.jf_com_assets.bucket
}