#!/usr/bin/env bash
set -euxo pipefail
{ set +x; } 2>/dev/null          # Trace aus, bevor ein Secret auftaucht
DB_PW=$(bao kv get -field=db_password secret/shop/api)
set -x
echo "deploy mit ${#DB_PW} Zeichen Passwort"
