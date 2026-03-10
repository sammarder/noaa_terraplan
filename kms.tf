resource "aws_kms_key" "noaa_key" {
  description             = "KMS key for NOAA data"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "minimal_alias" {
  name          = "alias/noaa-data-key"
  target_key_id = aws_kms_key.noaa_key.key_id
}