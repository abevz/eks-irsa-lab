# eks-irsa-lab

A disposable personal lab: moving a containerized workload to Amazon EKS with
modular OpenTofu, IRSA and EKS Pod Identity, GitOps delivery and a reviewed
create → verify → destroy cycle.

> **Not production.** This is a learning lab in a personal AWS account. Every
> cloud session ends with a full teardown; nothing here runs permanently.

## What is inside

_To be filled as sessions are completed._

## Layout

_To be filled once the directory structure is set._

## How to run

_To be filled: prerequisites, required environment variables, plan → review → apply, teardown._

## Cost

_To be filled: estimate per session and the actual bill for the lab window._

## Teardown

_To be filled: destroy order, cleanup targets and the post-destroy audit._

## Evidence

`evidence/` holds redacted command output that proves each step. Raw output
with account-specific values stays in `evidence/raw/`, which is not committed.

## Repository hygiene

Account IDs, ARNs, hosted zone IDs, state bucket names and kubeconfig files
are never committed. They come from environment variables or git-ignored
files. A pre-commit hook (`scripts/check-no-secrets.sh`, enabled with
`git config core.hooksPath .githooks`) blocks staged changes that contain
them.

## License

MIT — see [LICENSE](LICENSE).
