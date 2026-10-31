# Anhang B, A2: billing liest genau ein Secret – kein *, kein metadata/
path "secret/data/billing/app" {
  capabilities = ["read"]
}
