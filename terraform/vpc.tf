# ---------------------
# VPC configuration
# ---------------------

# Set up our VPC for the internal services
resource "aws_vpc" "jf_com_vpc" {
  # 10.0.0.0/16 is an internal block, so we can use this for internal communication.
  # It does not face the internet.
  cidr_block = "10.0.0.0/16"
  # Aurora and Lambda both need DNS support
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "jf_com_vpc"
    Environment = var.jf_com_environment
  }
}

# Create our subnets
resource "aws_subnet" "jf_com_private_1" {
  vpc_id = aws_vpc.jf_com_vpc.id
  # The address block this subnet is allowed to use in the VPC
  # We don't start with 10.0.0.0 in order to avoid confusion with the VPC itself
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.jf_com_region}a"
  tags = {
    Name = "jf_com_private_1"
    Environment = var.jf_com_environment
  }
}

resource "aws_subnet" "jf_com_private_2" {
  vpc_id = aws_vpc.jf_com_vpc.id
  # Use the next available address block
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.jf_com_region}b"
  tags = {
    Name = "jf_com_private_2"
    Environment = var.jf_com_environment
  }
}
/* Currently disabled; may be unnecessary
resource "aws_subnet" "jf_com_public_1" {
  vpc_id = aws_vpc.jf_com_vpc.id
  # Use an address block that is immediately visually distinct from the private subnets
  cidr_block = "10.0.101.0/24"
  availability_zone = "${var.region}a"
  # If we don't set this, a public IP won't be applied
  map_public_ip_on_launch = true
  tags = {
    Name = "jf_com_public_1"
    Environment = var.environment
  }
}

resource "aws_subnet" "jf_com_public_2" {
  vpc_id = aws_vpc.jf_com_vpc.id
  cidr_block = "10.0.102.0/24"
  availability_zone = "${var.region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "jf_com_public_2"
    Environment = var.environment
  }
}
*/

# We just need to define the route table here
# We need this for our S3 endpoint (for our assets)
resource "aws_route_table" "jf_com_route_table" {
  vpc_id = aws_vpc.jf_com_vpc.id
}

# And now we can associate the table with our subnets
resource "aws_route_table_association" "jf_com_private_1" {
  route_table_id = aws_route_table.jf_com_route_table.id
  subnet_id = aws_subnet.jf_com_private_1.id
}

resource "aws_route_table_association" "jf_com_private_2" {
  route_table_id = aws_route_table.jf_com_route_table.id
  subnet_id = aws_subnet.jf_com_private_2.id
}

# Open up an endpoint for S3
resource "aws_vpc_endpoint" "jf_com_assets_endpoint" {
  vpc_id = aws_vpc.jf_com_vpc.id
  # Gateway is actually the default, but for the sake of documentation, we define it anyway
  vpc_endpoint_type = "Gateway"
  service_name = "com.amazonaws.${var.jf_com_region}.s3" # AWS services follow this naming convention
  route_table_ids = [aws_route_table.jf_com_route_table.id]
}

# Define our security groups and access rules
resource "aws_security_group" "jf_com_db_sg" {
  vpc_id = aws_vpc.jf_com_vpc.id

  tags = {
    Name = "jf_com_db_sg"
    Environment = var.jf_com_environment
  }
}

resource "aws_security_group" "jf_com_lambda_sg" {
  vpc_id = aws_vpc.jf_com_vpc.id

  tags = {
    Name = "jf_com_lambda_sg"
    Environment = var.jf_com_environment
  }
}

# We don't need to set egress rules for the database; terraform removes the defaults so there are none
resource "aws_security_group_rule" "jf_com_db_sg_ingress" {
  description = "Allow connection to Aurora"
  from_port         = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.jf_com_db_sg.id
  to_port           = 5432
  type              = "ingress"
  source_security_group_id = aws_security_group.jf_com_lambda_sg.id
}

resource "aws_security_group_rule" "jf_com_lambda_sg_egress_db" {
  description = "Allow lambda to talk to Aurora"
  from_port         = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.jf_com_lambda_sg.id
  to_port           = 5432
  type              = "egress"
  source_security_group_id = aws_security_group.jf_com_db_sg.id
}

resource "aws_security_group_rule" "jf_com_lambda_sg_egress_assets" {
  description = "Allow lambda to talk to S3"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.jf_com_lambda_sg.id
  prefix_list_ids = [aws_vpc_endpoint.jf_com_assets_endpoint.prefix_list_id]
  to_port           = 443
  type              = "egress"
}