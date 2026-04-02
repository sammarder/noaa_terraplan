# 1. Admin Settings: Ensure these exist BEFORE permissions are managed


# 2. S3 Registration: Needs to know it depends on the Bucket being ready
resource "aws_lakeformation_resource" "s3_registration" {
  arn                     = "arn:aws:s3:::${var.bucket.id}"
  use_service_linked_role = true
  
  # Ensure the bucket is fully created before LF tries to register it
  depends_on = [var.bucket]
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
  principal   = var.caller_arn
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
}

resource "aws_lakeformation_permissions" "terraform_db_access" {
  principal   = var.caller_arn
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
