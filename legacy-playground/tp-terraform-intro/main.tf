resource "aws_dynamodb_table" "transactions" {
  name = "Transactions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "transaction_id"

  attribute {
    name = "transaction_id"
    type = "S"
  }
}
