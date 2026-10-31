#!/usr/bin/env bash
# Anhang B, Lösungsskizze A1–A3 und A6 (Admin-Schritte, Lab-Werte!)
set -euo pipefail
export BAO_ADDR="${BAO_ADDR:-http://127.0.0.1:8200}" BAO_TOKEN="${BAO_TOKEN:-root}"
DIR="$(cd "$(dirname "$0")" && pwd)"
# A1: KV-Pfad mit Metadaten
bao kv put secret/billing/app db_password=lab-billing-pw-1 \
  api_key=lab-billing-key-1 >/dev/null
bao kv metadata put -max-versions=5 -custom-metadata=owner=team-billing \
  secret/billing/app
# A2: Least-Privilege-Policy
bao policy write billing-read "$DIR/billing-read.hcl"
# A3: Namespace, ServiceAccount, Kubernetes-Auth-Rolle
kubectl create namespace billing --dry-run=client -o yaml | kubectl apply -f -
kubectl -n billing create serviceaccount billing --dry-run=client -o yaml \
  | kubectl apply -f -
bao write auth/kubernetes/role/billing bound_service_account_names=billing \
  bound_service_account_namespaces=billing audience=openbao \
  token_policies=billing-read token_ttl=15m token_max_ttl=1h
# A6: CI-Rolle für acme/billing (repository_id 200002), nur main
bao kv put secret/ci/billing registry_password=lab-billing-reg >/dev/null
bao policy write billing-ci - <<'HCL'
path "secret/data/ci/billing" {
  capabilities = ["read"]
}
HCL
bao write auth/jwt-ci/role/billing-deploy - <<'JSON'
{
  "role_type": "jwt",
  "user_claim": "sub",
  "bound_audiences": ["openbao"],
  "bound_claims": {"repository_id": "200002", "ref": "refs/heads/main"},
  "claim_mappings": {"repository": "repository", "run_id": "run_id"},
  "token_policies": ["billing-ci"],
  "token_ttl": "5m",
  "token_max_ttl": "10m"
}
JSON
