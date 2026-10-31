#!/usr/bin/env bash
cd ~/secrets-lab/tag12
export BAO_ADDR="${BAO_ADDR:-http://127.0.0.1:8200}" BASE=gitlab-claims.json
gl() { BAO_TOKEN= bao write -field=token auth/jwt-gitlab/login role=shop-deploy \
  jwt="$(./mint-jwt.sh "$@")" >/dev/null 2>&1; }
gl && echo "✔ GitLab-Deploy-Job kommt rein" || echo "✘ GitLab-Login"
gl ref_protected=false && echo "✘ ungeschützter Branch kommt rein" \
  || echo "✔ ungeschützter Branch abgewiesen"
gl aud=https://gitlab.lab.example && echo "✘ falsche aud akzeptiert" \
  || echo "✔ falsche aud abgewiesen"
export ROLE_ID=$(BAO_TOKEN=root bao read -field=role_id \
  auth/approle/role/jenkins-deploy/role-id)
export ISSUER_TOKEN=$(BAO_TOKEN=root bao token create -policy=approle-issuer \
  -ttl=5m -field=token)
( source ci/bao-login.sh && bao kv get -field=registry_password secret/ci/deploy \
  | grep -q lab-reg-pw ) && echo "✔ Jenkins-AppRole-Flow" || echo "✘ AppRole-Flow"
