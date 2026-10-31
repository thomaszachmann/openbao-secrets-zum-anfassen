#!/usr/bin/env bash
# Jenkins-Agent: Secret-ID gewrappt holen, auspacken, per AppRole anmelden.
# Erwartet ROLE_ID und ISSUER_TOKEN (aus withCredentials). Wird per "source" geladen.
set -euo pipefail
WRAP=$(BAO_TOKEN=$ISSUER_TOKEN bao write -wrap-ttl=60s -field=wrapping_token \
  -f auth/approle/role/jenkins-deploy/secret-id)
path=$(BAO_TOKEN=$ISSUER_TOKEN bao write -field=creation_path sys/wrapping/lookup \
  token="$WRAP")
[ "$path" = auth/approle/role/jenkins-deploy/secret-id ] \
  || { echo "✘ unerwarteter creation_path: $path" >&2; exit 1; }
SECRET_ID=$(BAO_TOKEN=$WRAP bao unwrap -field=secret_id)
BAO_TOKEN=$(BAO_TOKEN= bao write -field=token auth/approle/login \
  role_id="$ROLE_ID" secret_id="$SECRET_ID")
export BAO_TOKEN
unset SECRET_ID WRAP
