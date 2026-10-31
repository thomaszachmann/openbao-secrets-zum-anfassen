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
  auth_login_jwt {
    mount = "jwt-ci"
    role  = "tofu-main"
  }
}

ephemeral "vault_kv_secret_v2" "deploy" {
  mount = "secret"
  name  = "ci/deploy"
}

# Verbraucher: Write-only-Argument, landet nie im State
resource "vault_kv_secret_v2" "app_registry" {
  mount = "secret"
  name  = "ci/tofu/app-registry"
  data_json_wo = jsonencode({
    password = ephemeral.vault_kv_secret_v2.deploy.data.registry_password
  })
  data_json_wo_version = 1
}
