variable "caller_arn" {
  type = string
}

variable "glue_proc_role" {
  type = string
}

variable "glue_crawler_role" {
  type = string
}

variable "noaa_catalog_db_name" {
  type = string
}

variable "bucket" {
  type = object({
    arn = string
    id  = string
  })
}