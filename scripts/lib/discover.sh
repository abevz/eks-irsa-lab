# shellcheck shell=bash
# scripts/lib/discover.sh — shared by capture-cleanup-inventory.sh and audit-cleanup.sh.
# Sourced, not executed. Prints one JSON object with every lab resource that costs money
# or blocks VPC deletion. Any AWS API error returns non-zero (fail closed).

PROJECT_TAG="${PROJECT_TAG:-eks-lab}"

require_account() { # <expected-account-id>
  local actual
  actual=$(aws sts get-caller-identity --output json | jq -r '.Account')
  if [[ "$actual" != "$1" ]]; then
    printf 'guard: caller account %s, expected %s\n' "$actual" "$1" >&2
    return 1
  fi
}

discover() { # <region> <cluster-name>
  local region=$1 cluster=$2
  local vpcs nats eips enis lbs volumes clusters out err

  vpcs=$(aws ec2 describe-vpcs --region "$region" --output json \
    --filters "Name=tag:Project,Values=$PROJECT_TAG" | jq -c '[.Vpcs[].VpcId]')

  nats=$(aws ec2 describe-nat-gateways --region "$region" --output json \
    --filter "Name=tag:Project,Values=$PROJECT_TAG" \
    | jq -c '[.NatGateways[] | select(.State != "deleted") | .NatGatewayId]')

  eips=$(aws ec2 describe-addresses --region "$region" --output json \
    --filters "Name=tag:Project,Values=$PROJECT_TAG" | jq -c '[.Addresses[].AllocationId]')

  volumes=$(aws ec2 describe-volumes --region "$region" --output json \
    --filters "Name=tag:kubernetes.io/cluster/$cluster,Values=owned" | jq -c '[.Volumes[].VolumeId]')

  # ALBs are created by the controller outside OpenTofu: match them by the lab VPC.
  lbs=$(aws elbv2 describe-load-balancers --region "$region" --output json \
    | jq -c --argjson vpcs "$vpcs" '[.LoadBalancers[] | select(.VpcId as $v | $vpcs | index($v)) | .LoadBalancerArn]')

  enis='[]'
  if [[ "$vpcs" != "[]" ]]; then
    enis=$(aws ec2 describe-network-interfaces --region "$region" --output json \
      --filters "Name=vpc-id,Values=$(jq -r 'join(",")' <<<"$vpcs")" \
      | jq -c '[.NetworkInterfaces[].NetworkInterfaceId]')
  fi

  # A missing cluster is a valid answer; any other error is not.
  err=$(mktemp)
  if out=$(aws eks describe-cluster --region "$region" --name "$cluster" --output json 2>"$err"); then
    clusters=$(jq -c '[.cluster.arn]' <<<"$out")
  elif grep -q 'ResourceNotFoundException' "$err"; then
    clusters='[]'
  else
    cat "$err" >&2; rm -f "$err"; return 1
  fi
  rm -f "$err"

  jq -n --argjson eks_clusters "$clusters" --argjson vpcs "$vpcs" --argjson nat_gateways "$nats" \
        --argjson eips "$eips" --argjson load_balancers "$lbs" --argjson enis "$enis" \
        --argjson volumes "$volumes" \
    '{eks_clusters:$eks_clusters, vpcs:$vpcs, nat_gateways:$nat_gateways, eips:$eips,
      load_balancers:$load_balancers, enis:$enis, volumes:$volumes}'
}
