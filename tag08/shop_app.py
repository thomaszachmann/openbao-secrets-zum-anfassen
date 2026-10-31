"""Lab-App: liest secret/shop/api aus OpenBao und hält den Token am Leben."""
import os
import sys
import time

import hvac
from hvac.exceptions import Forbidden, InvalidRequest

ADDR = os.environ.get("BAO_ADDR", "http://127.0.0.1:8200")
ROLE = os.environ.get("BAO_ROLE", "shop-api")
JWT_FILE = os.environ.get("BAO_JWT_FILE", "/var/run/secrets/openbao/token")
INTERVAL = int(os.environ.get("CHECK_INTERVAL", "10"))


def login(client):
    """Kubernetes-Auth: JWT bei jedem Login neu lesen, kubelet rotiert ihn."""
    with open(JWT_FILE) as f:
        jwt = f.read().strip()
    auth = client.auth.kubernetes.login(role=ROLE, jwt=jwt)["auth"]
    print(f"login: ttl={auth['lease_duration']}s "
          f"policies={auth['token_policies']}", flush=True)


def read_secret(client):
    resp = client.secrets.kv.v2.read_secret_version(
        path="shop/api", mount_point="secret", raise_on_deleted_version=True)
    return resp["data"]["data"], resp["data"]["metadata"]["version"]


def keep_alive(client):
    """Erneuern, solange es geht; sonst neu einloggen."""
    ttl = client.auth.token.lookup_self()["data"]["ttl"]
    if ttl > 2 * INTERVAL:
        return
    try:
        new = client.auth.token.renew_self()["auth"]["lease_duration"]
        print(f"renew: ttl {ttl}s -> {new}s", flush=True)
        if new > 2 * INTERVAL:
            return
        print("max_ttl erreicht -> re-login", flush=True)
    except (Forbidden, InvalidRequest) as err:
        print(f"renew fehlgeschlagen ({err.__class__.__name__}) -> re-login",
              flush=True)
    login(client)


def main():
    client = hvac.Client(url=ADDR)
    login(client)
    while True:
        try:
            keep_alive(client)
            data, version = read_secret(client)
            print(f"v{version} db_user={data['db_user']} "
                  f"db_password=***{data['db_password'][-3:]}", flush=True)
        except Forbidden:
            print("403 -> re-login", flush=True)
            login(client)
        except Exception as err:  # Lab: weiterlaufen, aber laut sein
            print(f"Fehler: {err}", file=sys.stderr, flush=True)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
