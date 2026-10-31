# Tag 4: Schreibrechte nur für secret/shop/webhook (PushSecret)
path "secret/data/shop/webhook" {
  capabilities = ["create", "update", "read", "delete"]
}
# ESO markiert das Secret per custom_metadata (managed-by) als seins
path "secret/metadata/shop/webhook" {
  capabilities = ["create", "update", "read", "delete"]
}
