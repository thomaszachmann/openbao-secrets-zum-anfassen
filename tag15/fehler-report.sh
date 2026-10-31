#!/usr/bin/env bash
# Tag 15 Challenge: Fehler im Audit-Log je Identität und Pfad zählen (Top 5)
# Nutzung: ./fehler-report.sh [audit.jsonl]
jq -r 'select(.type == "response")
  | select(.error != null or .response.data.error != null)
  | [(.auth.display_name // "-"), .request.path] | @tsv' "${1:-audit.jsonl}" \
  | sort | uniq -c | sort -rn | head -5
