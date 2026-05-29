# ---------------------
# Lambda function configuration
# ---------------------

# We'll need the database password later.
data "aws_secretsmanager_secret_version" "jf_com_db_password" {
  secret_id = aws_rds_cluster.jf_com_main_site_db.master_user_secret[0].secret_arn
}

resource "aws_lambda_function" "jf_com_main_site" {
  # Safeguard to prevent debug mode from being enabled in Production
  lifecycle {
    precondition {
      condition = !(var.jf_com_debug && var.jf_com_environment == "Production")
      error_message = "Debug cannot be enabled in the Production Environment."
    }
  }

  function_name = "jf_com_main_site"
  role          = aws_iam_role.jf_com_admin.arn
  package_type  = "Image" # We use Docker images
  image_uri     = "${aws_ecr_repository.jf_com_main_site.repository_url}:${var.jf_com_tag_random}"
  timeout       = 30 # Because we let Aurora spin down to nothing, we need to give it time to warm up
  memory_size   = 512
  # ARM is cheaper but don't forget to build with it specifically
  architectures = ["arm64"]

  vpc_config {
    subnet_ids         = [aws_subnet.jf_com_private_1.id, aws_subnet.jf_com_private_2.id]
    security_group_ids = [aws_security_group.jf_com_lambda_sg.id]
  }

  environment {
    variables = {
      JF_COM_DJANGO_SECRET_KEY = aws_secretsmanager_secret_version.jf_com_django_secret_key_version.secret_string
      JF_COM_DB_USER           = aws_rds_cluster.jf_com_main_site_db.master_username
      JF_COM_DB_PASS           = jsondecode(data.aws_secretsmanager_secret_version.jf_com_db_password.secret_string)["password"]
      JF_COM_DB_HOST           = aws_rds_cluster.jf_com_main_site_db.endpoint
      JF_COM_DB_NAME           = aws_rds_cluster.jf_com_main_site_db.database_name
      JF_COM_ENVIRONMENT       = low(var.jf_com_environment) == "production" ? "Production" : "Development"
      JF_COM_DEBUG             = var.jf_com_debug
      JF_COM_REGION            = var.jf_com_region
      JF_COM_ASSETS_BUCKET     = aws_s3_bucket.jf_com_assets.bucket
    }
  }
}

# Set up the actual function URL
resource "aws_lambda_function_url" "jf_com_main_site_url" {
  authorization_type = "NONE"
  function_name      = aws_lambda_function.jf_com_main_site.function_name

  # CORS settings for future-proofing
  cors {
    allow_credentials = lower(var.jf_com_environment) == "production" ? true : false
    allow_origins     = lower(var.jf_com_environment) == "production" ? ["https://justinfolvarcik.com"] : ["*"]
    allow_methods     = ["GET", "POST", "HEAD"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
  }
}

# Establish permissions
resource "aws_lambda_permission" "jf_com_lambda_permissions_url" {
  action        = "lambda:InvokeFunctionUrl"
  function_name = aws_lambda_function.jf_com_main_site.function_name
  principal     = "*" # Everyone
  # Auth type has to match the function URL auth type
  function_url_auth_type = "NONE"
  # A unique name so that it doesn't just get a generic AWS identifier
  statement_id = "AllowPublicUrlAccess"
}

# Allowing URL access and function invocation access are two separate things
# Both required for this application
resource "aws_lambda_permission" "jf_com_lambda_permissions_function" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jf_com_main_site.function_name
  principal     = "*"
  statement_id  = "AllowPublicInvoke"
}
