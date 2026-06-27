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
| Part size is less than or equal to slot capacity | Missing exact contract | Current topology only rejects abrupt size jumps, while internal payloads use aggregate capacity/volume rules. This is not the same as a per-socket `part_size <= socket_size` rule. | Add socket-size metadata and validation in `scripts/services/unit_editor_legality_service.gd`; integrate through `scripts/main.gd::_topology_rule_note()`; add `tools/unit_editor_socket_size_rejection_probe.gd` first. |
| Every construct body uses hardware from one manufacturer | Missing hard gate | `_manufacturer_counts_for_blueprint()` and `_manufacturer_rule_note()` currently produce global synergy and a `MFR MIX WARN`, not a per-connected-body rejection. | Add connected-component maker validation in `scripts/services/unit_editor_legality_service.gd`; call it from `scripts/main.gd::_training_blueprint_illegal_note()`; add `tools/construct_body_manufacturer_rejection_probe.gd` first. Software makers must be excluded. |
| Hero requires exactly one Soul | Missing explicit hard gate | Hero UI defaults and filters expose Soul, and stats expose `has_soul`, but `_training_blueprint_illegal_note()` does not reject a missing or wrong identity payload. | Add role identity validation in `scripts/services/unit_editor_legality_service.gd`; integrate in `scripts/main.gd`; add `tools/role_identity_software_rejection_probe.gd` first. |
| Puppet requires at least one Source Code | Missing explicit hard gate | Puppet catalogs and runtime source rules provide Code behavior, but legality currently relies on authored/default data. | Same role identity owner and probe as above. The validator must support multiple ordered Source Codes later. |
| Barrier requires Ether | Partial | Ether capacity and material limits are hard-gated by `_ether_group_rule_note()`, but absence or wrong identity kind is not rejected explicitly. | Same role identity owner and probe as above. |

## Implementation Order

1. Create `scripts/services/unit_editor_legality_service.gd` as a pure dictionary-based rule service.
2. Write `tools/role_identity_software_rejection_probe.gd`.
3. Write `tools/unit_editor_socket_size_rejection_probe.gd` after socket capacity metadata is defined.
4. Write `tools/construct_body_manufacturer_rejection_probe.gd`.
5. Integrate one structured report into `_training_blueprint_illegal_note()`, preserving existing save, training, and team gates.
6. Localize each error through stable reason codes in Chinese and English; do not make UI text the source of truth.
7. Keep legacy topology keys and saved-unit schema unchanged until a separate migration. Guarded by `tools/unit_editor_schema_invariance_probe.gd`, which verifies `momentum_chain_v3`, `single_unit` / `puppet_group`, `custom_topology` keys, and absence of persisted transient legality reports.

## Acceptance For The Follow-Up

- The validator returns stable reason codes plus Chinese and English messages.
- Editor preview, save, training import, saved-unit load, team validation, and battle entry use the same report.
- No invalid build is silently repaired or admitted to battle.
- Each new hard rule has a failing probe before implementation.
- `tools/unit_editor_schema_invariance_probe.gd` proves the legality work keeps legacy topology keys and saved-unit schema unchanged until a dedicated migration plan exists.
