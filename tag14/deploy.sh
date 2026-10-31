#!/usr/bin/env bash
set -euxo pipefail
DB_PW=$(bao kv get -field=db_password secret/shop/api)
echo "deploy mit ${#DB_PW} Zeichen Passwort"
