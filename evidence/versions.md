# Versions

Session 0 output. Exact versions only: no `~>` ranges, no `latest`.
Checked 2026-11-03 against the local machine, the OpenTofu/Terraform module registries
and the official Helm chart indexes. No AWS API calls were made.

## Local tools

| Tool | Version |
|---|---|
| OpenTofu | 1.13.2 |
| AWS CLI | 2.32.9 |
| kubectl (client) | 1.37.2 |
| Helm | 4.3.0 |
| Docker (client) | 28.3.2 |
| Docker Buildx | 0.38.1 |
| tflint | 0.59.1 |
| Trivy | 0.76.1 |
| Checkov | 3.4.2 |
| GitHub CLI | 2.102.1 |
| jq | 1.8.2 |
| shellcheck | 0.11.0 |

## OpenTofu runtime, provider and modules

| Item | Pin | Why this version |
|---|---|---|
| OpenTofu `required_version` | `= 1.13.2` | installed runtime |
| `hashicorp/aws` provider | `= 5.100.0` | latest 5.x; EKS module 20.37.2 requires `>= 5.95, < 6.0.0` |
| `terraform-aws-modules/vpc/aws` | `= 5.21.0` | latest 5.x (`aws >= 5.79`); VPC 6.x requires `aws >= 6.28`, which conflicts with the EKS module |
| `terraform-aws-modules/eks/aws` | `= 20.37.2` | the HCL in the runbook uses the v20 inputs; v21 renamed them |
| `terraform-aws-modules/iam/aws` (`iam-role-for-service-accounts-eks`) | `= 5.60.0` | the submodule path used here does not exist in v6 |
| `time`, `tls` providers (EKS module dependencies) | from `.terraform.lock.hcl` | recorded after the first `tofu init`; the lock file is committed |

## EKS

| Item | Pin | Note |
|---|---|---|
| Kubernetes version | `1.36` | owner decision 2026-11-03; standard support to 2027-08-02 (AWS calendar checked 2026-10-20). Not the newest minor, so add-on support is more likely. |
| Node AMI | `AL2023_x86_64_STANDARD` | AL2 AMIs end at 1.32 |
| Node instance types | `t3.medium`, `t3a.medium` (spot) | from the runbook; confirm spot availability before plan |

## Helm charts

| Chart | Chart version | App version | Source |
|---|---|---|---|
| aws-load-balancer-controller | `3.6.0` | v3.6.0 | runbook slice 2026-10-20 (SHA256 checked then); 3.6.2 published 2026-10-30, not adopted |
| external-dns | `1.23.0` | 0.23.0 | runbook slice; still the latest stable on 2026-11-03 |
| argo-cd | `10.11.6` | v3.5.6 | latest stable in the official index, published 2026-10-26; security check below |
| external-secrets | `2.14.0` | v2.14.0 | latest stable in the official index, published 2026-10-23; security check below |

Environment variables read by the scripts (must be non-empty):
`AWS_LB_CONTROLLER_CHART_VERSION=3.6.0`, `EXTERNAL_DNS_CHART_VERSION=1.23.0`,
`ARGOCD_CHART_VERSION=10.11.6`, `EXTERNAL_SECRETS_CHART_VERSION=2.14.0`.

## Security check of the chosen charts (2026-11-03)

Upstream security advisories (GitHub, `argoproj/argo-cd` and `external-secrets/external-secrets`):

- Argo CD: the advisories of 2026-10-07 (four critical, two high) are fixed in 3.5.4; the pinned app
  version v3.5.6 includes the fixes. No newer advisory affects 3.5.6.
- External Secrets: the latest advisory (2026-10-29, low) is fixed in 2.14.0, the pinned version.

Image scan, Trivy 0.76.1, `--severity CRITICAL,HIGH`, images taken from `helm template` of the pinned charts:

| Image | CRITICAL | HIGH |
|---|---:|---:|
| quay.io/argoproj/argocd:v3.5.6 | 2 | 122 |
| ghcr.io/dexidp/dex:v2.46.1 | 0 | 22 |
| redis:8.6.4-alpine (ecr-public) | 0 | 8 |
| ghcr.io/external-secrets/external-secrets:v2.14.0 | 0 | 0 |

Both Argo CD criticals are CVE-2025-68121 (Go standard library, `crypto/tls` certificate validation) in the
bundled `git-lfs` and `kustomize` binaries, not in Argo CD's own code. Most HIGH findings are Go standard
library versions in the same bundled binaries (`git-lfs`, `kustomize`, `helm`, `pebble`). v3.5.6 is the newest
stable release, so no newer image removes them. Accepted for this disposable lab: the cluster lives only for a
session, and Argo CD reads one public repository. Re-scan before each cloud session.

## Not verified yet

- Compatibility of the chosen Kubernetes version with each chart and EKS add-on.
- Rendering and installation of the pinned charts with Helm 4.3.0 (server-side apply by default).
- `time` and `tls` provider versions (after the first `init`).
