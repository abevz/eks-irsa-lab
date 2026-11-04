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

The AWS account ID is public by decision: it lives in the committed
`infra/root.hcl`, which also derives the state bucket name from it, and
`allowed_account_ids` in the generated provider refuses any other account.
ARNs, access keys, kubeconfig files and personal values are never committed;
personal values go to the git-ignored `infra/local.hcl`.

`scripts/check-staged-public.py` rejects staged additions that contain an ARN
or an AWS access key (`AKIA…`/`ASIA…`), and any binary diff. The repository is
used as a bare clone with worktrees, so hooks live in `.bare/hooks/` and are
shared by every worktree. Install a wrapper that runs the script from the
worktree being committed:

```sh
printf '#!/bin/sh\nexec "$(git rev-parse --show-toplevel)/scripts/check-staged-public.py"\n' > .bare/hooks/pre-commit
chmod +x .bare/hooks/pre-commit
```

In a normal (non-bare) clone, use `.git/hooks/pre-commit` instead. The check
does not replace a manual review of the diff and of `git log -p`.

## License

MIT — see [LICENSE](LICENSE).
