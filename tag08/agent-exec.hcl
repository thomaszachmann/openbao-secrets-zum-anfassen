# bao agent als Prozess-Supervisor (Lab: JWT-Datei vom Laptop)
auto_auth {
  method "kubernetes" {
    mount_path = "auth/kubernetes"
    config = {
      role       = "shop-api-short"
      token_path = "sa.jwt" # im Pod: /var/run/secrets/openbao/token
    }
  }
}

template_config {
  static_secret_render_interval = "10s" # KV v2 alle 10 s neu prüfen
  exit_on_retry_failure         = true
}

env_template "DB_USER" {
  contents             = <<-EOT
    {{- with secret "secret/data/shop/api" }}{{ .Data.data.db_user }}{{ end -}}
  EOT
  error_on_missing_key = true
}

env_template "DB_PASSWORD" {
  contents             = <<-EOT
    {{- with secret "secret/data/shop/api" }}{{ .Data.data.db_password }}{{ end -}}
  EOT
  error_on_missing_key = true
}

exec {
  command                   = ["./app.sh"]
  restart_on_secret_changes = "always"
  restart_stop_signal       = "SIGTERM"
}
