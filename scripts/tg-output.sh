#!/usr/bin/env bash
# scripts/tg-output.sh <unit-dir> <output-name>
set -Eeuo pipefail
cd "$1" && terragrunt output -raw "$2" | tr -d '[:space:]'
