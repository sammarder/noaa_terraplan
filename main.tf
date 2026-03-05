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



resource "aws_s3_bucket" "noaa_bucket" {
  bucket = "sams-noaa-test-east-2"
}

resource "aws_s3_object" "base_folders" {
  for_each = toset([
    "extracted_data/",
    "parquet/",
    "finished_archive/",
    "athena-results/",
	"new_archive/"
  ])

  bucket       = aws_s3_bucket.noaa_bucket.id
  key          = each.value
  content_type = "application/x-directory"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "scripts/s3_lambda_trigger.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "my_awesome_script"
  role          = "arn:aws:iam::489719310300:role/service-role/preprocnoaa-role-5nn0xete"
  handler       = "s3_lambda_trigger.handler" # filename.function_name

  # This helps Terraform detect code changes
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.12"
}