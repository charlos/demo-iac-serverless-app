locals {
  mock_outputs_lambda = {
    lambda_details = {
      lambda1 = {
        name = "mock-lambda-name"
        arn  = "arn:aws:lambda:mock-region:mock-account-id:function:mock-lambda-name"
      },
      lambda2 = {
        name = "mock-lambda-name"
        arn  = "arn:aws:lambda:mock-region:mock-account-id:function:mock-lambda-name"
      }
    }
  }
}