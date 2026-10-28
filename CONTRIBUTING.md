# Contributing

```bash
moon update
moon fmt
moon check --deny-warn
moon test --deny-warn
./scripts/e2e.sh
```

Add tests for every scoring rule and manifest validation rule. Reports and generated examples must remain deterministic except for measured durations.

Keep process execution in `runtime/`; grading policy belongs in the MoonBit library.
