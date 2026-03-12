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

  catalog_target {
    database_name = aws_glue_catalog_table.manual_table.database_name
    tables        = [aws_glue_catalog_table.manual_table.name]
  }
  
  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }
}

resource "aws_glue_catalog_table" "manual_table" {
  name          = "noaa_table"
  database_name = aws_glue_catalog_database.noaa_db.name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.noaa_bucket.id}/parquet/"
    # You must provide a basic format for the Crawler to start
    input_format  = "org.apache.hadoop.mapred.TextInputFormat" 
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    
    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }
  }
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