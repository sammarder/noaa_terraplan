# 1. Admin Settings: Ensure these exist BEFORE permissions are managed
resource "aws_lakeformation_data_lake_settings" "admin" {
  admins = [
    data.aws_caller_identity.current.arn, 
    aws_iam_role.glue_proc_role.arn
  ]

  create_database_default_permissions {
    permissions = []
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    permissions = []
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }
}

# 2. S3 Registration: Needs to know it depends on the Bucket being ready
resource "aws_lakeformation_resource" "s3_registration" {
  arn                     = module.storage.bucket_arn
  use_service_linked_role = true
  
  # Ensure the bucket is fully created before LF tries to register it
  depends_on = [module.storage]
}

# 3. Permissions: These MUST point to the registration, not just the bucket
resource "aws_lakeformation_permissions" "crawler_s3_access" {
  principal   = aws_iam_role.glue_crawler_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    # Reference the registration resource directly to create a dependency link
    arn = aws_lakeformation_resource.s3_registration.arn
  }
}

resource "aws_lakeformation_permissions" "terraform_s3_access" {
  principal   = data.aws_caller_identity.current.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.s3_registration.arn
  }
}

# 4. Database Permissions: Ensure the DB exists first
resource "aws_lakeformation_permissions" "crawler_database_access" {
  principal   = aws_iam_role.glue_crawler_role.arn
  permissions = ["CREATE_TABLE", "ALTER", "DESCRIBE"]

  database {
    name = aws_glue_catalog_database.noaa_db.name
  }
  
  # Ensure settings are applied before individual permissions
  depends_on = [aws_lakeformation_data_lake_settings.admin]
}

resource "aws_lakeformation_permissions" "terraform_db_access" {
  principal   = data.aws_caller_identity.current.arn
  permissions = ["CREATE_TABLE", "DESCRIBE", "ALTER", "DROP"]

  database {
    name = aws_glue_catalog_database.noaa_db.name
  }
}

# 5. Table Wildcard Permissions
resource "aws_lakeformation_permissions" "crawler_table_perms" {
  principal   = aws_iam_role.glue_crawler_role.arn
  permissions = ["ALL", "ALTER", "DESCRIBE", "INSERT"]

  table {
    database_name = aws_glue_catalog_database.noaa_db.name
    wildcard      = true 
  }
  
  # Tables can't have permissions if the DB permission isn't there yet
  depends_on = [aws_lakeformation_permissions.crawler_database_access]
}