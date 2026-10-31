#!/usr/bin/env bash
# Legt die Demo-Daten an (Lab-Werte!). Voraussetzung: Port-Forward auf 8200 läuft.
set -euo pipefail
export BAO_ADDR="${BAO_ADDR:-http://127.0.0.1:8200}" BAO_TOKEN="${BAO_TOKEN:-root}"

bao kv put secret/shop/api db_user=shop db_password=lab-db-pw-123 \
  api_key=lab-api-key-456 >/dev/null
bao kv put secret/shop/stripe token=lab-stripe-789 >/dev/null

bao policy write shop-api-read - <<'HCL'
path "secret/data/shop/*" {
  capabilities = ["read"]
}
HCL

bao auth list -format=json | jq -e '."kubernetes/"' >/dev/null \
  || bao auth enable kubernetes
# OpenBao läuft im Cluster: CA und Reviewer-Token kommen aus dem eigenen Pod
bao write auth/kubernetes/config kubernetes_host="https://kubernetes.default.svc:443"
bao write auth/kubernetes/role/shop-api \
  bound_service_account_names=shop-api \
  bound_service_account_namespaces=shop \
  audience=openbao \
  token_policies=shop-api-read token_ttl=15m token_max_ttl=1h >/dev/null

kubectl create namespace shop --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n shop create serviceaccount shop-api --dry-run=client -o yaml \
  | kubectl apply -f - >/dev/null
echo "✔ Demo-Daten, Policy shop-api-read, Rolle kubernetes/shop-api, NS shop angelegt"
