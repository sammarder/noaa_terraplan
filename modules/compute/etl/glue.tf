resource "aws_glue_job" "jsonl_to_parquet" {
  name     = var.job_name
  role_arn = var.glue_etl_role
  command {
    name = "glueetl"
    # Point to the S3 path of the uploaded object
    script_location = "s3://${var.bucket}/${aws_s3_object.templated_script.key}"
    python_version  = "3"
  }
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 2 
  connections       = [var.connector_name]
  timeout = 10
  default_arguments = {
    "--enable-metrics" = "true"
	"--use-postgres-driver" = "true"
  }
}

resource "aws_s3_object" "templated_script" {
  bucket = var.bucket
  key    = "scripts/process_jsonl.py"

  # Render the file with variables before uploading
  content = templatefile("${var.root_dir}/scripts/processor.tftpl", {
    bucket_id = var.bucket
    job_name = var.job_name
  })

  content_type = "text/x-python"

  # Crucial: This ensures S3 updates if the template or variables change
  etag = md5(templatefile("${var.root_dir}/scripts/processor.tftpl", {
    bucket_id = var.bucket
    job_name = var.job_name
  }))
}


resource "aws_glue_catalog_database" "noaa_db" {
  name = "noaa_processed_data"
}

resource "aws_glue_crawler" "noaa_parquet_crawler" {
  database_name = aws_glue_catalog_database.noaa_db.name
  name          = var.crawler_name
  role          = var.crawler_role

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
    location      = "s3://${var.bucket}/parquet/"
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