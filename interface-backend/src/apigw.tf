/*-------------------------------------------------------------------------------*/

resource "aws_api_gateway_rest_api" "pokemons" {
  name        = "pokemons"
  description = "Handling Pokemon Req"
  body = templatefile("${path.root}/files/swagger_apigw.yaml", {
    listPokemons_uri  = aws_lambda_function.list_pokemons.invoke_arn
    createPokemon_uri = aws_lambda_function.create_pokemon.invoke_arn
    getPokemon_uri    = aws_lambda_function.get_pokemon.invoke_arn
    updatePokemon_uri = aws_lambda_function.update_pokemon.invoke_arn
    deletePokemon_uri = aws_lambda_function.delete_pokemon.invoke_arn
  })
}

/*-------------------------------------------------------------------------------*/

resource "aws_api_gateway_authorizer" "pokemons" {
  name                             = "CognitoDefaultUserPoolAuthorizer"
  rest_api_id                      = aws_api_gateway_rest_api.pokemons.id
  authorizer_result_ttl_in_seconds = 300
  type                             = "COGNITO_USER_POOLS"
  provider_arns                    = [module.cognito.arn]
  identity_source                  = "method.request.header.Authorization"

  depends_on = [module.cognito]
}

/*-------------------------------------------------------------------------------*/

resource "aws_api_gateway_deployment" "pokemons" {
  rest_api_id = aws_api_gateway_rest_api.pokemons.id
  stage_name  = "prod"
}

/*-------------------------------------------------------------------------------*/
