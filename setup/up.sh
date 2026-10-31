#!/usr/bin/env bash
# Baut das Trainingsgelände: kind-Cluster secrets-lab + OpenBao (Dev-Modus) per Helm
set -euo pipefail
CLUSTER="${CLUSTER:-secrets-lab}"
DIR="$(cd "$(dirname "$0")" && pwd)"
kind get clusters | grep -qx "$CLUSTER" || kind create cluster --name "$CLUSTER" \
  --config "$DIR/kind.yaml"
kubectl config use-context "kind-$CLUSTER" >/dev/null
helm repo add openbao https://openbao.github.io/openbao-helm >/dev/null 2>&1 || true
helm repo update openbao >/dev/null
# --server-side=false: der Injector patcht caBundle selbst; Server-Side-Apply (Helm-4-
# Standard) meldet sonst beim erneuten Lauf einen Konflikt
helm upgrade --install openbao openbao/openbao -n openbao --create-namespace \
  --server-side=false -f "$DIR/openbao-values.yaml" --wait --timeout 5m
# Pod kann nach helm --wait noch fehlen (z. B. nach Neuinstallation)
kubectl -n openbao wait --for=create pod/openbao-0 --timeout=120s >/dev/null
kubectl -n openbao wait --for=condition=Ready pod/openbao-0 --timeout=180s
echo "✔ OpenBao läuft. Weiter: kubectl -n openbao port-forward svc/openbao 8200:8200"
