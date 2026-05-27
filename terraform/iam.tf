# ---------------------
# IAM configuration
# ---------------------

resource "aws_iam_role" "jf_com_admin" {
  name = "jf_com_admin"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Allow lambda to write logs to CloudWatch
# These roles are pre-defined by Amazon so you don't need boilerplate
resource "aws_iam_role_policy_attachment" "jf_com_execute" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.jf_com_admin.name
}

# Allow lambda to manage network interfaces
resource "aws_iam_role_policy_attachment" "jf_com_vpc" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.jf_com_admin.name
}

resource "aws_iam_policy" "jf_com_s3_admin" {
  name = "jf_com_s3_admin"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
      Resource = [
        # We need both the bucket and its assets
        aws_s3_bucket.jf_com_assets.arn,
        "${aws_s3_bucket.jf_com_assets.arn}/*"
      ]
    }]
  })
}

# Need to actually attach the policy
resource "aws_iam_role_policy_attachment" "jf_com_s3_admin" {
  policy_arn = aws_iam_policy.jf_com_s3_admin.arn
  role       = aws_iam_role.jf_com_admin.name
}

resource "aws_iam_policy" "jf_com_db_secrets" {
  name = "jf_com_db_secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "secretsmanager:GetSecretValue"
        Effect = "Allow"
        Resource = [
          # Allow reading of secrets
          aws_rds_cluster.jf_com_main_site_db.master_user_secret[0].secret_arn,
          aws_secretsmanager_secret.jf_com_django_secret_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jf_com_db_secrets" {
  policy_arn = aws_iam_policy.jf_com_db_secrets.arn
  role       = aws_iam_role.jf_com_admin.name
}