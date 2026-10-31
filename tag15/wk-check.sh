#!/usr/bin/env bash
# Tag 15: Wettkampf-Matrix – kommen alle Verbraucher an ihre Secrets? (✔/✘)
# Exit-Code = Anzahl ✘. Optional: pipeline.claims (Claims der Lab-Pipeline)
export BAO_ADDR="${BAO_ADDR:-http://127.0.0.1:8200}" BAO_TOKEN="${BAO_TOKEN:-root}"
DIR="$(cd "$(dirname "$0")" && pwd)"
fail=0
t() {
  local n=$1; shift
  if "$@" >/dev/null 2>&1; then echo "✔ $n"
  else echo "✘ $n"; fail=$((fail + 1)); fi
}
PW=$(bao kv get -field=db_password secret/shop/api 2>/dev/null) || PW=__fehlt__
CLAIMS=$(cat "$DIR/pipeline.claims" 2>/dev/null)
ready() { [ "$(kubectl -n shop get "$1" \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }
last() { kubectl -n shop logs "deploy/$1" -c app --tail=1; }
file() { kubectl -n shop exec "deploy/$1" -c app -- cat "$2" | grep -q -- "$PW"; }
envok() { last shop-api | grep -q "env=$PW vol="; }
subok() { last shop-api | grep -q "subpath=$PW\$"; }
loopok() { last shop-api-loop | grep -q 'HTTP 200'; }
pgok() { last shop-api-pg | grep -q ' v-'; }
mint() { KEY=~/secrets-lab/tag10/ci-issuer.key ~/secrets-lab/tag10/mint-jwt.sh "$@"; }
ci() { BAO_TOKEN= bao write auth/jwt-ci/login role=deploy-main jwt="$(mint $CLAIMS)"; }
pods() { kubectl -n shop wait --for=condition=Ready pod --all --timeout=5s; }

t "SecretStore openbao Ready"         ready secretstore/openbao
t "ExternalSecret shop-api synchron"  ready externalsecret/shop-api
t "ExternalSecret shop-db synchron"   ready externalsecret/shop-db
t "shop-api: Env aktuell"             envok
t "shop-api: subPath aktuell"         subok
t "shop-api-inj: Datei aktuell"       file shop-api-inj /vault/secrets/env
t "shop-api-csi: Datei aktuell"       file shop-api-csi /mnt/secrets/db_password
t "shop-api-loop: liest (HTTP 200)"   loopok
t "shop-api-pg: DB-Login klappt"      pgok
t "CI: deploy-main-Login"             ci
t "alle Pods in shop Ready"           pods
echo "Fehler: $fail"
exit "$fail"
