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

data "vault_kv_secret_v2" "deploy" {
  mount = "secret"
  name  = "ci/deploy"
}

output "deploy_keys" {
  value = nonsensitive(keys(data.vault_kv_secret_v2.deploy.data))
}
