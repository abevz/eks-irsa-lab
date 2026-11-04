# scripts/tg-output.sh <unit-dir> <output-name>
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$1" && terragrunt output -raw "$2" | tr -d '[:space:]'
