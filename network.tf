resource "aws_vpc" "data_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "noaa-data-vpc" }
}

resource "aws_security_group" "glue_sg" {
  name        = "noaa-glue-vpc-sg"
  description = "Allow Glue to talk to itself and S3"
  vpc_id      = aws_vpc.data_vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "glue-security-group" }
}

resource "aws_vpc_security_group_ingress_rule" "self_reference" {
  security_group_id = aws_security_group.glue_sg.id

  # This is the "magic" part: referencing the ID of the group it belongs to
  referenced_security_group_id = aws_security_group.glue_sg.id

  from_port   = 0
  to_port     = 0
  ip_protocol = "-1" # Allow all internal traffic between members
  description = "Allow all traffic from nodes in the same SG"
}

resource "aws_security_group" "lambda_sg" {
  name        = "noaa-lambda-vpc-sg"
  description = "Allow Lambda to trigger Glue and talk to S3"
  vpc_id      = aws_vpc.data_vpc.id

  # INBOUND: None needed! 
  # S3 triggers Lambda through the AWS control plane, not the VPC.

  # EGRESS: To S3 and Glue
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Or use Prefix Lists for stricter S3 control
  }

  tags = { Name = "lambda-security-group" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.data_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
}

resource "aws_glue_connection" "vpc_connector" {
  name            = "noaa-vpc-connection"
  connection_type = "NETWORK"

  physical_connection_requirements {
    availability_zone      = aws_subnet.private.availability_zone
    security_group_id_list = [aws_security_group.glue_sg.id]
    subnet_id              = aws_subnet.private.id
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.data_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  # This automatically updates your private subnet's routing
  route_table_ids = [aws_vpc.data_vpc.default_route_table_id]
}