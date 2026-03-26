



resource "aws_iam_role_policy" "combined_lambda_policy" {
  name = "preprocessor_consolidated_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${var.caller_identity}:*"
      },
      {
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Effect   = "Allow"
        Resource = "${var.bucket}/*"
      },
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = "${var.bucket}"
      },
      {
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Effect   = "Allow"
        Resource = var.key_arn
      },
      {
        Effect   = "Allow"
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.region}:${var.caller_identity}:parameter/noaa/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "step_func_policy" {
  name = "sf_consolidated_policy"
  role = aws_iam_role.noaa_sf_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${var.caller_identity}:*"
      },
      {
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Effect   = "Allow"
        Resource = "${var.bucket}/*"
      },
	  {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = "arn:aws:lambda:${var.region}:${var.caller_identity}:function:${var.archiver}"
      },
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.bucket}"
      },
      {
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Effect   = "Allow"
        Resource = var.key_arn
      },
	  {
        Action   = ["glue:StartJobRun", "glue:GetJobRun", "glue:BatchStopJobRun"]
        Effect   = "Allow"
        Resource = "arn:aws:glue:${var.region}:${var.caller_identity}:job/${var.glue_job}"
      },
	  {
        Action   = ["glue:StartCrawler", "glue:GetCrawler"]
        Effect   = "Allow"
        Resource = "arn:aws:glue:${var.region}:${var.caller_identity}:crawler/${var.glue_crawler}"
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
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "${var.bucket}",
          "${var.bucket}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "glue:GetConnection"
        ],
        "Resource" : [
          "arn:aws:glue:${var.region}:${var.caller_identity}:catalog"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        "Resource" : [
          var.key_arn #this is fine
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "analyst_access" {
  name        = "data-analyst-athena-policy"
  description = "This is not used at the moment"

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
          "${var.bucket}/parquet/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : "${var.caller_identity}"
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
          var.key_arn
        ]
      }
    ]
  })
}