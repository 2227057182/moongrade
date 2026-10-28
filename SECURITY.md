# Security

MoonGrade runs local commands from assignment manifests. Only use manifests and submissions you trust.

Commands are passed directly without shell interpolation and run with time and output limits inside a temporary copy of the submission. This is not a hostile-code sandbox.

For public multi-tenant deployments, add container isolation, network controls, read-only mounts, and operating-system resource limits.
