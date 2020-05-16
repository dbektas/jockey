/*----------------------------------update_pokemon-----------------------------------*/

data "archive_file" "update_pokemon" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/updatePokemon"
  output_path = "${path.module}/lambdas/updatePokemon.zip"
}

resource "aws_lambda_function" "update_pokemon" {
  filename      = "${path.module}/lambdas/updatePokemon.zip"
  function_name = "updatePokemon"
  description   = "Update pokemon for user id"
  role          = aws_iam_role.dynamodbaccess.arn
  handler       = "index.handler"

  source_code_hash = filebase64sha256(data.archive_file.update_pokemon.output_path)

  runtime     = "nodejs12.x"
  timeout     = "120"
  memory_size = "256"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.pokemons.id
    }
  }

  depends_on = [aws_iam_role_policy_attachment.dynamodbaccess]
}

/*-------------------------------------------------------------------------------------------*/

resource "aws_lambda_permission" "updatePokemon" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_pokemon.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.pokemons.execution_arn}/*"
}

/*-------------------------------------------------------------------------------------------*/
