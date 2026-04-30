# NenaBot Documentation Setup

This document explains the Doxygen documentation setup for the NenaBot project.

## Overview

The NenaBot project uses **Doxygen** to generate comprehensive source code documentation for both:
- **Backend**: Python code (FastAPI application, adapters, services, domain models)
- **Frontend**: TypeScript/React code (components, hooks, services, type definitions)

A single Doxygen configuration generates a unified documentation site with cross-referenced content from both codebases.

## Generating Documentation

To generate or regenerate the documentation:

```bash
./scripts/generate-docs.sh
```

Generated HTML documentation is output to `docs/generated/html/`. Open `docs/generated/html/index.html` in a web browser to view.

To automatically open in your default browser:

```bash
./scripts/generate-docs.sh --open
```

## Configuration

The Doxygen configuration is defined in the `Doxyfile` at the project root. Key settings:

| Setting | Value | Purpose |
|---------|-------|---------|
| `INPUT` | `backend/app`, `backend/lib/dobot`, `frontend/src` | Paths to source code directories |
| `OUTPUT_DIRECTORY` | `docs/generated` | Output location for generated docs |
| `EXTRACT_ALL` | `YES` | Document all code, not just public APIs |
| `GENERATE_HTML` | `YES` | Generate HTML output (primary format) |
| `SOURCE_BROWSER` | `YES` | Include source code browser |
| `MARKDOWN_SUPPORT` | `YES` | Support Markdown in comments |

## Documentation Scope

The documentation includes:

### Backend (Python)
- FastAPI application initialization and middleware setup
- Domain models (Job, Waypoint, Measurement, etc.)
- API routes and endpoint handlers
- Service layer orchestration logic
- Hardware adapters (robot, camera, database, IonVision)
- Utility functions and helper code

### Frontend (TypeScript/React)
- React components (tabs, layouts, shared components)
- Custom hooks (useProgressData, useRoutePlan, useJobEvents, etc.)
- API client and service functions
- Type definitions for domain entities and API contracts
- State management utilities

## Docstring Standards

To keep documentation generation up-to-date:

### Python (Backend)
- Use triple-quoted docstrings (`"""..."""`) for module, class, and function documentation
- Follow Google-style docstring format for consistency
- Module-level docstrings describe package purpose and organization

Example:
```python
"""Module for FastAPI application setup and custom OpenAPI schema handling."""

def subscribe(self, job_id: str) -> queue.Queue:
    """Subscribe to SSE events for a job.
    
    Args:
        job_id: The unique job identifier.
        
    Returns:
        A Queue that receives event dicts for the subscription.
    """
```

### TypeScript/Frontend
- Use JSDoc format (`/** ... */`) for functions, types, and constants
- Add brief module-level JSDoc at the top of service files and type definition files
- Type signatures provide most documentation; JSDoc complements with context

Example:
```typescript
/**
 * API call wrappers for backend integration.
 * 
 * Provides functions for job management, calibration, and result retrieval.
 */

/**
 * Starts a new calibration process.
 * 
 * @param profile - The calibration profile settings.
 * @returns Promise containing calibration results.
 */
export async function startCalibration(profile: CalibrationProfile): Promise<void> {
  // ...
}
```

## Regenerating After Code Changes

The generated documentation reflects committed code. After significant changes (new modules, major API changes), regenerate:

```bash
./scripts/generate-docs.sh
```

**Note:** Generated documentation files in `docs/generated/` are not committed to version control. Each developer regenerates locally as needed.

## Advanced Customization

To customize Doxygen behavior:

1. Edit `Doxyfile` in the project root
2. Regenerate documentation
3. For common options, see [Doxygen Configuration Manual](https://www.doxygen.nl/manual/config.html)

Some useful options to explore:
- `HAVE_DOT = YES` — Enable graph generation (requires Graphviz)
- `SEARCH_ENGINE = YES` — Add search functionality to HTML output
- `GENERATE_LATEX = YES` — Generate LaTeX/PDF documentation
- `EXTRACT_PRIVATE = YES` — Include private members in documentation

## Troubleshooting

### "doxygen: command not found"
- Doxygen is not installed. See installation instructions in the main [README.md](README.md#doxygen-installation).

### TypeScript/JSDoc Comments Not Appearing
- Ensure JSDoc blocks use `/** ... */` format (not `// ...` comments)
- Module-level docstrings must be the first code in the file
- Run regeneration: `./scripts/generate-docs.sh`

### Generated HTML Not Opening in Browser
- The `--open` flag requires a default browser to be configured in your OS
- Manually open `docs/generated/html/index.html` in your browser
- On headless systems, inspect the HTML output directly

## Documentation Navigation

After generation, the documentation site includes:
- **Index**: Overview of all modules and namespaces
- **Modules**: Organized by backend/frontend boundaries
- **Classes/Interfaces**: Type definitions and class hierarchies
- **Files**: Source code file listings with line-by-line documentation
- **Source**: Browsable source code with comments and cross-references
- **Search** (if enabled): Full-text search across documentation

## Contributing Documentation

- When adding new modules or significant functions, include docstrings/JSDoc blocks
- Keep documentation concise; focus on **why** and **how**, not obvious implementation details
- Link between related functionality using cross-references in comments
- Update this file if Doxygen configuration changes
