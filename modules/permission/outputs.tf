output "glue_proc_role" {
  value = aws_iam_role.glue_proc_role.arn
}

output "glue_crawler_role" {
  value = aws_iam_role.glue_crawler_role.arn
}

output "lambda_role" {
  value = aws_iam_role.lambda_role.arn
}

output "sf_role" {
  value = aws_iam_role.noaa_sf_role.arn
}