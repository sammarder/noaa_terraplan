resource "aws_s3_bucket" "noaa_bucket" {
  bucket        = "sams-noaa-test-east-2"
  force_destroy = true
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


resource "aws_s3_bucket_server_side_encryption_configuration" "noaa_bucket_encrypt" {
  bucket = aws_s3_bucket.noaa_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key
    }
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.noaa_bucket.id

  lambda_function {
    lambda_function_arn = var.s3_lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "new_archive/"
    filter_suffix       = ".zip"
  }

  # This ensures the permission is created BEFORE S3 tries to link to it
  depends_on = [var.lambda_allow]
}

resource "aws_s3tables_table_bucket" "noaa_bucket" {
  name = "noaa-table-bucket"
  
  # Maintenance settings are internal to S3 Tables
  maintenance_configuration {
    iceberg_compaction {
      status = "Enabled"
    }
    iceberg_snapshot_management {
      status = "Enabled"
    }
  }
}

resource "aws_s3tables_namespace" "weather_data" {
  table_bucket_arn = aws_s3tables_table_bucket.noaa_bucket.arn
  namespace        = "weather_data"
}

resource "aws_s3tables_table" "my_table" {
  table_bucket_arn = aws_s3tables_table_bucket.noaa_bucket.arn
  namespace        = aws_s3tables_namespace.weather_data.namespace
  name             = "monthly_reports"
  format           = "ICEBERG"
}

resource "aws_s3tables_table_bucket_policy" "allow_glue" {
  resource_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGlueAccess"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = [
          "s3tables:GetTable",
          "s3tables:ListTables",
          "s3tables:ReadObject"
        ]
        Resource = [
          "${aws_s3tables_table_bucket.noaa_bucket.arn}",
          "${aws_s3tables_table_bucket.noaa_bucket.arn}/table/*"
        ]
      }
    ]
  })
  table_bucket_arn = aws_s3tables_table_bucket.noaa_bucket.arn
}
