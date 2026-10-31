# Tag 3: Zusatz-Policy für dataFrom.find – Metadaten unter shop/ auflisten
path "secret/metadata/shop/*" {
  capabilities = ["list", "read"]
}
path "secret/metadata/shop" {
  capabilities = ["list"]
}
