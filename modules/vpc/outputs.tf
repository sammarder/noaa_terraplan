output "vpc_id" {
  value = aws_vpc.data_vpc.id
}

output "glue_connector_name" {
  value = aws_glue_connection.vpc_connector.name
}