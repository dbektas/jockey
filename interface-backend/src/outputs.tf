output "cognito_user_pool" {
  value = module.cognito.id
}

output "cognito_client_id" {
  value = module.cognito.client_ids[0]
}

output "cognito_identity_pool" {
  value = aws_cognito_identity_pool.pokemons.id
}

output "region" {
  value = var.region
}

output "api_url" {
  value = "${aws_api_gateway_rest_api.pokemons.execution_arn}/prod"
}
