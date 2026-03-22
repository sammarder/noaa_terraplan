variable "key_arn" {
  type = string
}

variable "glue_crawler" {
  description = "Primary crawler's arn"
  type = string
}

variable "glue_job" {
  description = "Primary job's arn"
  type = string
}

variable "analyst_account" {
  description = "Analyst account id"
  type = string
}

variable "bucket" {
  description = "Bucket's arn"
  type = string
}

variable "archiver_arn" {
  description = "Archiver's lambda arn"
  type = string
}

variable "caller_identity" {
  description = "Current caller number string"
  type = string
}

variable "region" {
  description = "Target region"
  type = string
}