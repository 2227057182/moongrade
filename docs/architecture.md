# MoonGrade architecture

MoonGrade separates grading policy from process execution and report rendering.

```text
assignment.json
      │
      ▼
validate and model ──► copy submission to temporary directory
                              │
                              ▼
                   run compile/test/custom checks
                              │
                              ▼
               normalize output and calculate score
                              │
             ┌────────────────┼────────────────┐
             ▼                ▼                ▼
          Markdown           JSON             HTML
```

## Core library

`assignment.mbt` parses a JSON manifest into typed checks. It rejects duplicate IDs, invalid totals, unsupported kinds, missing commands, and excessive timeouts.

`scoring.mbt` accepts a process result and returns a check result. Compile and custom checks are pass/fail. Test checks parse `Total tests`, `passed`, and `failed` counters to award proportional points.

`render.mbt` produces deterministic report structures. Duration values come from execution and are intentionally not used for grading decisions.

## Runtime adapter

`runtime` is a thin JavaScript-target package. It:

1. copies a trusted local project to a temporary directory;
2. excludes `_build`, `.git`, `.mooncakes`, and `node_modules`;
3. starts a command directly without shell interpolation;
4. captures stdout, stderr, exit code, timeout status, and duration;
5. removes the temporary directory after grading.

All policy decisions remain in the MoonBit library.

## Failure model

- Invalid manifest: the CLI exits with status 2 before grading.
- Submission does not pass: the CLI exits with status 1 only when `--fail-on-fail` is provided.
- Passing submission: exit status 0.

This keeps local exploration friendly while supporting CI gates.
