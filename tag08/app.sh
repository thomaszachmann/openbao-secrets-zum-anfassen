#!/bin/sh
# Lab-App: zeigt, was sie per Env bekommt (Passwort maskiert)
TAIL=$(awk -v p="$DB_PASSWORD" 'BEGIN { print substr(p, length(p) - 2) }')
echo "app start pid=$$ DB_USER=$DB_USER DB_PASSWORD=***$TAIL"
trap 'echo "app pid=$$ bekommt SIGTERM"; exit 0' TERM
while true; do sleep 1; done
