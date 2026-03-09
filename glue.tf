resource "aws_glue_job" "jsonl_to_parquet" {
  name     = "noaa_preprocessor_job"
  role_arn = aws_iam_role.glue_proc_role.arn
  command {
    name = "glueetl"
    # Point to the S3 path of the uploaded object
    script_location = "s3://${aws_s3_bucket.noaa_bucket.id}/${aws_s3_object.templated_script.key}"
    python_version  = "3"
  }
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 2 # Minimum for Spark
  connections       = [aws_glue_connection.vpc_connector.name]
}

resource "aws_glue_catalog_database" "noaa_db" {
  name = "noaa_processed_data"
}

resource "aws_glue_crawler" "noaa_parquet_crawler" {
  database_name = aws_glue_catalog_database.noaa_db.name
  name          = "noaa_parquet_crawler"
  role          = aws_iam_role.glue_crawler_role.arn

  s3_target {
    # Point this to your Parquet output folder
    path = "s3://${aws_s3_bucket.noaa_bucket.id}/parquet/"
  }

  # This tells the crawler to only update the schema if it changes
  configuration = jsonencode({
    "Version" = 1.0
    "CreatePartitionIndex" : true
  })
}