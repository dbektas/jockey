resource "aws_dynamodb_table" "pokemons" {
  name             = "pokemons"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  billing_mode     = "PROVISIONED"
  read_capacity    = 1
  write_capacity   = 1
  hash_key         = "userId"
  range_key        = "uuId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "uuId"
    type = "S"
  }
}
