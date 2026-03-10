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