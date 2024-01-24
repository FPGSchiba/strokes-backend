data "aws_iam_policy_document" "cognito_authenticated_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.pool.id]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["authenticated"]
    }
  }
}

data "aws_iam_policy_document" "cognito_authenticated" {
  statement {
    actions   = ["personalize:PutUsers"]
    resources = ["arn:aws:personalize:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dataset/umbcase/USERS"]
  }
}

resource "aws_iam_policy" "cognito_authenticated" {
  name   = "${var.prefix}-authenticated"
  policy = data.aws_iam_policy_document.cognito_authenticated.json
}

resource "aws_iam_role" "cognito_authenticated" {
  name               = "${var.prefix}-authenticated"
  assume_role_policy = data.aws_iam_policy_document.cognito_authenticated_assume.json
}

resource "aws_iam_role_policy_attachment" "test_attach" {
  role       = aws_iam_role.cognito_authenticated.name
  policy_arn = aws_iam_policy.cognito_authenticated.arn
}

data "aws_iam_policy_document" "cognito_unauthenticated_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.pool.id]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["unauthenticated"]
    }
  }
}

resource "aws_iam_role" "cognito_unauthenticated" {
  name               = "${var.prefix}-cognito-unauthenticated"
  assume_role_policy = data.aws_iam_policy_document.cognito_unauthenticated_assume.json
}

resource "aws_cognito_user_pool" "pool" {
  name                     = var.prefix
  auto_verified_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 5
      max_length = 300
    }
  }

  password_policy {
    temporary_password_validity_days = 7
    minimum_length                   = 10
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name                          = "${var.prefix}-client"
  user_pool_id                  = aws_cognito_user_pool.pool.id
  prevent_user_existence_errors = "ENABLED"
  access_token_validity         = 2
  id_token_validity             = 2
  refresh_token_validity        = 365
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  allowed_oauth_scopes = [
    "aws.cognito.signin.user.admin",
    "email",
    "openid",
    "phone",
    "profile"
  ]
  allowed_oauth_flows = ["code"]
  supported_identity_providers = [
    "COGNITO"
  ]

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

resource "aws_cognito_identity_pool" "pool" {
  identity_pool_name               = var.prefix
  allow_unauthenticated_identities = false
  allow_classic_flow               = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.client.id
    provider_name           = aws_cognito_user_pool.pool.endpoint
    server_side_token_check = false
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "pool" {
  identity_pool_id = aws_cognito_identity_pool.pool.id

  roles = {
    "authenticated"   = "${aws_iam_role.cognito_authenticated.arn}"
    "unauthenticated" = "${aws_iam_role.cognito_unauthenticated.arn}"
  }
}