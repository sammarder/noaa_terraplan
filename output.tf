data "aws_region" "current" {}

output "aws_region" {
  description = "The AWS region where resources were deployed"
  value       = data.aws_region.current.name
}
