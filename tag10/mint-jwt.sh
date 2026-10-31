#!/usr/bin/env bash
# Lab-CI-Issuer: signiert ein JWT (RS256) mit GitHub-artigen Claims. Nur fürs Lab!
# Nutzung: ./mint-jwt.sh [claim=wert ...]  (leerer Wert löscht den Claim)
# Sonderfall ttl=<sek>: Lebensdauer ab jetzt, negativ = schon abgelaufen
# BASE=<datei.json> ersetzt die GitHub-artigen Standard-Claims (Tag 12)
set -euo pipefail
KEY="${KEY:-ci-issuer.key}"
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
payload=$(python3 - "$@" <<'PY'
import json, os, sys, time
now = int(time.time())
c = json.load(open(os.environ["BASE"])) if os.environ.get("BASE") else {
  "iss": "https://ci.lab.example", "aud": "openbao",
  "sub": "repo:acme/shop:ref:refs/heads/main",
  "repository": "acme/shop", "repository_owner": "acme", "repository_id": "100001",
  "ref": "refs/heads/main", "ref_type": "branch", "actor": "zachmann",
  "workflow": "deploy", "event_name": "push", "run_id": "4711",
  "workflow_ref": "acme/shop/.github/workflows/deploy.yml@refs/heads/main",
  "job_workflow_ref": "acme/shop/.github/workflows/deploy.yml@refs/heads/main",
}
ttl = 300
for arg in sys.argv[1:]:
    k, _, v = arg.partition("=")
    if k == "ttl":
        ttl = int(v)
    elif v == "":
        c.pop(k, None)
    else:
        c[k] = v
iat = min(now, now + ttl - 300)
c.update(iat=iat, nbf=iat, exp=now + ttl)
print(json.dumps(c, separators=(",", ":")))
PY
)
header=$(printf '{"alg":"RS256","typ":"JWT","kid":"lab-ci-1"}' | b64url)
body=$(printf '%s' "$payload" | b64url)
sig=$(printf '%s.%s' "$header" "$body" \
  | openssl dgst -sha256 -sign "$KEY" -binary | b64url)
printf '%s.%s.%s\n' "$header" "$body" "$sig"
