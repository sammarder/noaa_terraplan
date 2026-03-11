resource "aws_ssm_parameter" "bucket_arn" {
  name        = "/noaa/s3/bucket_arn"
  description = "The ARN for the NOAA test bucket"
  type        = "String"
  value       = aws_s3_bucket.noaa_bucket.arn
}

resource "aws_ssm_parameter" "key_arn" {
  name        = "/noaa/kms/key_arn"
  description = "The ARN for the NOAA kms key"
  type        = "String"
  value       = aws_kms_key.noaa_key.arn
}

resource "aws_ssm_parameter" "iam_lambda_arn" {
  name        = "/noaa/iam_role/lambda_arn"
  description = "The ARN for the NOAA Lambda IAM role"
  type        = "String"
  value       = aws_iam_role.lambda_role.arn
}

resource "aws_ssm_parameter" "iam_glue_arn" {
  name        = "/noaa/iam_role/glue_arn"
  description = "The ARN for the NOAA Glue Job IAM role"
  type        = "String"
  value       = aws_iam_role.glue_proc_role.arn
}

resource "aws_ssm_parameter" "iam_glue_crawler_arn" {
  name        = "/noaa/iam_role/glue_crawler_arn"
  description = "The ARN for the NOAA Glue Crawler IAM role"
  type        = "String"
  value       = aws_iam_role.glue_crawler_role.arn
}

resource "aws_ssm_parameter" "lambda_arn" {
  name        = "/noaa/lambda/function_arn"
  description = "The ARN for the NOAA Lambda Function"
  type        = "String"
  value       = aws_lambda_function.test_lambda.arn
}

resource "aws_ssm_parameter" "glue_catalog_arn" {
  name        = "/noaa/glue/catalog_arn"
  description = "The ARN for the NOAA Glue Catalog DB"
  type        = "String"
  value       = aws_glue_catalog_database.noaa_db.arn
}

resource "aws_ssm_parameter" "glue_job_arn" {
  name        = "/noaa/glue/job_arn"
  description = "The ARN for the NOAA Glue Job"
  type        = "String"
  value       = aws_glue_job.jsonl_to_parquet.arn
}

resource "aws_ssm_parameter" "glue_crawler_arn" {
  name        = "/noaa/glue/crawler_arn"
  description = "The ARN for the NOAA Glue Crawler"
  type        = "String"
  value       = aws_glue_crawler.noaa_parquet_crawler.arn
}