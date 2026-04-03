provider "aws" {
  region = var.region
  
  default_tags {
    tags = {
      Project = "noaa"
	  Managed = "Terraform"
	  Team = "Data Engineers"
    }
  }
}
