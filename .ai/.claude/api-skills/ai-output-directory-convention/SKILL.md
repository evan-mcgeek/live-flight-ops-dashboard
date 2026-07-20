---
name: ai-output-directory-convention
description: All AI-generated content (analysis, docs, specs) goes in .ai/ directory; configure tools to output there, not in source directories
---

## Convention

This project reserves `.ai/` at project root as the single output directory for all AI-assisted content: documentation, analysis results, specifications, configurations, and templates. Generated files do not belong in source directories or tool working directories.

## Why

- Keeps generated and hand-written code clearly separated
- Makes it obvious which files are AI-produced vs. authored
- Simplifies `.gitignore` (one directory to exclude)
- Prevents tools from littering their working directories

## Configuration

When running analysis or generation tools, explicitly set their output path if the tool allows it.

### understand-anything example

When analyzing a subdirectory like `api/`, set `PROJECT_ROOT` to the project root and scope via `.understandignore`. Output will land in `.ai/.understand-anything/` at project root, not inside the analyzed subdirectory:

```bash
PROJECT_ROOT=/path/to/live_flight_ops_dashboard /path/to/understand-anything analyze
# Result: .ai/.understand-anything/ (project root)
```

See also: `understand-anything-project-root-configuration` for `.understandignore` details.

### Other tools

Review tool configuration to point output to `.ai/`. If the tool doesn't support a custom output path, post-process its output to `.ai/` before committing.

## Cleanup

If a tool creates output in the wrong location before you correct its configuration, remove the artifact before proceeding:

```bash
rm -rf api/.understand-anything/
```

This prevents accidentally committing misplaced generated files to the repo.

## Pre-flight checklist

Before running any documentation, analysis, or generation tool:
1. Verify its output path or confirm it will write to `.ai/`
2. Run the tool
3. Check that output is in `.ai/`, not in source directories
4. Clean up any misplaced artifacts
