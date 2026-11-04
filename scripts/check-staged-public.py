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
# Account ID is public by decision (infra/root.hcl, 03.11.2026); ARNs and access keys are not.
patterns = [b"arn" + b":aws:", rb"(?<![A-Z0-9])(AKIA|ASIA)[A-Z0-9]{16}(?![A-Z0-9])"]
if any(re.search(pattern, added) for pattern in patterns):
    sys.exit("ARN or AWS access key in staged additions: redact before commit")
