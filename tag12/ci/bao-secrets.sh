#!/bin/sh
# GitLab-Job: ID-Token bei OpenBao einlösen, Secret als Datei ablegen, Token widerrufen
set -eu
BAO_TOKEN=$(bao write -field=token auth/jwt-gitlab/login \
  role=shop-deploy jwt="$OPENBAO_ID_TOKEN")
export BAO_TOKEN
umask 077
bao kv get -field=registry_password secret/ci/deploy > "${TMPDIR:-/tmp}/registry-pw"
echo "✔ Secret als Datei abgelegt"
bao token revoke -self >/dev/null && echo "✔ OpenBao-Token widerrufen"
