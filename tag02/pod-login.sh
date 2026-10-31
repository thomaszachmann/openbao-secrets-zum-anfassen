# pod-login.sh – läuft IM Pod login-test:
#   kubectl -n shop exec -i login-test -- sh < pod-login.sh
BAO=http://openbao.openbao.svc:8200
JWT=$(cat /var/run/secrets/openbao/token)
curl -s -X POST "$BAO/v1/auth/kubernetes/login" \
  -d "{\"role\":\"shop-api\",\"jwt\":\"$JWT\"}" > /tmp/login.json
TOKEN=$(sed 's/.*"client_token":"\([^"]*\)".*/\1/' /tmp/login.json)
echo "Token: $(echo "$TOKEN" | cut -c1-6)…"
curl -s -H "X-Vault-Token: $TOKEN" "$BAO/v1/secret/data/shop/api" \
  | grep -o '"data":{"api_key[^}]*}'
