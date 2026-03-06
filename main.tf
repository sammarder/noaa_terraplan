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
	"new_archive/",
	"scripts/"
  ])

  bucket       = aws_s3_bucket.noaa_bucket.id
  key          = each.value
  content_type = "application/x-directory"
}

resource "aws_s3_object" "templated_script" {
  bucket = aws_s3_bucket.noaa_bucket.id
  key    = "scripts/process_jsonl.py"

  # Render the file with variables before uploading
  content = templatefile("${path.module}/scripts/processor.tftpl", {
    bucket_id     = aws_s3_bucket.noaa_bucket.id
  })

  content_type = "text/x-python"
  
  # Crucial: This ensures S3 updates if the template or variables change
  etag = md5(templatefile("${path.module}/scripts/processor.tftpl", {
    bucket_id     = aws_s3_bucket.noaa_bucket.id
  }))
}

resource "aws_iam_role" "iam_for_lambda_noaa_east_2" {
  name = "preproc_role"

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

resource "aws_iam_role" "glue_crawler_role" {
  name = "noaa_crawler_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service_attach" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "local_file" "lambda_rendered" {
  content  = templatefile("${path.module}/scripts/s3_lambda_trigger.tftpl", {
    glue_job = aws_glue_job.jsonl_to_parquet.id
  })
  filename = "${path.module}/scripts/s3_lambda_trigger.py"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_rendered.filename
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "preprocessor"
  role          = aws_iam_role.iam_for_lambda_noaa_east_2.arn
  handler       = "s3_lambda_trigger.lambda_handler" # filename.function_name
  timeout = 120

  # This helps Terraform detect code changes
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.12"
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.noaa_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.noaa_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.test_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "new_archive/"
    filter_suffix       = ".zip"
  }

  # This ensures the permission is created BEFORE S3 tries to link to it
  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_glue_job" "jsonl_to_parquet" {
  name     = "noaa_preprocessor_job"
  role_arn = "arn:aws:iam::489719310300:role/Glue_role"
  command {
    name            = "glueetl"
    # Point to the S3 path of the uploaded object
    script_location = "s3://${aws_s3_bucket.noaa_bucket.id}/${aws_s3_object.templated_script.key}"
	python_version = "3"
  }
  glue_version = "5.0"
}

resource "aws_glue_catalog_database" "noaa_db" {
  name = "noaa_processed_data"
}


resource "aws_glue_crawler" "noaa_parquet_crawler" {
  database_name = aws_glue_catalog_database.noaa_db.name
  name          = "noaa_parquet_crawler"
  role          = aws_iam_role.glue_crawler_role.arn

  s3_target {
    # Point this to your Parquet output folder
    path = "s3://${aws_s3_bucket.noaa_bucket.id}/parquet/"
  }

  # This tells the crawler to only update the schema if it changes
  configuration = jsonencode({
    "Version" = 1.0
    "CreatePartitionIndex": true
  })
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
      },
        {
            "Effect": "Allow",
            "Action": "glue:StartJobRun",
            "Resource": [
                "${aws_glue_job.jsonl_to_parquet.arn}"
            ]
        }
    ]
  })
}

resource "aws_iam_role_policy" "glue_crawler_policy" {
  name = "preprocessor_permissions"
  role = aws_iam_role.glue_crawler_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.noaa_bucket.arn}/parquet/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:ResourceAccount": "489719310300"
                }
            }
        }
    ]
})
}

resource "aws_iam_policy" "crawler_s3_policy" {
  name = "noaa_crawler_s3_access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.noaa_bucket.arn,            # Bucket level
          "${aws_s3_bucket.noaa_bucket.arn}/*"      # Object level
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attach" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.crawler_s3_policy.arn
}