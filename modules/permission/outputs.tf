output "role_arns" {
  description = "Map of all relevant iam roles"
  value = {
    glue_process = aws_iam_role.glue_proc_role.arn
	glue_crawler = aws_iam_role.glue_crawler_role.arn
	lambda = aws_iam_role.lambda_role.arn
	step_function = aws_iam_role.noaa_sf_role.arn
  }
}