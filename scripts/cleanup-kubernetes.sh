#!/usr/bin/env bash
# Usage: cleanup-kubernetes.sh ACCOUNT REGION CLUSTER
# Before OpenTofu destroys the cluster: delete only the allowlisted objects that make AWS create
# resources outside OpenTofu state (Ingress -> ALB), then wait until those ALBs are gone.
# Never uses --all. Any guard mismatch exits before the first kubectl mutation.
set -Eeuo pipefail
source "$(dirname "$0")/lib/discover.sh"

usage() { printf 'usage: %s ACCOUNT REGION CLUSTER\n' "${0##*/}" >&2; exit 2; }
(( $# == 3 )) || usage
account=$1 region=$2 cluster=$3
[[ $account =~ ^[0-9]{12}$ ]] || { printf 'bad account: %s\n' "$account" >&2; exit 2; }

TIMEOUT=${CLEANUP_TIMEOUT:-600}   # seconds to wait for ALBs to disappear
POLL=${CLEANUP_POLL:-15}

# namespace/kind/name — the only objects this script may delete.
ALLOWLIST=(
  "argocd/applications.argoproj.io/democicd"
  "boutique/ingress/boutique"
  "demo-app/ingress/democicd"
)

# --- guard 1: account -----------------------------------------------------------------
require_account "$account"

# --- guard 2: the cluster exists and has the exact ARN we expect ------------------------
err=$(mktemp); trap 'rm -f "$err"' EXIT
if ! desc=$(aws eks describe-cluster --region "$region" --name "$cluster" --output json 2>"$err"); then
  if grep -q 'ResourceNotFoundException' "$err"; then
    echo "cluster $cluster not found: nothing to clean"
    exit 0
  fi
  cat "$err" >&2; exit 1
fi
expected_arn="arn:aws:eks:$region:$account:cluster/$cluster"
actual_arn=$(jq -r '.cluster.arn' <<<"$desc")
if [[ "$actual_arn" != "$expected_arn" ]]; then
  printf 'guard: cluster ARN %s, expected %s\n' "$actual_arn" "$expected_arn" >&2
  exit 1
fi

# --- guard 3: kubectl talks to THIS cluster (not the homelab, not another context) ------
endpoint=$(jq -r '.cluster.endpoint' <<<"$desc")
server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
if [[ "$server" != "$endpoint" ]]; then
  printf 'guard: kubeconfig points to %s, cluster endpoint is %s\n' "$server" "$endpoint" >&2
  exit 1
fi
vpc=$(jq -r '.cluster.resourcesVpcConfig.vpcId' <<<"$desc")

# --- delete the allowlist ---------------------------------------------------------------
has_argo=false
if kubectl get crd applications.argoproj.io >/dev/null 2>&1; then has_argo=true; fi

for item in "${ALLOWLIST[@]}"; do
  IFS=/ read -r ns kind name <<<"$item"
  if [[ $kind == applications.argoproj.io && $has_argo == false ]]; then
    echo "skip $item: Argo CD CRD not installed"
    continue
  fi
  echo "delete $item"
  kubectl delete "$kind" "$name" -n "$ns" --ignore-not-found --wait=true --timeout=5m
done

# --- wait until the controller has removed the ALBs in the lab VPC -----------------------
deadline=$(( SECONDS + TIMEOUT ))
while :; do
  left=$(aws elbv2 describe-load-balancers --region "$region" --output json \
    | jq --arg vpc "$vpc" '[.LoadBalancers[] | select(.VpcId == $vpc)] | length')
  (( left == 0 )) && { echo "no load balancers left in $vpc"; break; }
  if (( SECONDS >= deadline )); then
    printf 'timeout: %s load balancer(s) still in %s after %ss\n' "$left" "$vpc" "$TIMEOUT" >&2
    exit 1
  fi
  echo "waiting: $left load balancer(s) in $vpc"
  sleep "$POLL"
done
