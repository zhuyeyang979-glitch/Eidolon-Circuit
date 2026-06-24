# Source Code Priority UI And Data Plan

## Goal

Allow a puppet made from one or more construct bodies to carry multiple Source Codes in a deterministic player-authored order. Destroying one construct body removes only the Source Codes carried by that body; Source Codes on surviving bodies continue to operate in their original relative order.

The first implementation is intentionally data-only. It establishes the save contract and ordering service before adding editor controls or changing puppet AI selection.

## Current Source Code Inventory

Current catalog Source Codes already provide:

- `kind: "code"` identity;
- `group_count` controlled-body limit;
- `ai` movement family;
- `module_sequence_limit` and `condition_slots`;
- `sequence` action-state order;
- `source_rules` condition table;
- targeting fields such as `source_target_policy`;
- attack fields such as `source_attack_preference`;
- movement fields such as `source_close_response`, `source_keep_range`, and `source_threat_override_range`.

At present, unit stats collapse these fields into one active `source_rules`, `ai`, and `sequence` set. The battle adapter then asks `BattleActorCommandService.source_rule_for_condition()` for one rule. There is no persisted multi-code priority contract in the old path.

## Data Contract

Puppet blueprints may now carry:

```text
source_code_priority: [
  {
    entry_id,
    construct_body_id,
    payload_index,
    source_code_name,
    priority
  }
]
```

- `entry_id` is stable within the puppet blueprint and defaults to `<construct_body_id>:<payload_index>`.
- `construct_body_id` identifies the carrier, not the bodies controlled by the code.
- `payload_index` points to the Source Code software payload on that carrier.
- `source_code_name` is display and recovery metadata, not identity.
- `priority` is zero-based after normalization.

`scripts/services/source_code_priority_service.gd` owns pure normalization, one-step movement, surviving-carrier filtering, and blueprint reads.

Explicit priorities sort first in ascending order. Equal priorities preserve source-array order. Entries without priorities follow ranked entries in source-array order. Every output is renumbered contiguously.

## Priority Semantics

Priority is evaluation order, not an unconditional override.

1. Remove entries whose carrier construct body is destroyed.
2. Walk the remaining Source Codes from priority zero upward.
3. A Source Code may claim eligible puppet construct bodies up to its `group_count`.
4. A later Source Code receives bodies not claimed by an earlier applicable code.
5. If an earlier code cannot handle the current condition or has no surviving carrier, evaluation continues.
6. Source Codes on one destroyed body disappear; entries on surviving bodies retain relative order.

The first runtime integration should expose the selected Source Code ID and rejection reason in diagnostics. Existing single-code puppets behave exactly as before.

## Minimal Editor UI

Place a `源代码优先级 / SOURCE PRIORITY` section in the puppet software detail panel.

Each row shows:

- priority number;
- Source Code name;
- carrier construct-body label;
- controlled-body limit;
- current status: available, carrier missing, or invalid payload.

Controls:

- Up and Down icon buttons move one row at a time.
- Reset restores stable payload order.
- Rows are keyboard focusable and announce the new priority after movement.
- Drag reordering is deferred until button ordering and controller navigation are proven.

The editor writes only `source_code_priority`. It does not rewrite `torso_payloads`, topology indices, Source Code behavior fields, or `module_bindings`.

## Player Explanation

Chinese:

> 优先级决定多个源代码的判定顺序。高优先级源代码先接管其可控制的傀儡构件体；若其载体被摧毁、条件不适用或数量已满，则继续判定下一项。其他存活构件体携带的源代码不会随之消失。

English:

> Priority controls the order in which Source Codes are evaluated. Higher entries claim eligible puppet construct bodies first. If a carrier is destroyed, a rule does not apply, or its capacity is full, evaluation continues to the next entry. Source Codes carried by surviving bodies remain available.

## Save Compatibility

- The new array is optional. Missing data means stable payload order.
- Saved-unit serialization already deep-copies blueprint dictionaries and puppet-group blueprint arrays.
- Array order and explicit priorities survive JSON round trips.
- Legacy saves do not need migration before loading.
- Runtime destruction never rewrites the saved blueprint.
- Unknown extra fields remain ignored by old battle code until runtime integration is enabled.

## Runtime Integration Boundary

Future battle integration should:

1. Materialize stable construct-body IDs at puppet spawn.
2. Resolve Source Code payloads from each priority entry.
3. Filter entries through `SourceCodePriorityService.surviving()`.
4. Produce one deterministic body-to-code assignment table.
5. Derive current `ai`, `source_rules`, and sequence fields per assigned body.
6. Rebuild only the affected assignment table after construct-body destruction.

Do not merge this logic into `BattleActorCommandService`; that service should continue receiving an already selected rule dictionary.

## Verification

`tools/source_code_priority_service_probe.gd` covers:

- explicit and implicit priority normalization;
- stable one-step movement;
- carrier destruction filtering;
- contiguous priority renumbering;
- malformed entry rejection and stable ID derivation;
- single-blueprint JSON round trip;
- puppet-group save payload JSON round trip.

## Acceptance

- Multiple Source Codes have a deterministic stored order.
- Saved puppet and puppet-group blueprints preserve that order.
- Destroyed carriers remove only their own Source Codes.
- Surviving Source Codes preserve relative order.
- Existing single-code runtime behavior remains unchanged until the later integration task.
