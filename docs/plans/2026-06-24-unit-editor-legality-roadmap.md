# Unit Editor Legality Roadmap

## Goal

Map every documented Star Soul Loop assembly rule to an existing hard gate or to a named implementation owner. The current save and training paths must continue to reject builds that fail rules already implemented.

## Current Gate Chain

The reusable entry point is `_training_blueprint_illegal_note()` in `scripts/main.gd`.

- Editor training import calls `_prepare_editor_canvas_training_import()` and blocks before battle.
- Unit-library save calls `_unit_library_save_audit()` before writing and `_saved_unit_entry_illegal_note()` after readback.
- Team and sortie checks consume the same per-unit legality result instead of silently repairing invalid units.
- Canonical storage rejection remains owned by `scripts/services/unit_blueprint_validator.gd`.
- Balance and efficiency hard limits remain owned by `scripts/services/unit_build_rule_service.gd`.

## Rule Coverage

| Documented rule | Status | Current owner and evidence | Next owner |
| --- | --- | --- | --- |
| A unit contains at least one hardware part | Implemented | `scripts/main.gd::_topology_rule_note()` rejects empty topology and non-barrier bodies without a core. `tools/unit_library_legality_gate_probe.gd` proves invalid canonical builds cannot be saved. | Keep in `scripts/main.gd` until topology legality is extracted. |
| One compatible part per matching slot/socket | Partially implemented | Socket type, endpoint occupancy, interface count, duplicate occupancy, and explicit socket pairing are checked by `_topology_rule_note()` / `_topology_endpoint_conflicts()`. Covered by `tools/editor_endpoint_socket_probe.gd` and `tools/drag_connected_no_resnap_probe.gd`. Internal payload capacity is covered by `slot_payload_note` and `tools/torso_slot_capacity_plus_one_probe.gd`. | Exact slot-kind ownership should move to `scripts/services/unit_editor_legality_service.gd`; adapter remains `scripts/main.gd`. |
| Part size is less than or equal to slot capacity | Implemented for explicit records and custom topology | `scripts/services/unit_editor_legality_service.gd::audit_socket_sizes()` rejects `part_size > socket_capacity` with stable code `socket_part_too_large`, localized messages, and normalized ranks. `scripts/main.gd::_unit_editor_legality_topology_socket_size_records()` materializes `root_joint` live topology edges into socket-size records before `_unit_editor_legality_report()` merges the shared service report. Covered by `tools/unit_editor_socket_size_rejection_probe.gd` and `tools/unit_editor_topology_socket_size_gate_probe.gd`. | Add more saved-unit, team-validation, and battle-entry fixtures before claiming exhaustive entrypoint coverage. |
| Every construct body uses hardware from one manufacturer | Implemented for explicit records and custom topology | `scripts/services/unit_editor_legality_service.gd::audit_construct_body_manufacturers()` rejects mixed hardware makers per construct body, excludes software makers, and reports stable code `construct_body_mixed_manufacturer`. `scripts/main.gd::_unit_editor_legality_topology_manufacturer_records()` materializes connected `custom_topology` components before the shared report is merged. Covered by `tools/construct_body_manufacturer_rejection_probe.gd` and `tools/unit_editor_topology_manufacturer_gate_probe.gd`. | Add more saved-unit, team-validation, and battle-entry fixtures before claiming exhaustive entrypoint coverage. |
| Hero requires exactly one Soul | Implemented | `scripts/services/unit_editor_legality_service.gd::audit_role_identity()` reports `hero_soul_count`; `scripts/main.gd::_training_blueprint_illegal_note()` consumes the merged report before save/training admission. Covered by `tools/role_identity_software_rejection_probe.gd` and `tools/unit_editor_legality_main_gate_probe.gd`. | Add more entrypoint-specific probes for saved-unit load, team validation, and battle entry if this rule changes. |
| Puppet requires at least one Source Code | Implemented in the shared service and main-gate paths | `scripts/services/unit_editor_legality_service.gd::audit_role_identity()` reports `puppet_source_code_missing`; puppet groups recurse through `_training_blueprint_illegal_note()`, and missing Source Code is blocked before training import, save write, and saved-unit entry admission. Covered by `tools/role_identity_software_rejection_probe.gd` and `tools/unit_editor_puppet_source_code_main_gate_probe.gd`. | Add focused team-validation and battle-entry fixtures before claiming exhaustive entrypoint coverage. |
| Barrier requires Ether | Implemented in the shared service and main-gate paths | `scripts/services/unit_editor_legality_service.gd::audit_role_identity()` reports `barrier_ether_missing`; the same merged report path handles barrier blueprints before training import, save write, and saved-unit entry admission. Covered by `tools/role_identity_software_rejection_probe.gd` and `tools/unit_editor_barrier_ether_main_gate_probe.gd`. | Add focused team-validation and battle-entry fixtures before claiming exhaustive entrypoint coverage. |

## Implementation Order

1. Done: create `scripts/services/unit_editor_legality_service.gd` as a pure dictionary-based rule service.
2. Done: write `tools/role_identity_software_rejection_probe.gd`.
3. Done: write `tools/unit_editor_socket_size_rejection_probe.gd` for explicit socket capacity records.
4. Done: write `tools/construct_body_manufacturer_rejection_probe.gd` for explicit construct-body manufacturer records.
5. Done: integrate one structured report into `_training_blueprint_illegal_note()`, preserving the existing save, training, and team gate chain.
6. Done: localize each implemented error through stable reason codes in Chinese and English; UI text is not the source of truth.
7. Done: materialize connected-body manufacturer records from live editor topology and keep the legal starter fixture on a same-manufacturer construct body.
8. Done: materialize socket-size records from live editor topology and gate oversized connected parts through `socket_part_too_large`.
9. Done: add main-gate probes for puppet Source Code and barrier Ether fixtures.
10. Next: add focused team-validation and battle-entry fixtures for the shared legality report.
11. Continue keeping legacy topology keys and saved-unit schema unchanged until a separate migration. Guarded by `tools/unit_editor_schema_invariance_probe.gd`, which verifies `momentum_chain_v3`, `single_unit` / `puppet_group`, `custom_topology` keys, and absence of persisted transient legality reports.

## Acceptance For The Follow-Up

- The validator returns stable reason codes plus Chinese and English messages.
- Editor preview, save, training import, saved-unit load, team validation, and battle entry use the same report.
- No invalid build is silently repaired or admitted to battle.
- Each new hard rule has a failing probe before implementation.
- `tools/unit_editor_schema_invariance_probe.gd` proves the legality work keeps legacy topology keys and saved-unit schema unchanged until a dedicated migration plan exists.
