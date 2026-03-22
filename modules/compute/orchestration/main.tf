resource "aws_sfn_state_machine" "noaa_pipeline" {
  name     = "noaa-data-pipeline"
  role_arn = var.sf_permission
  
  # Crucial for your new setup
  type = "STANDARD" 

  # This pulls in your JSON definition and allows you to pass 
  # Terraform variables (like ARNs) directly into the JSON
  definition = templatefile("${path.module}/noaa_states.jsonata.tftpl", {
    glue_job   = var.glue_job,
    s3_bucket = var.bucket,
    lambda_archiver = var.archiver_arn,
	crawler = var.crawler_name
  })
}
