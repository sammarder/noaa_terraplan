# 1. Admin Settings: Ensure these exist BEFORE permissions are managed
resource "aws_lakeformation_data_lake_settings" "admin" {
  admins = [
    var.caller_id, 
    var.glue_proc_role
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
  arn                     = var.bucket_arn
  use_service_linked_role = true
  
  # Ensure the bucket is fully created before LF tries to register it
  depends_on = [var.bucket_id]
}

# 3. Permissions: These MUST point to the registration, not just the bucket
resource "aws_lakeformation_permissions" "crawler_s3_access" {
  principal   = var.glue_crawler_role
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    # Reference the registration resource directly to create a dependency link
    arn = aws_lakeformation_resource.s3_registration.arn
  }
}

resource "aws_lakeformation_permissions" "terraform_s3_access" {
  principal   = var.caller_id
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.s3_registration.arn
  }
}

# 4. Database Permissions: Ensure the DB exists first
resource "aws_lakeformation_permissions" "crawler_database_access" {
  principal   = var.glue_crawler_role
  permissions = ["CREATE_TABLE", "ALTER", "DESCRIBE"]

  database {
    name = var.noaa_catalog_db_name
  }
  
  # Ensure settings are applied before individual permissions
  depends_on = [aws_lakeformation_data_lake_settings.admin]
}

resource "aws_lakeformation_permissions" "terraform_db_access" {
  principal   = var.caller_id
  permissions = ["CREATE_TABLE", "DESCRIBE", "ALTER", "DROP"]

  database {
    name = var.noaa_catalog_db_name
  }
}

# 5. Table Wildcard Permissions
resource "aws_lakeformation_permissions" "crawler_table_perms" {
  principal   = var.glue_crawler_role
  permissions = ["ALL", "ALTER", "DESCRIBE", "INSERT"]

  table {
    database_name = var.noaa_catalog_db_name
    wildcard      = true 
  }
  
  # Tables can't have permissions if the DB permission isn't there yet
  depends_on = [aws_lakeformation_permissions.crawler_database_access]
}