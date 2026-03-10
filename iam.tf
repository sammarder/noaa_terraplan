resource "aws_iam_role" "iam_for_lambda_noaa_east_2" {
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

resource "local_file" "lambda_rendered" {
  content = templatefile("${path.module}/scripts/s3_lambda_trigger.tftpl", {
    glue_job = aws_glue_job.jsonl_to_parquet.id
  })
  filename = "${path.module}/scripts/s3_lambda_trigger.py"
}

resource "aws_iam_role_policy" "combined_lambda_policy" {
  name = "preprocessor_consolidated_policy"
  role = aws_iam_role.iam_for_lambda_noaa_east_2.id

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
        Action   = "glue:StartJobRun"
        Effect   = "Allow"
        Resource = aws_glue_job.jsonl_to_parquet.arn
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
        Effect = "Allow"
        Action = [
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
            "aws:ResourceAccount" : "489719310300"
          }
        }
      }
    ]
  })
}





resource "aws_iam_policy" "crawler_s3_policy" {
  name = "noaa_crawler_s3_access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.noaa_bucket.arn,       # Bucket level
          "${aws_s3_bucket.noaa_bucket.arn}/*" # Object level
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attach" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.crawler_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.iam_for_lambda_noaa_east_2.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}