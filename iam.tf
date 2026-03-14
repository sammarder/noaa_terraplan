resource "aws_iam_role" "lambda_role" {
  name = "preproc_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "glue_crawler_role" {
  name = "noaa_crawler_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "glue_proc_role" {
  name = "noaa_glue_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service_attach" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_service_attach2" {
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



resource "aws_iam_role_policy" "combined_lambda_policy" {
  name = "preprocessor_consolidated_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.noaa_bucket.arn}/*"
      },
      {
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Effect   = "Allow"
        Resource = aws_kms_key.noaa_key.arn
      },
	  {
        Effect   = "Allow"
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        # Replace with your specific parameter ARN for better security
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/noaa/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "glue_s3_access" {
  name = "GlueS3Access"
  role = aws_iam_role.glue_proc_role.id # The role your job assumes

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow"
        Action : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.noaa_bucket.arn}",
          "${aws_s3_bucket.noaa_bucket.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "glue:GetConnection"
        ],
        "Resource" : [
          "arn:aws:glue:${data.aws_region.current.name}:489719310300:catalog"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        "Resource" : [
          aws_kms_key.noaa_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "wind_role" {
  name = "data-lake-wind-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${aws_organizations_account.analyst_account.id}:root"
          Service = "athena.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "temperature_role" {
  name = "data-lake-temp-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
		  AWS = "arn:aws:iam::${aws_organizations_account.analyst_account.id}:root"
          Service = "athena.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "analyst_access" {
  name        = "data-analyst-athena-policy"
  description = "Coarse-grained permissions for Athena and Lake Formation analysts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. Athena Service Access
      {
        Sid    = "AthenaQueryPermissions"
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StopQueryExecution",
          "athena:ListWorkGroups",
          "athena:GetWorkGroup"
        ]
        Resource = "*" # Or restrict to specific workgroup ARNs
      },
      # 2. Glue Catalog Access (Metadata only)
      {
        Sid    = "GlueCatalogMetadataAccess"
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartitions"
        ]
        Resource = "*"
      },
      # 3. Lake Formation Handshake
      {
        Sid    = "LakeFormationAccess"
        Effect = "Allow"
        Action = [
          "lakeformation:GetDataAccess"
        ]
        Resource = "*"
      },
      # 4. S3 Results Bucket (Writing Query Outputs)
      {
        Sid    = "AthenaResultsBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::your-athena-results-bucket",
          "arn:aws:s3:::your-athena-results-bucket/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "glue_crawler_policy" {
  name = "preprocessor_permissions"
  role = aws_iam_role.glue_crawler_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.noaa_bucket.arn}/parquet/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        "Resource" : [
          aws_kms_key.noaa_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}