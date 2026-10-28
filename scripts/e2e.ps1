$ErrorActionPreference = "Stop"
$env:Path = "$HOME\.moon\bin;$env:Path"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
New-Item -ItemType Directory -Path "examples/reports" -Force | Out-Null

moon test --deny-warn
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

moon run cmd/main -- grade `
  --assignment examples/assignment.json `
  --student examples/passing-student `
  --markdown examples/passing-report.md `
  --json examples/passing-report.json `
  --html examples/passing-report.html `
  --fail-on-fail
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

moon run cmd/main -- grade `
  --assignment examples/assignment.json `
  --student examples/failing-student `
  --markdown examples/failing-report.md `
  --json examples/failing-report.json `
  --html examples/failing-report.html `
  --fail-on-fail
if ($LASTEXITCODE -ne 1) { exit 1 }

moon run cmd/main -- batch `
  --assignment examples/assignment.json `
  --students examples `
  --reports examples/reports `
  --fail-on-fail
if ($LASTEXITCODE -ne 1) { exit 1 }

$summary = Get-Content -Raw "examples/reports/summary.md"
if (-not $summary.Contains("failing-student | 65/100")) { exit 1 }
if (-not $summary.Contains("passing-student | 100/100")) { exit 1 }
if (-not $summary.Contains("compile-error-student | 0/100")) { exit 1 }

exit 0
