/*----------------------------------delete_pokemon-----------------------------------*/

data "archive_file" "delete_pokemon" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/deletePokemon"
  output_path = "${path.module}/lambdas/deletePokemon.zip"
}

resource "aws_lambda_function" "delete_pokemon" {
  filename      = "${path.module}/lambdas/deletePokemon.zip"
  function_name = "deletePokemon"
  description   = "Delete pokemon for user id"
  role          = aws_iam_role.dynamodbaccess.arn
  handler       = "index.handler"

  source_code_hash = filebase64sha256(data.archive_file.delete_pokemon.output_path)

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

resource "aws_iam_role" "dynamodbaccess" {
  name = "DynamoDbRoleAccessPokemon"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "dynamodbaccess" {
  name        = "DynamoDbRoleAccessPokemon"
  path        = "/"
  description = "DynamoDb access"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:Query",
                "dynamodb:UpdateItem",
                "dynamodb:GetItem",
                "dynamodb:Scan",
                "dynamodb:DeleteItem"
            ],
            "Resource": "${aws_dynamodb_table.pokemons.arn}",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dynamodbaccess" {
  role       = aws_iam_role.dynamodbaccess.name
  policy_arn = aws_iam_policy.dynamodbaccess.arn
}

data "aws_iam_policy" "lambda_execution_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  role       = aws_iam_role.dynamodbaccess.name
  policy_arn = data.aws_iam_policy.lambda_execution_policy.arn
}

/*-------------------------------------------------------------------------------------------*/

resource "aws_lambda_permission" "deletePokemon" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_pokemon.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.pokemons.execution_arn}/*"
}

/*-------------------------------------------------------------------------------------------*/
