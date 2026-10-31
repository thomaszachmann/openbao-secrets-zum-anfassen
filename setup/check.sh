#!/usr/bin/env bash
# check.sh – prüft das Trainingsgelände (✔/✘). Exit-Code = Anzahl Fehler.
export BAO_ADDR="${BAO_ADDR:-http://127.0.0.1:8200}" BAO_TOKEN="${BAO_TOKEN:-root}"
fail=0
ok()  { echo "✔ $1"; }
bad() { echo "✘ $1"; fail=$((fail + 1)); }
t()   { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

t "kubectl-Kontext kind-${CLUSTER:-secrets-lab}" \
  "[ \"\$(kubectl config current-context)\" = kind-${CLUSTER:-secrets-lab} ]"
t "Pod openbao-0 Ready" \
  "kubectl -n openbao wait --for=condition=Ready pod/openbao-0 --timeout=5s"
t "OpenBao erreichbar unter $BAO_ADDR (Port-Forward?)" "bao status"
t "Demo-Secret secret/shop/api vorhanden (sonst: seed.sh)" \
  "bao kv get -field=db_user secret/shop/api"
t "Policy shop-api-read vorhanden" "bao policy read shop-api-read"
t "Rolle auth/kubernetes/role/shop-api vorhanden" \
  "bao read auth/kubernetes/role/shop-api"
t "ServiceAccount shop/shop-api vorhanden" "kubectl -n shop get sa shop-api"
t "Login als shop-api klappt" \
  "bao write -field=token auth/kubernetes/login role=shop-api \
     jwt=\"\$(kubectl -n shop create token shop-api --audience openbao)\""
exit "$fail"
