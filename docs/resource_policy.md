# Resource Policy

This policy keeps the current art set useful without turning routine code commits into accidental binary drops.

## Current Decision

- Keep the existing tracked `assets/concepts/` curated baselines in Git. They are referenced by docs, probes, and `scripts/part_art.gd`, and the current set has no single oversized file that requires immediate migration.
- Keep the existing tracked `assets/generated/` runtime atlases, textures, and their Godot `.import` files in Git. These assets are loaded by runtime code and visual probes, so missing files would break local verification.
- Do not introduce Git LFS in this branch. There is no current `.gitattributes` LFS setup and `git-lfs` is not available in this workspace; a partial migration would add process risk without fixing an active blocker.
- Keep local drafts, prompt batches, raw layered files, videos, archives, and unstable generated experiments out of normal commits. Use `assets/concepts/_local/`, `assets/concepts/_incoming/`, `assets/concepts/_scratch/`, `assets/generated/_local/`, or `assets/generated/_scratch/`.

## Adding New Tracked Art

Track a new art asset only when all of these are true:

- It is referenced by source code, a probe, a checked-in manifest, or a design document.
- It is a curated baseline, not a batch of near-duplicate attempts.
- It has a stable versioned filename such as `*_v2.png`.
- It is visually reviewed when it affects UI, gameplay readability, or screenshots.
- For `assets/concepts/`, update `assets/concepts/ART_ASSET_MANIFEST.md` or the closest JSON manifest when the asset is part of a reusable set.

## Size Triggers

- Revisit Git LFS or external storage before adding any single binary asset above 25 MB.
- Revisit the overall policy before growing `assets/concepts/` or `assets/generated/` by more than 200 MB in one change.
- Prefer regeneratable local scratch output over committed binaries when a file is not loaded by code or used as an accepted visual baseline.

## Godot Import Files

- Keep tracked `.import` files for tracked runtime assets in `assets/generated/` when they are already part of the project contract.
- Do not commit transient `.import` files produced for local-only concept scratch folders.
