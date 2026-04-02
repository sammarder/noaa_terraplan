variable "glue_crawler" {
  type = string
  default = "noaa_parquet_crawler"
}

variable "glue_job" {
  type = string
  default = "noaa_processor_job"
}

variable "bucket" {
  type = string
  default = "sams-noaa-test-east-2"
}

variable "archiver" {
  type = string
  default = "archiver"
}

variable "region" {
  type = string
  default = "us-east-2"
}