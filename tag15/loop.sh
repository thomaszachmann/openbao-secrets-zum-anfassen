#!/bin/sh
# Tag 15: Direkt-Leser – einmal einloggen, dann alle 5 s erneuern und lesen (Lab)
BAO=http://openbao.openbao.svc:8200
login() {
  JWT=$(cat /var/run/secrets/openbao/token)
  TOKEN=$(curl -s -X POST "$BAO/v1/auth/kubernetes/login" \
    -d "{\"role\":\"shop-loop\",\"jwt\":\"$JWT\"}" \
    | sed 's/.*"client_token":"\([^"]*\)".*/\1/')
  echo "$(date +%T) login"
}
login
while sleep 5; do
  TTL=$(curl -s -X POST -H "X-Vault-Token: $TOKEN" \
    "$BAO/v1/auth/token/renew-self" | sed -n 's/.*"lease_duration":\([0-9]*\).*/\1/p')
  CODE=$(curl -s -o /dev/null -w '%{http_code}' -H "X-Vault-Token: $TOKEN" \
    "$BAO/v1/secret/data/shop/api")
  echo "$(date +%T) renew ttl=${TTL:--} read HTTP $CODE"
done
