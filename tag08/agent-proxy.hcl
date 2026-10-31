# bao agent als lokaler Proxy mit Cache (Lab: JWT-Datei vom Laptop)
auto_auth {
  method "kubernetes" {
    mount_path = "auth/kubernetes"
    config = {
      role       = "shop-api-short"
      token_path = "sa.jwt" # im Pod: /var/run/secrets/openbao/token
    }
  }
}

api_proxy {
  use_auto_auth_token = true # Anfragen ohne Token bekommen den Agent-Token
}

cache {}

listener "tcp" {
  address     = "127.0.0.1:8100"
  tls_disable = true
}
