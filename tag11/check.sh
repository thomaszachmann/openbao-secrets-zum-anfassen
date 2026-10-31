#!/usr/bin/env bash
cd ~/secrets-lab/tag11
export BAO_ADDR="${BAO_ADDR:-http://127.0.0.1:8200}"
login() { BAO_TOKEN= bao write -field=token auth/jwt-ci/login role=shop-prod \
  jwt="$(./mint-jwt.sh "$@")" >/dev/null 2>&1; }
[ "$(BAO_TOKEN=root bao read -field=status auth/jwt-github/config)" = valid ] \
  && echo "✔ jwt-github per Discovery" || echo "✘ jwt-github-Config"
login sub=repo:acme/shop:environment:production && echo "✔ Environment-Login" \
  || echo "✘ Environment-Login"
login sub=repo:acme/shop:pull_request && echo "✘ PR kommt rein" \
  || echo "✔ PR abgewiesen"
login sub=repo:acme/shop:environment:production repository_id=999 \
  && echo "✘ fremde repository_id" || echo "✔ fremde repository_id abgewiesen"
grep -q 'id-token: write' .github/workflows/deploy.yml \
  && echo "✔ Workflow fordert id-token an" || echo "✘ permissions fehlt"
