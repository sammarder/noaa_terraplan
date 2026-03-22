resource "aws_kms_key" "noaa_key" {
  description             = "KMS key for NOAA data"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "minimal_alias" {
  name          = "alias/noaa-data-key"
  target_key_id = aws_kms_key.noaa_key.key_id
}



resource "aws_kms_key_policy" "noaa_key_policy" {
  key_id = aws_kms_key.noaa_key.id
  policy = jsonencode({
    Id = "example-policy"
    Statement = [
  {
    Sid    = "Enable IAM User Permissions"
    Effect = "Allow"
    Principal = {
      AWS = "arn:aws:iam::${var.caller_identity}:root"
    }
    Action   = "kms:*"
    Resource = "*"
  },
  {
    Sid    = "AllowLakeFormationToDecrypt"
    Effect = "Allow"                      
    Principal = {                         
      AWS = "arn:aws:iam::${var.caller_identity}:role/aws-service-role/lakeformation.amazonaws.com/AWSServiceRoleForLakeFormationDataAccess"
    }
    Action = [                            
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*"
    ]
    Resource = aws_kms_key.noaa_key.arn                      
  }
]
    Version = "2012-10-17"
  })
}