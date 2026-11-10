#!/usr/bin/env python3
import re
import subprocess
import sys

numstat = subprocess.run(
    ["git", "diff", "--cached", "--numstat", "--"], stdout=subprocess.PIPE, check=True
).stdout
if any(line.startswith(b"-\t-\t") for line in numstat.splitlines()):
    sys.exit("Binary staged diff: inspect and unstage before commit")
result = subprocess.run(
    ["git", "diff", "--cached", "--no-ext-diff", "--no-color", "--unified=0", "--"],
    stdout=subprocess.PIPE,
    check=True,
)
diff = result.stdout
added = b"\n".join(
    line[1:]
    for line in diff.splitlines()
    if line.startswith(b"+") and not line.startswith(b"+++")
)
# Account ID is public by decision (infra/root.hcl, 03.11.2026); real ARNs and access keys are not.
# Block an ARN that carries a 12-digit account other than the AWS documentation placeholders
# used in test fixtures. Templates such as arn:aws:eks:$region:$account:... pass.
PLACEHOLDER_ACCOUNTS = {b"111122223333", b"444455556666", b"123456789012"}
arn_accounts = re.findall(
    rb"arn" + rb":aws[a-z-]*:[a-z0-9-]+:[a-z0-9-]*:(\d{12}):", added
)
real_arn = any(account not in PLACEHOLDER_ACCOUNTS for account in arn_accounts)
access_key = re.search(rb"(?<![A-Z0-9])(AKIA|ASIA)[A-Z0-9]{16}(?![A-Z0-9])", added)
if real_arn or access_key:
    sys.exit("ARN or AWS access key in staged additions: redact before commit")
