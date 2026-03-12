resource "aws_organizations_account" "analyst_account" {
  name  = "Data-Lake-Consumer"
  email = "samuelsmarder@gmail.com" # Must be a unique email

  # Optional: AWS creates this role in the new account so you can 
  # manage it from your main account immediately.
  role_name = "OrganizationAccountAccessRole"

  # If you delete this resource from Terraform, it will only 
  # remove the account from the Org, not close it, unless you set:
  # close_on_deletion = true
}