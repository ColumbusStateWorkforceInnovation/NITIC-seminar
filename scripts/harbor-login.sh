#!/bin/bash
# harbor-login — give this VM the shared Harbor push credential for Day 1 Lab 01.
#
# Day 1 Lab 01 pushes to harbor.<lab-domain>/raft-fleet, and Harbor ALWAYS
# requires auth to push (a public project only grants anonymous PULL). A docker
# login is just a base64 "user:secret" stored under .auths[host] in
# ~/.docker/config.json — so this fetches the shared push token and writes that
# entry DIRECTLY. No `docker login`, no running daemon, no 'docker' group needed.
#
# setup-client.sh installs this as the `harbor-login` command and runs the same
# write at setup time, so a freshly-set-up VM needs nothing in class. Run this by
# hand only if `docker push` ever says "unauthorized" (e.g. the shared token was
# rotated after your VM was set up):
#
#   harbor-login                       # if installed by setup-client.sh
#   bash scripts/harbor-login.sh       # straight from a `git pull`ed checkout
#
# Env overrides:
#   LAB_DOMAIN        default: wagbiz.org
#   HARBOR_CREDS_URL  default: https://docs.${LAB_DOMAIN}/creds/harbor-robot.env
set -e

LAB_DOMAIN="${LAB_DOMAIN:-wagbiz.org}"
HOST="harbor.${LAB_DOMAIN}"
URL="${HARBOR_CREDS_URL:-https://docs.${LAB_DOMAIN}/creds/harbor-robot.env}"

# Fetch the shared robot creds. The file is plain KEY=value; parse it LITERALLY
# (grep + cut, never `source`) so the literal '$' in the robot username
# (robot$raft-fleet+raft-pusher) is never shell-expanded.
hc="$(curl -fsSL "$URL")" || { echo "harbor-login: couldn't reach $URL" >&2; exit 1; }
u="$(printf '%s\n' "$hc" | grep -E '^HARBOR_ROBOT_USER='   | head -1 | cut -d= -f2-)"
s="$(printf '%s\n' "$hc" | grep -E '^HARBOR_ROBOT_SECRET=' | head -1 | cut -d= -f2-)"
u="${u#[\"\']}"; u="${u%[\"\']}"; s="${s#[\"\']}"; s="${s%[\"\']}"
[ -n "$u" ] && [ -n "$s" ] || { echo "harbor-login: no creds found at $URL" >&2; exit 1; }

# auth = base64("user:secret") — exactly what `docker login` would persist.
auth="$(printf '%s' "$u:$s" | base64 | tr -d '\n')"
cfg="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
mkdir -p "$(dirname "$cfg")"
if command -v jq > /dev/null 2>&1 && [ -s "$cfg" ]; then
    # Merge into the existing config so any other registry logins are preserved.
    tmp="$(mktemp)"
    if jq --arg h "$HOST" --arg a "$auth" '.auths = ((.auths // {}) + {($h): {auth: $a}})' "$cfg" > "$tmp" 2>/dev/null; then
        mv "$tmp" "$cfg"
    else
        rm -f "$tmp"; printf '{"auths":{"%s":{"auth":"%s"}}}\n' "$HOST" "$auth" > "$cfg"
    fi
else
    printf '{"auths":{"%s":{"auth":"%s"}}}\n' "$HOST" "$auth" > "$cfg"
fi
chmod 600 "$cfg"
echo "✅ Harbor ready — 'docker push $HOST/raft-fleet/<name>:v1' will work."
