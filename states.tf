resource "aws_sfn_state_machine" "noaa_pipeline" {
  name     = "noaa-data-pipeline"
  role_arn = aws_iam_role.noaa_sf_role.arn
  
  # Crucial for your new setup
  type = "STANDARD" 

  # This pulls in your JSON definition and allows you to pass 
  # Terraform variables (like ARNs) directly into the JSON
  definition = templatefile("${path.module}/states.jsonata.tftpl", {
    glue_job   = aws_glue_job.jsonl_to_parquet.name,
    s3_bucket = aws_s3_bucket.noaa_bucket.id,
    lambda_archiver = aws_lambda_function.archive_lambda.arn,
	crawler = aws_glue_crawler.noaa_parquet_crawler.name
  })
}