#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.moon/bin:$PATH"
mkdir -p examples/reports

moon test --deny-warn

moon run cmd/main -- grade \
  --assignment examples/assignment.json \
  --student examples/passing-student \
  --markdown examples/passing-report.md \
  --json examples/passing-report.json \
  --html examples/passing-report.html \
  --fail-on-fail

set +e
moon run cmd/main -- grade \
  --assignment examples/assignment.json \
  --student examples/failing-student \
  --markdown examples/failing-report.md \
  --json examples/failing-report.json \
  --html examples/failing-report.html \
  --fail-on-fail
failing_code=$?

moon run cmd/main -- batch \
  --assignment examples/assignment.json \
  --students examples \
  --reports examples/reports \
  --fail-on-fail
batch_code=$?
set -e

test "$failing_code" -eq 1
test "$batch_code" -eq 1
grep -q 'failing-student | 65/100' examples/reports/summary.md
grep -q 'passing-student | 100/100' examples/reports/summary.md
grep -q 'compile-error-student | 0/100' examples/reports/summary.md
