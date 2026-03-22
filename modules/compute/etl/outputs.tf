output "noaa_catalog_db_name" {
  value = aws_glue_catalog_database.noaa_db.name
}

output "noaa_catalog_db_arn" {
  value = aws_glue_catalog_database.noaa_db.arn
}

output "noaa_crawler_arn" {
  value = aws_glue_crawler.noaa_parquet_crawler.arn
}

output "noaa_glue_etl_arn" {
  value = aws_glue_job.jsonl_to_parquet.arn
}

output "noaa_glue_etl_name" {
  value = aws_glue_job.jsonl_to_parquet.name
}

output "noaa_glue_crawler_name" {
  value = aws_glue_crawler.noaa_parquet_crawler.name
}