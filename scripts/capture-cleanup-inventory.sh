#!/usr/bin/env bash
# Usage: capture-cleanup-inventory.sh ACCOUNT REGION CLUSTER OUT_JSON
# Records which lab resources exist before destroy; audit-cleanup.sh checks them afterwards.
set -Eeuo pipefail
source "$(dirname "$0")/lib/discover.sh"

usage() { printf 'usage: %s ACCOUNT REGION CLUSTER OUT_JSON\n' "${0##*/}" >&2; exit 2; }
(( $# == 4 )) || usage
account=$1 region=$2 cluster=$3 out=$4
[[ $account =~ ^[0-9]{12}$ ]] || { printf 'bad account: %s\n' "$account" >&2; exit 2; }

require_account "$account"
resources=$(discover "$region" "$cluster")

mkdir -p "$(dirname "$out")"
jq --arg account "$account" --arg region "$region" --arg cluster "$cluster" \
   --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   '{account:$account, region:$region, cluster:$cluster, captured_at:$at} + .' \
   <<<"$resources" > "$out.tmp"
mv "$out.tmp" "$out"
jq -r 'to_entries[] | select(.value | type == "array") | "\(.key): \(.value | length)"' "$out"
