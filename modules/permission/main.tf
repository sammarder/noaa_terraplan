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

resource "aws_iam_role" "noaa_sf_role" {
  name = "noaa_sf_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
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
        Resource = "${var.archiver_arn}"
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
        Action   = ["glue:StartJobRun", "glue:GetJobRun", "glue:BatchStopJobRun"]
        Effect   = "Allow"
        Resource = var.glue_job
      },
	  {
        Action   = ["glue:StartCrawler", "glue:GetCrawler"]
        Effect   = "Allow"
        Resource = var.glue_crawler
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
          var.key_arn
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
          AWS = "arn:aws:iam::${var.analyst_account}:root"
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
		  AWS = "arn:aws:iam::${var.analyst_account}:root"
          Service = "athena.amazonaws.com"
        }
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

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
