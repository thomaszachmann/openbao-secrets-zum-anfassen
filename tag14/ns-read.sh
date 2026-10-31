#!/usr/bin/env bash
# Schreibt das Policy-Template ns-read mit dem Accessor des Mounts kubernetes/ (Lab)
set -euo pipefail
ACC=$(bao auth list -format=json | jq -r '."kubernetes/".accessor')
M="identity.entity.aliases.$ACC.metadata"
bao policy write ns-read - <<HCL
path "secret/data/{{$M.service_account_namespace}}/*" {
  capabilities = ["read"]
}
HCL
