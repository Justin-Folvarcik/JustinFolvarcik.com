# ---------------------
# Database configuration
# ---------------------

# First we have to define the subnets the DB cluster can use
resource "aws_db_subnet_group" "jf_com_db" {
  name       = "jf_com_main_site_db_subnets"
  subnet_ids = [aws_subnet.jf_com_private_1.id, aws_subnet.jf_com_private_2.id]

  tags = {
    Name = "Database subnets"
    Environment = var.jf_com_environment
  }
}

# Then we define the actual DB cluster
resource "aws_rds_cluster" "jf_com_main_site_db" {
  cluster_identifier = "jf_com_main_site_cluster"
  engine = "aurora-postgresql"
  engine_mode = "provisioned"
  engine_version = "16.13"
  availability_zones = ["${var.jf_com_region}a", "${var.jf_com_region}b"]
  database_name = "jf_com_main_site"
  master_username = "dbadmin"
  manage_master_user_password = true
  skip_final_snapshot = var.jf_com_environment == "production" ? false : true
  db_subnet_group_name = aws_db_subnet_group.jf_com_db.name
  vpc_security_group_ids = [] # @TODO: Fill these in during wiring

  serverlessv2_scaling_configuration {
    # This is what actually shuts off the database when there's no traffic, so we don't end up with aurora costs
    max_capacity = 1
    min_capacity = 0
  }
}

# Now instances within said cluster
resource "aws_rds_cluster_instance" "jf_com_main_site_production" {
  identifier = "jf_com_main_site_production_1"
  cluster_identifier = aws_rds_cluster.jf_com_main_site_db.id
  engine             = aws_rds_cluster.jf_com_main_site_db.engine
  engine_version     = aws_rds_cluster.jf_com_main_site_db.engine_version
  instance_class     = "db.serverless"
  db_subnet_group_name = aws_db_subnet_group.jf_com_db.name
}