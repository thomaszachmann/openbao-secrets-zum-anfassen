#!/usr/bin/env bash
# GitHub-Actions-Schritt: OIDC-JWT holen, bei OpenBao einlösen, Secret lesen
set -euo pipefail
JWT=$(curl -sSf -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=openbao" | jq -r .value)
echo "::add-mask::$JWT"
BAO_TOKEN=$(bao write -field=token "auth/$BAO_AUTH_PATH/login" \
  role=shop-prod jwt="$JWT")
echo "::add-mask::$BAO_TOKEN"
export BAO_TOKEN
PW=$(bao kv get -field=registry_password secret/ci/deploy)
echo "::add-mask::$PW"
echo "REGISTRY_PASSWORD=$PW" >> "$GITHUB_ENV"
bao token revoke -self >/dev/null
echo "✔ Secret übergeben, OpenBao-Token widerrufen"
