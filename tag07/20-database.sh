#!/usr/bin/env bash
# Tag 7: kurzlebige DB-Rolle shop-ro-short auf der Verbindung shop-pg aus Tag 4
# (Lab-Werte!). Idempotent: legt database/ nur an, falls Tag 4 übersprungen wurde.
set -euo pipefail
PG=postgres.shop.svc:5432
bao secrets list -format=json | jq -e '."database/"' >/dev/null \
  || bao secrets enable database
bao write database/config/shop-pg \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@$PG/shop?sslmode=disable" \
  username=postgres password=lab-pg-pw \
  allowed_roles=shop-ro,shop-ro-short
bao write database/roles/shop-ro-short db_name=shop-pg \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' \
VALID UNTIL '{{expiration}}'; GRANT pg_read_all_data TO \"{{name}}\";" \
  default_ttl=2m max_ttl=6m
bao policy write shop-api-db - <<'HCL'
path "database/creds/shop-ro-short" {
  capabilities = ["read"]
}
HCL
# Eigene Rolle: shop-api (Tag 0/3) bleibt unverändert
bao write auth/kubernetes/role/shop-api-db \
  bound_service_account_names=shop-api \
  bound_service_account_namespaces=shop \
  audience=openbao \
  token_policies=shop-api-db token_ttl=15m token_max_ttl=1h
