# Saved Unit Library Service Boundary Tightening

## Goal

Make `SavedUnitLibraryService` the single owner for saved-unit cache signatures, cache refresh decisions, latest-name lookup, save path resolution, save payload construction, readback status, payload entry restoration, rejected-entry construction, and record-to-entry conversion.

## Priority

P5 service-boundary cleanup. This narrows `scripts/main.gd` toward file orchestration and UI feedback while keeping saved-unit library policy in a pure service with contract coverage.

## Steps

1. Add a lazy `_saved_unit_library_service()` accessor in `scripts/main.gd`.
2. Route saved-unit cache, save path, payload, readback, entry restore, rejected-entry, and latest-name wrappers through `_saved_unit_library_service()`.
3. Remove legacy saved-unit fallback functions and duplicate inline saved-unit library algorithms from `main.gd`.
4. Update saved-unit and controller boundary probes to require the accessor-based service boundary and reject legacy fallback tokens.

## Verification

- `tools/saved_unit_library_service_contract_probe.gd`
- `tools/main_controller_boundary_probe.gd`
- Saved-unit save/load/delete/cache probes that cover disk records, strict rejection, overwrite/save-as, postwrite validation, and no-silent-delete behavior.
