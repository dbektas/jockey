module "cognito" {

  source = "./cognito"

  user_pool_name = "pokemons"
  #alias_attributes         = []
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  admin_create_user_config_allow_admin_create_user_only = false

  admin_create_user_config_email_message = "Here is your confirmation code: {####}"
  admin_create_user_config_email_subject = "Jockey Confirmation Code"

  admin_create_user_config = {
    unused_account_validity_days = 7
    email_message                = "Here is your verification code: {####} for {username}"
    email_subject                = "Jockey Verification Code"
  }

  password_policy = {
    minimum_length                   = 8
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }

  verification_message_template = {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your verification code is {####}"
    email_subject        = "Your verification code"
  }

  string_schemas = [
    {
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = false
      name                     = "email"
      required                 = true

      string_attribute_constraints = {
        min_length = 3
        max_length = 35
      }
    }
  ]

  # clients
  clients = [
    {
      allowed_oauth_flows                  = []
      allowed_oauth_flows_user_pool_client = false
      allowed_oauth_scopes                 = []
      callback_urls                        = []
      default_redirect_uri                 = ""
      explicit_auth_flows                  = []
      generate_secret                      = false
      logout_urls                          = []
      name                                 = "pokemons"
      read_attributes                      = []
      refresh_token_validity               = 1
      supported_identity_providers         = []
      write_attributes                     = []
    }
  ]

  tags = {}
}

resource "aws_cognito_identity_pool" "pokemons" {
  identity_pool_name               = "pokemonsIdentity"
  allow_unauthenticated_identities = true

  cognito_identity_providers {
    client_id     = module.cognito.client_ids[0]
    provider_name = "cognito-idp.eu-central-1.amazonaws.com/${module.cognito.id}"
  }
}

resource "aws_iam_role" "unauthorized" {
  name = "CognitoUnauthorizedRolePokemon"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.pokemons.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "unauthenticated"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "unauthorized" {
  name = "CognitoUnauthorizedPolicy"
  role = aws_iam_role.unauthorized.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "mobileanalytics:PutEvents",
        "cognito-sync:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "authorized" {
  name = "CognitoAuthorizedRolePokemon"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.pokemons.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "authorized" {
  name = "CognitoAuthorizedPolicy"
  role = aws_iam_role.authorized.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "mobileanalytics:PutEvents",
        "cognito-sync:*",
        "cognito-identity:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "execute-api:Invoke"
      ],
      "Resource": [
        "${aws_api_gateway_rest_api.pokemons.execution_arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_cognito_identity_pool_roles_attachment" "pokemons" {
  identity_pool_id = aws_cognito_identity_pool.pokemons.id

  roles = {
    unauthenticated = aws_iam_role.unauthorized.arn
    authenticated   = aws_iam_role.authorized.arn
  }
}
