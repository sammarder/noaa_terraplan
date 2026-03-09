terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Or the latest stable version
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


# The S3 Gateway Endpoint (The "Magic Link")
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.data_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  # This automatically updates your route table to point S3 traffic here
  route_table_ids = [aws_vpc.data_vpc.main_route_table_id]
}





resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.noaa_bucket.arn
}