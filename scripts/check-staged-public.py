#!/usr/bin/env python3
import re
import subprocess
import sys

numstat = subprocess.run(["git", "diff", "--cached", "--numstat", "--"], stdout=subprocess.PIPE, check=True).stdout
if any(line.startswith(b"-\t-\t") for line in numstat.splitlines()):
    sys.exit("Binary staged diff: inspect and unstage before commit")
result = subprocess.run(["git", "diff", "--cached", "--no-ext-diff", "--no-color", "--unified=0", "--"], stdout=subprocess.PIPE, check=True)
diff = result.stdout
added = b"\n".join(line[1:] for line in diff.splitlines() if line.startswith(b"+") and not line.startswith(b"+++"))
patterns = [rb"(?<![0-9])[0-9]{12}(?![0-9])", b"arn" + b":aws:"]
if any(re.search(pattern, added, re.IGNORECASE) for pattern in patterns):
    sys.exit("Account ID or ARN in staged additions: redact before commit")
