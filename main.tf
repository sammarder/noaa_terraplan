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

resource "aws_iam_role" "iam_for_lambda_noaa_east_2" {
  name = "preproc_role"

  # THIS is the Trust Policy. It only says "Lambda can use me."
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}



data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "scripts/s3_lambda_trigger.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "preprocessor"
  role          = aws_iam_role.iam_for_lambda_noaa_east_2.arn
  handler       = "s3_lambda_trigger.handler" # filename.function_name

  # This helps Terraform detect code changes
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.12"
}

resource "aws_iam_role_policy" "lambda_s3_logs_policy" {
  name = "preprocessor_permissions"
  role = aws_iam_role.iam_for_lambda_noaa_east_2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:us-east-2:489719310300:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:us-east-2:489719310300:log-group:/aws/lambda/preprocessor:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.noaa_bucket.arn}/*"      # Needed for file operations
        ]
      }
    ]
  })
}