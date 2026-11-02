#!/usr/bin/env bash
# Fail if staged changes add an AWS account ID, an ARN or a Route 53 hosted zone ID.
# Public history cannot be cleaned after the fact, so this runs as a pre-commit hook.
set -euo pipefail

# AWS documentation placeholder account ID is allowed.
allowed_account='123456789012'

added=$(git diff --cached --unified=0 --no-color -- . ':(exclude)scripts/check-no-secrets.sh' \
  | grep -E '^\+' | grep -vE '^\+\+\+ ' || true)

[[ -z $added ]] && exit 0

found=0
check() {
  local label=$1 pattern=$2 hits
  hits=$(printf '%s\n' "$added" | grep -nE "$pattern" | grep -v "$allowed_account" || true)
  if [[ -n $hits ]]; then
    printf 'check-no-secrets: %s in staged changes:\n%s\n' "$label" "$hits" >&2
    found=1
  fi
}

check 'AWS account ID (12 digits)' '(^|[^0-9])[0-9]{12}([^0-9]|$)'
check 'ARN' 'arn:aws[a-z-]*:'
check 'Route 53 hosted zone ID' '(hostedzone/)?\bZ[0-9A-Z]{12,}\b'

if (( found )); then
  printf 'Move the value to env or a git-ignored file (evidence/raw/, *.tfvars) and redact it before committing.\n' >&2
  exit 1
fi
