# ---------------------
# S3 buckets configuration
# ---------------------

# Set up our S3 bucket for static assets
resource "aws_s3_bucket" "jf_com_assets" {
  # S3 buckets do not accept underscores in bucket names.
  bucket = "jf-com-assets-${var.jf_com_bucket_suffix}"
  tags = {
    Name = "jf_com_assets"
    Environment = var.jf_com_environment
  }
}

# Set up our DB backups bucket
resource "aws_s3_bucket" "jf_com_db_backups" {
  bucket = "jf-com-db-backups-${var.jf_com_bucket_suffix}"
  tags = {
    Name = "jf_com_db_backups"
    Environment = var.jf_com_environment
  }
}

# Remove the default blocking so the assets bucket can be accessed
resource "aws_s3_bucket_public_access_block" "jf_com_assets_access" {
  bucket = aws_s3_bucket.jf_com_assets.id

  # We don't use ACLs, so those can stay true
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# The backups bucket does not need public access
# These are actually set by default; we explicitly declare them here for the sake of documentation
resource "aws_s3_bucket_public_access_block" "jf_com_db_backups_access" {
  bucket = aws_s3_bucket.jf_com_db_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Ensure all assets are owned by the bucket owner
resource "aws_s3_bucket_ownership_controls" "jf_com_assets_ownership" {
  bucket = aws_s3_bucket.jf_com_assets.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Allow public access to the assets bucket
resource "aws_s3_bucket_policy" "jf_com_assets_policy" {
  bucket = aws_s3_bucket.jf_com_assets.id
  # The access blocks must be lifted first
  depends_on = [aws_s3_bucket_public_access_block.jf_com_assets_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPublicReadAccess" # Statement name
        Effect    = "Allow"
        Principal = "*" # Everyone
        Action    = "s3:GetObject" # GET
        Resource  = "${aws_s3_bucket.jf_com_assets.arn}/*" # The actual resources in the assets bucket
      }
    ]
  })
}

# CORS policy
resource "aws_s3_bucket_cors_configuration" "jf_com_assets_cors" {
  bucket = aws_s3_bucket.jf_com_assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"] # Only allow pulling data
    allowed_origins = ["*"] # Might tighten this up later; not a problem for now
    max_age_seconds = 3000
  }

}