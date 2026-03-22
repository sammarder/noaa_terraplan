resource "aws_sfn_state_machine" "noaa_pipeline" {
  name     = "noaa-data-pipeline"
  role_arn = aws_iam_role.noaa_sf_role.arn
  
  # Crucial for your new setup
  type = "STANDARD" 

  # This pulls in your JSON definition and allows you to pass 
  # Terraform variables (like ARNs) directly into the JSON
  definition = templatefile("${path.module}/noaa_states.jsonata.tftpl", {
    glue_job   = aws_glue_job.jsonl_to_parquet.name,
    s3_bucket = module.storage.bucket_id,
    lambda_archiver = module.lambda.archiver_arn,
	crawler = aws_glue_crawler.noaa_parquet_crawler.name
  })
}
