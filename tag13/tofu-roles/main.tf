terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.12"
    }
  }
}

provider "vault" {
  skip_child_token = true
}

resource "vault_jwt_auth_backend_role" "deploy_staging" {
  backend         = "jwt-ci"
  role_name       = "deploy-staging"
  role_type       = "jwt"
  user_claim      = "sub"
  bound_audiences = ["openbao"]
  bound_claims = {
    repository = "acme/shop"
    ref        = "refs/heads/staging"
  }
  token_policies = ["ci-deploy"]
  token_ttl      = 300
}
