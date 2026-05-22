# Supply Chain / Provenance Adapter

Purpose: keep the ready-made-first strategy safe.

## Required checks before use/wrap

- source URL and version are recorded;
- license is acceptable or flagged;
- install path works in target environment;
- package is pinned or lockfile exists;
- binary provenance is documented when using prebuilt artifacts;
- smoke test verifies the exact installed artifact;
- rollback/removal path is known.

## Optional higher-level checks

- SBOM;
- dependency scan;
- signed artifact verification;
- SLSA/provenance statement;
- reproducible build note.

## Decision rule

If provenance is weak but the design is valuable, classify as pattern source instead of direct dependency.
