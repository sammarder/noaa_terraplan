resource "aws_lakeformation_data_lake_settings" "admin" {
  admins = [data.aws_caller_identity.current.arn, aws_iam_role.glue_proc_role.arn]

  # This removes the "IAMAllowedPrincipals" default, 
  # forcing Lake Formation to be the gatekeeper for new databases.
}

resource "aws_lakeformation_resource" "s3_registration" {
  arn = aws_s3_bucket.noaa_bucket.arn
  # Use the service-linked role so AWS manages the S3 access for you
  use_service_linked_role = true
}

resource "aws_lakeformation_permissions" "crawler_database_access" {
  principal   = aws_iam_role.glue_crawler_role.arn
  permissions = ["CREATE_TABLE", "ALTER", "DESCRIBE"]

  database {
    name = aws_glue_catalog_database.noaa_db.name
  }
}

resource "aws_lakeformation_permissions" "crawler_s3_access" {
  principal   = aws_iam_role.glue_crawler_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.s3_registration.arn
  }
}

resource "aws_lakeformation_permissions" "crawler_table_perms" {
  principal = aws_iam_role.glue_crawler_role.arn
  permissions = ["ALL", "ALTER", "DESCRIBE", "INSERT"]

  table {
    database_name = aws_glue_catalog_database.noaa_db.name
    wildcard = true 
  }
}

resource "aws_lakeformation_permissions" "terraform_s3_access" {
  principal   = data.aws_caller_identity.current.arn # The role running Terraform
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.s3_registration.arn
  }
}

resource "aws_lakeformation_permissions" "terraform_db_access" {
  principal   = data.aws_caller_identity.current.arn
  permissions = ["CREATE_TABLE", "DESCRIBE", "ALTER", "DROP"]

  database {
    name = aws_glue_catalog_database.noaa_db.name
  }
}

