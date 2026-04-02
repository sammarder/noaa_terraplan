resource "aws_s3_bucket" "noaa_bucket" {
  bucket        = var.bucket_name
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
