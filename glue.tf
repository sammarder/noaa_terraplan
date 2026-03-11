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
    path = "s3://${aws_s3_bucket.noaa_bucket.id}/parquet/"
  }

  configuration = jsonencode({
    "Version" = 1.0
    "CreatePartitionIndex" : true
  })
}

data "aws_glue_catalog_table" "crawled_table" {
  database_name = aws_glue_catalog_database.noaa_db.name
  name          = "parquet" # The Crawler's guess
}

resource "aws_glue_trigger" "job_to_crawler" {
  name = "trigger-crawler-after-job"
  type = "CONDITIONAL"

  # What to do? Start the Crawler
  actions {
    crawler_name = aws_glue_crawler.noaa_parquet_crawler.name
  }

  # When to do it? When the Job succeeds
  predicate {
    conditions {
      job_name = aws_glue_job.jsonl_to_parquet.name
      state    = "SUCCEEDED"
    }
  }
}