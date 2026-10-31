#!/usr/bin/env bash
cd ~/secrets-lab/tag13
git -C gitops grep -q -E 'lab-[a-z-]*-[0-9]+' && echo "✘ Secret-Wert in Git" \
  || echo "✔ GitOps-Repo ohne Secret-Werte"
grep -q 'argocd.argoproj.io/sync-wave: "-1"' gitops/shop/externalsecret.yaml \
  && echo "✔ ExternalSecret in Welle -1" || echo "✘ Sync-Wave fehlt"
grep -q lab-reg-pw tofu-eph/terraform.tfstate && echo "✘ Secret im ephemeral-State" \
  || echo "✔ ephemeral-State sauber"
grep -q lab-reg-pw tofu-data/terraform.tfstate \
  && echo "✔ Data-Source-State enthält Klartext (erwartet, Gegenbeispiel)"
grep -q 'skip_child_token = true' tofu-eph/main.tf && echo "✔ skip_child_token" \
  || echo "✘ skip_child_token fehlt"
