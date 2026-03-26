resource "aws_iam_role_policy_attachment" "glue_service_crawler_attach" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_service_proc_attach" {
  role       = aws_iam_role.glue_proc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "wind_attach" {
  role       = aws_iam_role.wind_role.name
  policy_arn = aws_iam_policy.analyst_access.arn
}

resource "aws_iam_role_policy_attachment" "temperature_attach" {
  role       = aws_iam_role.temperature_role.name
  policy_arn = aws_iam_policy.analyst_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}