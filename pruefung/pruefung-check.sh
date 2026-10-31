#!/usr/bin/env bash
# pruefung-check.sh – wertet die praktische Abschlussprüfung aus (Anhang B)
# Voraussetzung: Port-Forward auf 8200, Lab-Issuer aus Tag 10
cd ~/secrets-lab/pruefung || exit 2
export BAO_ADDR="${BAO_ADDR:-http://127.0.0.1:8200}" BAO_TOKEN="${BAO_TOKEN:-root}"
sum=0
pt() {  # pt <aufgabe> <punkte> <text> <befehl...>
  local a=$1 p=$2 t=$3; shift 3
  if "$@" >/dev/null 2>&1; then
    echo "✔ A$a $t (+$p)"; sum=$((sum + p))
  else
    echo "✘ A$a $t (0 von $p)"
  fi
}
K=secret/billing/app
PW=$(bao kv get -field=db_password "$K" 2>/dev/null)
APIKEY=$(bao kv get -field=api_key "$K" 2>/dev/null)
meta() { [ "$(bao kv metadata get -format=json "$K" | jq -r "$1")" = "$2" ]; }
pol() { bao policy read billing-read; }
APP=$(bao token create -policy=billing-read -ttl=5m -field=token 2>/dev/null)
cap() { [ "$(bao token capabilities "$APP" "$1")" = "$2" ]; }
role() { [ "$(bao read -field="$1" auth/kubernetes/role/billing)" = "$2" ]; }
maxttl() { [ "$(bao read -format=json auth/kubernetes/role/billing \
  | jq '.data.token_max_ttl')" -le 3600 ]; }
login() { bao write auth/kubernetes/login role=billing \
  jwt="$(kubectl -n billing create token "$1" --audience openbao)"; }
nologin() { bao read auth/kubernetes/role/billing && ! login "$@"; }
ready() { [ "$(kubectl -n billing get "$1" \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }
k8sval() { [ "$(kubectl -n billing get secret billing-db \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 -d)" = "$PW" ]; }
injected() { [ "$(kubectl -n billing get pod -l app=billing-api -o jsonpath=\
'{.items[0].metadata.annotations.vault\.hashicorp\.com/agent-inject-status}')" \
  = injected ]; }
envfile() { kubectl -n billing exec deploy/billing-api -c app -- \
  cat /vault/secrets/env | grep -q "export API_KEY=\"$APIKEY\""; }
noenv() { injected && ! kubectl -n billing exec deploy/billing-api -c app -- env \
  | grep -q -- "$APIKEY"; }
mint() { KEY=~/secrets-lab/tag10/ci-issuer.key ~/secrets-lab/tag10/mint-jwt.sh \
  repository=acme/billing repository_id=200002 \
  sub=repo:acme/billing:ref:refs/heads/main "$@"; }
ci() { local t; t=$(BAO_TOKEN= bao write -field=token auth/jwt-ci/login \
  role=billing-deploy jwt="$(mint "$@")") || return 1
  BAO_TOKEN=$t bao kv get -field=registry_password secret/ci/billing; }
noci() { bao read auth/jwt-ci/role/billing-deploy && ! ci "$@"; }
reload() { kubectl -n billing get deploy billing-worker -o jsonpath=\
'{.metadata.annotations.secret\.reloader\.stakater\.com/reload}' \
  | grep -qx billing-db; }
rotated() { [ "$PW" != lab-billing-pw-1 ] && [ "$(kubectl -n billing logs \
  deploy/billing-worker --tail=1)" = "start ***${PW#lab-billing-}" ]; }
H=$(bao write -field=hash sys/audit-hash/stdout input=lab-billing-pw-1 2>/dev/null)
nachweis() { grep -q kubernetes-billing-billing audit-nachweis.txt; }
hmac() { [ -n "$H" ] && grep -qF "$H" audit-nachweis.txt; }

pt 1 4 "secret/billing/app mit db_password und api_key" \
  test -n "$PW" -a -n "$APIKEY"
pt 1 3 "Metadaten owner=team-billing" meta .data.custom_metadata.owner team-billing
pt 1 3 "max_versions=5" meta .data.max_versions 5
pt 2 3 "Policy billing-read vorhanden" pol
pt 2 4 "billing-read liest secret/billing/app" cap secret/data/billing/app read
pt 2 3 "billing-read: andere billing-Pfade deny" cap secret/data/billing/x deny
pt 2 3 "billing-read: metadata deny" cap secret/metadata/billing/app deny
pt 2 2 "billing-read: shop deny" cap secret/data/shop/api deny
pt 3 3 "Rolle billing verlangt Audience openbao" role audience openbao
pt 3 3 "Rolle billing nur mit billing-read" role token_policies "[billing-read]"
pt 3 2 "token_max_ttl <= 1h" maxttl
pt 3 4 "Login als billing/billing" login billing
pt 3 3 "Login als billing/default abgewiesen" nologin default
pt 4 5 "SecretStore billing/openbao Ready" ready secretstore/openbao
pt 4 5 "ExternalSecret billing-db synchron" ready externalsecret/billing-db
pt 4 5 "Secret billing-db = aktueller Wert" k8sval
pt 5 5 "billing-api injiziert" injected
pt 5 5 "/vault/secrets/env mit API_KEY" envfile
pt 5 5 "kein Secret in der Container-Env" noenv
pt 6 4 "billing-deploy: main liest secret/ci/billing" ci
pt 6 3 "billing-deploy: Feature-Branch abgewiesen" noci ref=refs/heads/feature
pt 6 3 "billing-deploy: fremde repository_id abgewiesen" noci repository_id=200003
pt 7 3 "billing-worker mit Reloader-Annotation" reload
pt 7 7 "Rotation im Worker angekommen" rotated
pt 8 5 "Audit-Nachweis nennt kubernetes-billing-billing" nachweis
pt 8 5 "Audit-Nachweis enthält HMAC von lab-billing-pw-1" hmac
echo "Summe: $sum von 100"
