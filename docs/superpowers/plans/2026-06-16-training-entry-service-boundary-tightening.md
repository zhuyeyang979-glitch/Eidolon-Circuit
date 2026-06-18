# Training Entry Service Boundary Tightening

## Goal

Make `TrainingEntryService` the single owner for training dummy radius/math, ball dummy stats and entry models, training entry intro segments, pending training imports, import-to-loadout conversion, first legal hero selection, starter loadout construction, and training side assignment.

## Priority

P5 service-boundary cleanup. This keeps `scripts/main.gd` focused on training UI state, battle startup, and scene side effects while moving training-entry decisions into a pure service with contract coverage.

## Steps

1. Add a lazy `_training_entry_service()` accessor in `scripts/main.gd`.
2. Route training dummy helpers, training import loadout, first-legal-hero selection, starter fallback, and training side assignment through `_training_entry_service()`.
3. Remove legacy training fallback functions and duplicate helper logic from `main.gd`.
4. Update training and controller boundary probes to require the accessor-based service boundary and reject legacy fallback tokens.

## Verification

- `tools/training_entry_service_contract_probe.gd`
- `tools/main_controller_boundary_probe.gd`
- Training entry, imported unit, dummy, readiness, and training start probes that cover both service contracts and actual battle-entry behavior.
