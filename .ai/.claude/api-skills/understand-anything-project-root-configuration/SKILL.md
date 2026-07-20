---
name: understand-anything-project-root-configuration
description: Configure understand-anything to analyze a single subdirectory while keeping output at the project root by setting PROJECT_ROOT to the root and filtering scope with .understandignore.
---

## Problem

The `understand-anything` skill hardcodes its output location and scan scope to the same `PROJECT_ROOT` parameter. Setting `PROJECT_ROOT=api/` results in:
- Analysis scoped to `api/`  
- Output created in `api/.understand-anything/`

The tool does not have a separate flag to decouple "where to scan" from "where to write output" — both are driven by `PROJECT_ROOT`.

This is problematic when you want:
- Analysis scoped to one subdirectory only (e.g., backend code)
- Output at the project root (not nested inside the analyzed subdirectory)

## Solution

1. **Set PROJECT_ROOT to the actual project root**, not the subdirectory you want to analyze.

2. **Use `.understand-anything/.understandignore`** (a `.gitignore`-style filter file) to exclude directories from the scan.

   The skill has a `generate-ignore` utility that creates a template. Edit `.understand-anything/.understandignore` to list directories to exclude. Example for backend-only analysis:
   ```
   .ai/
   app/
   ```

3. **Dispatch the scan** with `PROJECT_ROOT` pointing to the project root. The skill respects `.understandignore` and creates `.understand-anything/` at the root level.

## Why this approach works

- **Output stays at root**: `.understand-anything/` is discoverable and stable across multiple scans  
- **Updates append cleanly**: future runs from the same root update the same knowledge graph  
- **Scope is auditable**: `.understandignore` patterns are explicit and version-controllable

## When to apply

- Multi-directory projects where you want to analyze only some subdirectories initially (backend before frontend, POC infrastructure before full stack, etc.)
- The analysis tool couples `PROJECT_ROOT` with output location and you need output at the project root
