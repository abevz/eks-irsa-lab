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

Account IDs, ARNs, hosted zone IDs, state bucket names, `backend.hcl` and
kubeconfig files are never committed. They come from environment variables or
git-ignored files. `scripts/check-staged-public.py` rejects staged additions
with a 12-digit account ID or an ARN, and any binary diff; enable it on a fresh
clone with `ln -s ../../scripts/check-staged-public.py .git/hooks/pre-commit`.
It does not replace a manual review of the diff and of `git log -p`.

## License

MIT — see [LICENSE](LICENSE).
