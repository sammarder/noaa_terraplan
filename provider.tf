provider "aws" {
  region = "us-east-2"
  
  default_tags {
    tags = {
      Project = "noaa"
	  Managed = "Terraform"
	  Team = "Data Engineers"
    }
  }
}
