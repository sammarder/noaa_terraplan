resource "aws_lambda_function" "s3_lambda" {
  filename      = "s3_lambda_function_payload.zip"
  function_name = "preprocessor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "s3_lambda_trigger.lambda_handler" # filename.function_name
  timeout       = 120
  source_code_hash = data.archive_file.s3_lambda_zip.output_base64sha256

  
  runtime = "python3.12"

}

#new lambda function being built
resource "aws_lambda_function" "archive_lambda" {
  filename      = "archive_lambda_function_payload.zip"
  function_name = "archiver"
  role          = aws_iam_role.lambda_role.arn
  handler       = "archive_lambda.lambda_handler" # filename.function_name
  timeout       = 120
  source_code_hash = data.archive_file.archive_lambda_zip.output_base64sha256

  
  runtime = "python3.12"

}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.noaa_bucket.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.archive_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.glue_success_rule.arn
}

data "archive_file" "s3_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/scripts/s3_lambda_trigger.py" # Path to your script
  output_path = "${path.module}/s3_lambda_function_payload.zip"
}

data "archive_file" "archive_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/scripts/archive_lambda.py" # Path to your script
  output_path = "${path.module}/archive_lambda_function_payload.zip"
}