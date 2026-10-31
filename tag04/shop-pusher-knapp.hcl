# Tag 4: erster Versuch – zu knapp, Metadaten dürfen nicht geschrieben werden
path "secret/data/shop/webhook" {
  capabilities = ["create", "update", "read", "delete"]
}
path "secret/metadata/shop/webhook" {
  capabilities = ["read", "delete"]
}
