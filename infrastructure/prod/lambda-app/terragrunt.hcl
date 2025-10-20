terraform {
  source = "git::https://github.com/VishnuSharma11D00/infrastructure-modules.git//lambda?ref=lambda-v0.1.1"

  before_hook "package_lambdas" {
    commands = ["plan", "apply"]         # o los comandos que necesites
    execute  = ["bash", "${get_terragrunt_dir()}/../../../scripts/package_lambdas.sh"]
  }
}

include "root" {
  path = find_in_parent_folders()
  expose = true
}

include "env" {
  path = find_in_parent_folders("env.hcl")
  expose = true
  merge_strategy = "no_merge"
}


include "mock_outputs" {
  path = "${get_terragrunt_dir()}/mock_outputs.hcl"
  expose = true
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs = include.mock_outputs.locals.mock_outputs_dynamodb
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

locals {
  lambda_package_path = "${get_terragrunt_dir()}/../../../lambda-package"
  my_region        = include.root.locals.aws_region
  account_Id       = tostring(include.root.locals.account_id)
  lambda_prefix    = "app"
  tag_value = "terragrunt_frontend"
}

inputs = {
  env = include.env.locals.env
  aws_region = local.my_region
  account_id = local.account_Id
  prefix = local.lambda_prefix
  
    lambda_functions = {
    lambda2 = {
        name        = "History"
        zip_file    = "${local.lambda_package_path}/history.zip"
        policy_name = "History_lambda-policy"
        tagValue    = local.tag_value
        environment_variables = {
          DYNAMODB_TABLE_NAME = dependency.dynamodb.outputs.table_details["table1"].name
        }
        policy_document = {
          Version = "2012-10-17"
          Statement = [
            {
              Sid      = "DynamoDBQueryAccess"
              Effect   = "Allow"
              Action   = ["dynamodb:*"]              
              Resource = [
                dependency.dynamodb.outputs.table_details["table1"].arn
              ]
            }
          ]
        }
    }
  }
}