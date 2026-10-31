#!/usr/bin/env bash
cd ~/secrets-lab/tag10
export BAO_ADDR="${BAO_ADDR:-http://127.0.0.1:8200}"
login() { BAO_TOKEN= bao write -field=token auth/jwt-ci/login role=$1 \
  jwt="$(./mint-jwt.sh "${@:2}")" 2>/dev/null; }
T=$(login deploy-main)
[ "$(BAO_TOKEN=$T bao kv get -field=registry_password secret/ci/deploy 2>/dev/null)" \
  = lab-reg-pw ] && echo "✔ main darf secret/ci/deploy lesen" || echo "✘ main-Login"
login deploy-main ref=refs/heads/dev >/dev/null && echo "✘ dev-Branch kommt rein" \
  || echo "✔ dev-Branch abgewiesen"
login deploy-main ttl=-120 >/dev/null && echo "✘ abgelaufenes JWT akzeptiert" \
  || echo "✔ abgelaufenes JWT abgewiesen"
login deploy-release ref=refs/tags/v2.0.0 >/dev/null && echo "✔ Tag-Release per Glob" \
  || echo "✘ Glob-Rolle"
[ "$(BAO_TOKEN=root bao read -field=secret_id_num_uses \
  auth/approle/role/jenkins-deploy)" = 1 ] && echo "✔ Secret-ID einmalig" \
  || echo "✘ secret_id_num_uses"
