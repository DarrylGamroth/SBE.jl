SBE.jl - Work Plan for SBEDomainMapper Gaps

Phase 1: Scope + Design (Pending)
- Audit schema load/generate code paths that derive module names from `package`.
- Decide sanitization rules and whether to expose an explicit module-name override.
- Define minimal include-resolution support (xi:include or pluggable hook).
- Specify a compact, stable introspection surface (byte order, messages, fields).

Phase 2: Module Naming Fix (Pending)
- Implement package sanitization to valid Julia identifiers.
- Add optional override for module name in `@load_schema`/`generate`.
- Add targeted tests for invalid packages (spaces, hyphens).

Phase 3: Introspection Helpers (Pending)
- Expose helpers for schema metadata needed by tools (e.g., byte order, message list).
- Keep API read-only and stable across releases.
- Add tests exercising helpers on representative schemas.

Phase 4: Documentation + Release Readiness (Pending)
- Document new options and helper APIs in `README.md`/`docs`.
- Add release notes and compatibility notes if behavior changes.

Future Ideas (Parked)
- Schema composition / include resolution (e.g., xi:include) if multi-file schemas become common; currently most usage is single-file.
