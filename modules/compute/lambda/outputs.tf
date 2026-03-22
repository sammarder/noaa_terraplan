output "preproc_arn" {
  description = "The ARN of the Lambda function for S3 triggers"
  value       = aws_lambda_function.s3_lambda.arn
}

output "archiver_arn" {
  description = "The ARN of the Lambda function for S3 triggers"
  value       = aws_lambda_function.archive_lambda.arn
}

output "permission_id" {
  description = "The ID of the Lambda permission to ensure S3 can call it"
  value       = aws_lambda_permission.allow_s3.id
}