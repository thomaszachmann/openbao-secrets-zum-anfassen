# Nur genau das eine Secret, das shop-api braucht – keine Wildcard
path "secret/data/shop/api" {
  capabilities = ["read"]
}
