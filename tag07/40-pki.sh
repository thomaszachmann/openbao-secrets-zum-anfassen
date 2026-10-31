#!/usr/bin/env bash
# Tag 7: PKI-Mount pki/ mit Lab-Root-CA und Rolle shop-svc
set -euo pipefail
bao secrets enable pki
bao secrets tune -max-lease-ttl=87600h pki
bao write -field=certificate pki/root/generate/internal \
  common_name="Secrets-Lab Root CA" ttl=87600h > shop-lab-ca.crt 2>/dev/null
bao write pki/roles/shop-svc allowed_domains=shop.svc allow_subdomains=true \
  max_ttl=72h >/dev/null
bao policy write cert-manager-shop - <<'HCL'
path "pki/sign/shop-svc" {
  capabilities = ["update"]
}
HCL
bao write auth/kubernetes/role/cert-manager-shop \
  bound_service_account_names=shop-issuer \
  bound_service_account_namespaces=shop \
  audience=openbao \
  token_policies=cert-manager-shop token_ttl=5m
