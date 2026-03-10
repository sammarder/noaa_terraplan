data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_rendered.filename
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "preprocessor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "s3_lambda_trigger.lambda_handler" # filename.function_name
  timeout       = 120

  # This helps Terraform detect code changes
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.12"

}