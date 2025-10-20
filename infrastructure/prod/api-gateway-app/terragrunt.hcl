terraform {
  source = "git::https://github.com/VishnuSharma11D00/infrastructure-modules.git//api-gateway?ref=api-gateway-v0.1.0"
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

locals {
  my_region        = include.root.locals.aws_region
  account_Id       = tostring(include.root.locals.account_id)
}

include "mock_outputs" {
  path = "${get_terragrunt_dir()}/mock_outputs.hcl"
  expose = true
}

dependency "lambda"{
    config_path = "../lambda-app"

    mock_outputs = include.mock_outputs.locals.mock_outputs_lambda
    mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}


inputs = {
    env = include.env.locals.env
    api_name = "Strength_cat_apigw"
    cors_allowed_origin = "*"
    my_region = local.my_region
    account_Id = local.account_Id

    api_configurations = {
        api1 = {
            path_part_name = "strength-cat"
            api_method = "POST"
            lambda_function_name = dependency.lambda.outputs.lambda_details["lambda1"].name
            lambda_function_arn = dependency.lambda.outputs.lambda_details["lambda1"].arn
            mapping_template_body = "$input.json('$')"
        },
        api2 = {
            path_part_name = "history"
            api_method = "GET"
            lambda_function_name = dependency.lambda.outputs.lambda_details["lambda2"].name
            lambda_function_arn = dependency.lambda.outputs.lambda_details["lambda2"].arn
            mapping_template_body = <<EOT
            {
              "username": "$input.params('username')"
            }
            EOT
        }
    }

}