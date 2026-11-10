#!/usr/bin/env bash
# Runs the cleanup scripts against the fake aws CLI. No cloud, no credentials.
set -Euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
export PATH="$root/tests/bin:$PATH"
ACC=111122223333 REG=eu-central-1 CL=eks-lab
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
pass=0 fail=0

# expect <name> <expected-exit> <fixture-set> <command...>
expect() {
  local name=$1 want=$2 set=$3; shift 3
  export FIXTURES="$root/tests/fixtures/$set" FIXTURES_LOG="$tmp/$name.calls"
  "$@" >"$tmp/$name.out" 2>"$tmp/$name.err"
  local got=$?
  if (( got == want )); then
    pass=$((pass + 1)); printf 'ok   %s\n' "$name"
  else
    fail=$((fail + 1)); printf 'FAIL %s: exit %s, want %s\n' "$name" "$got" "$want"
    sed 's/^/     /' "$tmp/$name.err"
  fi
}

cap="$root/scripts/capture-cleanup-inventory.sh"
aud="$root/scripts/audit-cleanup.sh"
inv="$tmp/inventory.json"

expect capture-bad-args       2 up  "$cap" "$ACC" "$REG"
expect capture-bad-account    2 up  "$cap" 12345 "$REG" "$CL" "$inv"
expect capture-wrong-account  1 wrong-account "$cap" "$ACC" "$REG" "$CL" "$inv"
expect capture-api-error      1 api-error     "$cap" "$ACC" "$REG" "$CL" "$tmp/err.json"
expect capture-up             0 up  "$cap" "$ACC" "$REG" "$CL" "$inv"

# The inventory must hold the lab ALB and not the other project's ALB.
if jq -e '(.load_balancers | length) == 1 and (.load_balancers[0] | test("k8s-demo"))
          and (.vpcs == ["vpc-0aaa"]) and (.eks_clusters | length) == 1' "$inv" >/dev/null; then
  pass=$((pass + 1)); echo "ok   inventory-content"
else
  fail=$((fail + 1)); echo "FAIL inventory-content"; cat "$inv"
fi
if [[ ! -e "$tmp/err.json" ]]; then
  pass=$((pass + 1)); echo "ok   no-inventory-on-error"
else
  fail=$((fail + 1)); echo "FAIL no-inventory-on-error"
fi

expect audit-bad-args         2 down "$aud" "$ACC" "$REG"
expect audit-missing-file     2 down "$aud" "$ACC" "$REG" "$tmp/nope.json"
expect audit-other-account    2 down "$aud" 999999999999 "$REG" "$inv"
expect audit-wrong-account    1 wrong-account "$aud" "$ACC" "$REG" "$inv"
expect audit-api-error        1 api-error     "$aud" "$ACC" "$REG" "$inv"
expect audit-clean            0 down "$aud" "$ACC" "$REG" "$inv"
expect audit-leftover-alb     1 leftover-alb  "$aud" "$ACC" "$REG" "$inv"
expect audit-still-running    1 up   "$aud" "$ACC" "$REG" "$inv"

# --- cleanup-kubernetes.sh -------------------------------------------------------------
cln="$root/scripts/cleanup-kubernetes.sh"
export CLEANUP_TIMEOUT=2 CLEANUP_POLL=1

expect k8s-bad-args          2 k8s-ok             "$cln" "$ACC" "$REG"
expect k8s-wrong-account     1 wrong-account      "$cln" "$ACC" "$REG" "$CL"
expect k8s-cluster-absent    0 down               "$cln" "$ACC" "$REG" "$CL"
expect k8s-api-error         1 api-error          "$cln" "$ACC" "$REG" "$CL"
expect k8s-wrong-arn         1 k8s-wrong-arn      "$cln" "$ACC" "$REG" "$CL"
expect k8s-wrong-endpoint    1 k8s-wrong-endpoint "$cln" "$ACC" "$REG" "$CL"
expect k8s-ok                0 k8s-ok             "$cln" "$ACC" "$REG" "$CL"
expect k8s-no-argo           0 k8s-no-argo        "$cln" "$ACC" "$REG" "$CL"
expect k8s-alb-stuck         1 k8s-alb-stuck      "$cln" "$ACC" "$REG" "$CL"

# check <name> <description> <command...>: a plain assertion
check() {
  local name=$1; shift
  if "$@"; then pass=$((pass + 1)); printf 'ok   %s\n' "$name"
  else fail=$((fail + 1)); printf 'FAIL %s\n' "$name"; fi
}
deletes() { grep -c '^kubectl delete' "$tmp/$1.calls" || true; }

# Guards must stop the script before any delete.
for t in k8s-wrong-account k8s-api-error k8s-wrong-arn k8s-wrong-endpoint k8s-cluster-absent; do
  check "$t-no-delete" test "$(deletes "$t")" -eq 0
done
check k8s-ok-deletes-3        test "$(deletes k8s-ok)" -eq 3
check k8s-no-argo-deletes-2   test "$(deletes k8s-no-argo)" -eq 2
check k8s-only-allowlist      grep -qxE 'kubectl delete (applications.argoproj.io democicd -n argocd|ingress boutique -n boutique|ingress democicd -n demo-app) --ignore-not-found --wait=true --timeout=5m' "$tmp/k8s-ok.calls"
no_all() { ! grep -h -- '--all' "$tmp"/*.calls; }
check k8s-never-all           no_all

# Read-only: no aws call may create, delete or modify anything.
if grep -hvE '^kubectl ' "$tmp"/*.calls | grep -E ' (delete|create|terminate|release|modify|put|update)-'; then
  fail=$((fail + 1)); echo "FAIL read-only"
else
  pass=$((pass + 1)); echo "ok   read-only"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
