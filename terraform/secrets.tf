# ---------------------
# Secrets Manager configuration
# ---------------------

# Generate the site's secret key
# This acts as a salt and a source of randomness for the app
resource "random_password" "jf_com_django_key" {
  length = 50 # A nice, long password
  special = true # Allow special chars
}

# Create a container for the key we just generated
resource "aws_secretsmanager_secret" "jf_com_django_secret_key" {
  # SM secret names must use hyphens instead of underscores
  name = "jf-com-django-secret-key"
  description = "Django's secret key, used for cryptographic signing"

  tags = {
    Name = "jf_com_django_secret_key"
    Environment = var.jf_com_environment
  }
}

# Attach the actual key to the container so it can be referenced at deployment
resource "aws_secretsmanager_secret_version" "jf_com_django_secret_key_version" {
  secret_id = aws_secretsmanager_secret.jf_com_django_secret_key.id
  secret_string = random_password.jf_com_django_key.result
}

# Rotate the database password every month
# We do not rotate the Django key because it would invalidate user sessions
# This can cause problems if we add any kind of login functionality later. (Also it would annoy me)
resource "aws_secretsmanager_secret_rotation" "jf_com_db_pass_rotate" {
  secret_id = aws_rds_cluster.jf_com_main_site_db.master_user_secret[0].secret_arn
  rotation_rules {
    automatically_after_days = 30
  }
}
