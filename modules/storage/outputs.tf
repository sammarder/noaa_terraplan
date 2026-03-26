

output "bucket_details" {
  description = "Creating a bucket info object"
  value = {
    id = aws_s3_bucket.noaa_bucket.id
    arn = aws_s3_bucket.noaa_bucket.arn
  }
}