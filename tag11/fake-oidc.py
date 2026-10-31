#!/usr/bin/env python3
"""Lab-Attrappe für den GitHub-OIDC-Token-Endpunkt (ACTIONS_ID_TOKEN_REQUEST_URL).

Antwortet wie GitHub mit {"value": "<JWT>"}; signiert wird per mint-jwt.sh (Tag 10).
Zusätzliche Claims kommen aus der Umgebungsvariable CLAIMS (z. B. "environment=prod").
Nur fürs Lab!
"""
import json, os, subprocess, sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse

BEARER = os.environ.get("REQUEST_TOKEN", "lab-request-token")
MINT = os.environ.get("MINT", "./mint-jwt.sh")


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.headers.get("Authorization", "").lower() != f"bearer {BEARER}":
            self.send_error(401, "bad request token")
            return
        query = parse_qs(urlparse(self.path).query)
        aud = query.get("audience", ["https://github.com/acme"])[0]
        args = [MINT, f"aud={aud}"] + os.environ.get("CLAIMS", "").split()
        jwt = subprocess.run(args, check=True, capture_output=True, text=True).stdout
        body = json.dumps({"value": jwt.strip()}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)
        print(f"Token ausgestellt, aud={aud}", file=sys.stderr)

    def log_message(self, *args):
        pass


HTTPServer(("127.0.0.1", int(os.environ.get("PORT", "8299"))), Handler).serve_forever()
