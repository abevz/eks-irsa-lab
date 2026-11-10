#!/usr/bin/env bash
# Usage: audit-cleanup.sh ACCOUNT REGION INVENTORY_JSON
# After destroy: discovers lab resources again. Anything left = exit 1, not a warning.
set -Eeuo pipefail
source "$(dirname "$0")/lib/discover.sh"

usage() { printf 'usage: %s ACCOUNT REGION INVENTORY_JSON\n' "${0##*/}" >&2; exit 2; }
(( $# == 3 )) || usage
account=$1 region=$2 inventory=$3
[[ -r $inventory ]] || { printf 'inventory not readable: %s\n' "$inventory" >&2; exit 2; }
jq -e --arg a "$account" --arg r "$region" '.account == $a and .region == $r' "$inventory" >/dev/null \
  || { printf 'inventory is for another account/region\n' >&2; exit 2; }

require_account "$account"
cluster=$(jq -r '.cluster' "$inventory")
now=$(discover "$region" "$cluster")

# Per resource type: how many were there before destroy, what is still there now.
jq -r --slurpfile before "$inventory" '
  to_entries[] | "\(.key): before \($before[0][.key] | length), left \(.value | length) \(.value | join(" "))"' <<<"$now"

if jq -e '[.[] | length] | add == 0' <<<"$now" >/dev/null; then
  echo "audit: clean"
else
  echo "audit: leftovers found" >&2
  exit 1
fi
