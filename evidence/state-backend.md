# State backend (bootstrap)

Created 2026-11-09 by `infra/bootstrap/state-backend` (Terragrunt unit, local state).

## Bucket

| Item | Value |
|---|---|
| Name | `492613460415-eu-central-1-eks-lab-tfstate` |
| Region | `eu-central-1` |
| Versioning | Enabled |
| Encryption | SSE-S3 (`AES256`) |
| Public access block | all four flags `true` |
| Protection | `lifecycle { prevent_destroy = true }` |
| Tags | from `infra/root.hcl` via provider `default_tags` |

Verified with `aws s3api head-bucket / get-bucket-versioning / get-bucket-encryption / get-public-access-block / get-bucket-tagging` on 2026-11-09.

## Bootstrap state

The bucket cannot hold the state of its own creation, so this unit keeps a local `terraform.tfstate` in `$LAB_HOME/.local/bootstrap-state/` — outside every worktree, so removing a worktree cannot delete it (moved there 2026-11-09; `plan` after the move: No changes). It is not committed (`*.tfstate` in `.gitignore`).

Backup: encrypted with sops + age (key `age12xe6r5ge…`), stored outside git in `$LAB_HOME/.local/backup/state-backend-2026-11-09.tfstate.sops`.
Round-trip checked: 
```bash 
decrypt | cmp against the original — OK.
```

## Teardown (after the project is closed)

`prevent_destroy` blocks `destroy` on purpose. To remove the bucket:
1. Make sure no unit state remains in it (all units destroyed).
2. Remove `prevent_destroy` in `infra/modules/state-backend/main.tf`.
3. Empty the bucket including all object versions (versioning is on).
4. `task unit-destroy` for `infra/bootstrap/state-backend`, or `tofu destroy` in that unit.
