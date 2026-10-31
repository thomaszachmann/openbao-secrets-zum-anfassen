# Nur, was shop-api wirklich braucht
path "secret/data/shop/*" {
  capabilities = ["read"]
}
# Unterpfad explizit sperren: deny schlägt jede andere Regel
path "secret/data/shop/admin/*" {
  capabilities = ["deny"]
}
