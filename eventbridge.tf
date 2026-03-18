resource "aws_cloudwatch_event_rule" "glue_success_rule" {
  name        = "glue-job-success-trigger"
  description = "Triggers when a specific Glue job finishes successfully"

  # The event pattern filters for Glue Job state changes
  event_pattern = jsonencode({
    "source": ["aws.glue"],
    "detail-type": ["Glue Job State Change"],
    "detail": {
      "state": ["SUCCEEDED"],
      "jobName": ["${aws_glue_job.jsonl_to_parquet.name}"] # Replace with your job name
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.glue_success_rule.name
  target_id = "MoveFilesToArchive"
  arn       = aws_lambda_function.archive_lambda.arn
}