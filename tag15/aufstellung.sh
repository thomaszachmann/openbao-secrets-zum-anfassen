#!/usr/bin/env bash
# Tag 15, Drill 0: definierter Startzustand für den Wettkampf (Lab-Werte!)
# Voraussetzung: Port-Forward auf 8200, ESO (Tag 3), CSI (Tag 6), Reloader (Tag 9),
# Lab-Issuer aus Tag 10 (~/secrets-lab/tag10/ci-issuer.{key,pub})
set -euo pipefail
export BAO_ADDR="${BAO_ADDR:-http://127.0.0.1:8200}" BAO_TOKEN="${BAO_TOKEN:-root}"
C=~/secrets-lab/code
DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. Namespace shop frisch, Demo-Daten neu (Tag 0)
kubectl delete namespace shop --ignore-not-found --wait=true >/dev/null
~/secrets-lab/setup/seed.sh

# 2. Dynamische DB-Credentials (Tag 4/7): Postgres, database/, Rolle shop-api-db
kubectl apply -f "$C/tag04/postgres.yaml" >/dev/null
kubectl -n shop rollout status deploy/postgres --timeout=180s >/dev/null
# idempotent: legt database/ bei Bedarf an, schreibt shop-pg neu (neuer Postgres)
(cd "$C/tag07" && ./20-database.sh) >/dev/null

# 3. Pipeline-Identität (Tag 10): jwt-ci/, Policy ci-deploy, Rolle deploy-main
bao kv put secret/ci/deploy registry_password=lab-reg-pw \
  kubeconfig_token=lab-kube-token >/dev/null
bao policy write ci-deploy - >/dev/null <<'HCL'
path "secret/data/ci/deploy" {
  capabilities = ["read"]
}
HCL
bao auth list -format=json | jq -e '."jwt-ci/"' >/dev/null \
  || bao auth enable -path=jwt-ci jwt >/dev/null
bao write auth/jwt-ci/config bound_issuer=https://ci.lab.example \
  jwt_validation_pubkeys=@"$HOME/secrets-lab/tag10/ci-issuer.pub" >/dev/null
bao write auth/jwt-ci/role/deploy-main - >/dev/null <<'JSON'
{
  "role_type": "jwt",
  "user_claim": "sub",
  "bound_audiences": ["openbao"],
  "bound_claims_type": "string",
  "bound_claims": {"repository": "acme/shop", "ref": "refs/heads/main"},
  "token_policies": ["ci-deploy"],
  "token_ttl": "5m",
  "token_max_ttl": "10m"
}
JSON
rm -f "$DIR/pipeline.claims"

# 4. Rolle shop-loop für den Direkt-Leser (Muster aus Tag 8)
bao write auth/kubernetes/role/shop-loop bound_service_account_names=shop-api \
  bound_service_account_namespaces=shop audience=openbao \
  token_policies=shop-api-read token_ttl=20s token_max_ttl=10m >/dev/null

# 5. Workloads: ESO (Tag 3/9), Tag-9-App, Injector, CSI, Direkt-Leser, DB-App
kubectl apply -f "$C/tag03/secretstore.yaml" -f "$C/tag03/es-api.yaml" \
  -f "$DIR/20-es-shop-db.yaml" >/dev/null
kubectl -n shop wait --for=condition=Ready es/shop-db --timeout=120s >/dev/null
kubectl apply -f "$C/tag09/shop-api.yaml" >/dev/null
kubectl -n shop annotate deploy/shop-api \
  secret.reloader.stakater.com/reload=shop-db --overwrite >/dev/null
kubectl -n shop create configmap shop-loop --from-file="$DIR/loop.sh" >/dev/null
kubectl apply -f "$C/tag06/10-spc.yaml" -f "$DIR/40-shop-api-inj.yaml" \
  -f "$DIR/50-shop-api-csi.yaml" -f "$DIR/60-shop-api-loop.yaml" \
  -f "$DIR/70-shop-api-pg.yaml" >/dev/null
for d in shop-api shop-api-inj shop-api-csi shop-api-loop shop-api-pg; do
  kubectl -n shop rollout status "deploy/$d" --timeout=180s >/dev/null
done
echo "✔ Aufstellung fertig – weiter mit ./wk-check.sh"
