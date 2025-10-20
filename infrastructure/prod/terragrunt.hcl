# Terragrunt/terragrunt.hcl

locals {
  aws_region     = get_env("AWS_REGION", "us-east-1")
  account_id     = get_env("ACCOUNT_ID", "")
  state_prefix   = "demo-prod"
  # make this very unique so there won't be state clash between different projects
}

remote_state {
  backend = "s3"
  generate = {
    path      = "state.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # profile = "Terraform" # no need for this when it is doing aws configure in github actions
    bucket = "${local.state_prefix}-tf-state"

    key = "${path_relative_to_include()}/terraform.tfstate"
    region = local.aws_region
    encrypt = true
    dynamodb_table = "${local.state_prefix}-terraform-lock-table"

    assume_role = {
      role_arn = "arn:aws:iam::${local.account_id}:role/demo-terraform"
    }
  }
}


generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region     = "${local.aws_region}"
  # profile = "Terraform"

  assume_role {
    # (valid ~1 hour by default and session name helps audit logs)
    session_name = "demo-prod"
    role_arn = "arn:aws:iam::${local.account_id}:role/demo-terraform"
  }
 
}
EOF
}



