locals {
  mock_outputs_dynamodb = {
    table_details = {
      table1 = {
        name = "mock-table-name"
        arn  = "arn:aws:dynamodb:mock-region:mock-account-id:table/mock-table-name"
      }
    }
  }
}