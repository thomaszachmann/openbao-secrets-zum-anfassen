#!/usr/bin/env bash
# Tag 6: Secrets Store CSI Driver + OpenBao-CSI-Provider installieren
set -euo pipefail
helm repo add secrets-store-csi-driver \
  https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts >/dev/null
helm repo update secrets-store-csi-driver >/dev/null
helm upgrade --install csi secrets-store-csi-driver/secrets-store-csi-driver \
  -n kube-system --version 1.6.1 \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true \
  --set rotationPollInterval=30s --wait
# CSI-Provider dauerhaft einschalten: jedes spätere helm upgrade (up.sh, Tag 14)
# nimmt die Werte-Datei mit
sed -i.bak '/^csi:/,/enabled:/s/enabled: false/enabled: true/' \
  ~/secrets-lab/setup/openbao-values.yaml
helm upgrade openbao openbao/openbao -n openbao --server-side=false \
  -f ~/secrets-lab/setup/openbao-values.yaml --wait
kubectl -n openbao rollout status ds/openbao-csi-provider --timeout=120s
