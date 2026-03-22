output "pipeline_arn" {
  value = aws_sfn_state_machine.noaa_pipeline.arn
}