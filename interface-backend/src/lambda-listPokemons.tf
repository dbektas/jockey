/*----------------------------------list_pokemons-----------------------------------*/

data "archive_file" "list_pokemons" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/listPokemons"
  output_path = "${path.module}/lambdas/listPokemons.zip"
}

resource "aws_lambda_function" "list_pokemons" {
  filename      = "${path.module}/lambdas/listPokemons.zip"
  function_name = "listPokemons"
  description   = "Get list of pokemons for userId"
  role          = aws_iam_role.dynamodbaccess.arn
  handler       = "index.handler"

  source_code_hash = filebase64sha256(data.archive_file.list_pokemons.output_path)

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

resource "aws_lambda_permission" "listPokemons" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_pokemons.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.pokemons.execution_arn}/*"
}

/*-------------------------------------------------------------------------------------------*/
