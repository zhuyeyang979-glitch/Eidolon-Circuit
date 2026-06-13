# Unit Editor Auto Connection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a guided automatic connection step to Unit Edit so existing placed parts can be linked by the system, manually adjusted by the player, and evaluated before the recommended guide advances to entry pose.

**Architecture:** Add one pure service, `UnitEditorAutoConnectionService`, that ranks connection candidates and summarizes connection-phase readiness from supplied topology facts. Keep all Godot scene side effects in `scripts/main.gd`: fact gathering, edge application, node alignment, undo, UI buttons, hint text, dirty flags, and guide advancement. Preserve existing topology legality, save validation, manual editing, side-mounted weapon controls, and runtime combat behavior.

**Tech Stack:** Godot 4.6 GDScript, existing `scripts/main.gd` Unit Edit UI, free-canvas topology helpers, headless Godot probe scripts under `tools/`.

---

## File Structure

- Create `scripts/services/unit_editor_auto_connection_service.gd`
  - Pure `RefCounted` service.
  - Accepts facts from `main.gd`, never reads scene state directly.
  - Returns deterministic connection intents and evaluation dictionaries.

- Modify `scripts/main.gd`
  - Preload and instantiate the service.
  - Add transient `editor_connection_evaluation`.
  - Build service facts from current topology using existing socket and topology helpers.
  - Add `auto_connect`, `evaluate_connection`, and `restore_suggested_connection` actions.
  - Mark connection evaluation stale after manual topology edits.
  - Let recommended guide move from connection to entry pose only after a fresh `passed` evaluation.

- Create `tools/unit_editor_auto_connection_service_probe.gd`
  - Tests deterministic pure-service planning and state classification.

- Create `tools/unit_editor_auto_connection_ui_probe.gd`
  - Tests button visibility, auto-connect application, stale marking, evaluation blocking, and evaluation pass.

- Modify existing `tools/unit_editor_assembly_guide_service_probe.gd`
  - Update expected body guide order to include the new `connection` step between weapon and engine or, if the implementation treats connection as an in-board substep, assert the service exposes a stable connection key used by UI integration.

- Modify existing `tools/unit_editor_assembly_guide_ui_probe.gd`
  - Assert the guide exposes connection controls without removing manual catalog navigation.

---

### Task 1: Pure Auto-Connection Service

**Files:**
- Create: `scripts/services/unit_editor_auto_connection_service.gd`
- Create: `tools/unit_editor_auto_connection_service_probe.gd`

- [ ] **Step 1: Write the failing pure-service probe**

Create `tools/unit_editor_auto_connection_service_probe.gd` with this content:

```gdscript
extends SceneTree

const SERVICE_PATH := "res://scripts/services/unit_editor_auto_connection_service.gd"

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _socket(id: String, pos: Vector2, occupied: bool = false) -> Dictionary:
	return {
		"id": id,
		"pos": pos,
		"occupied": occupied,
	}


func _fact(index: int, slot_key: String, pos: Vector2, sockets: Array, is_torso: bool = false, terminal: bool = false, size_rank: int = 2, edge_count: int = 0) -> Dictionary:
	return {
		"index": index,
		"slot_key": slot_key,
		"pos": pos,
		"is_component": true,
		"is_torso": is_torso,
		"is_terminal_weapon": terminal,
		"size_rank": size_rank,
		"edge_count": edge_count,
		"sockets": sockets,
	}


func _plan_edges(plan: Dictionary) -> Array:
	var result: Array = []
	for raw_intent in Array(plan.get("intents", [])):
		if raw_intent is Dictionary:
			var intent: Dictionary = raw_intent
			result.append("%d:%s>%d:%s" % [
				int(intent.get("child", -1)),
				String(intent.get("child_socket", "")),
				int(intent.get("parent", -1)),
				String(intent.get("parent_socket", "")),
			])
	return result


func _init() -> void:
	var script := load(SERVICE_PATH)
	if script == null:
		_fail("Missing UnitEditorAutoConnectionService script.")
		quit(1)
		return
	var service = script.new()
	var torso := _fact(0, "muscle", Vector2(0.50, 0.50), [
		_socket("torso_port:0", Vector2(0.58, 0.50)),
		_socket("torso_port:1", Vector2(0.42, 0.50)),
	], true, false, 3)
	var limb := _fact(1, "limb_muscle", Vector2(0.66, 0.50), [
		_socket("root_joint", Vector2(0.62, 0.50)),
		_socket("distal", Vector2(0.75, 0.50)),
	], false, false, 2)
	var weapon := _fact(2, "muscle", Vector2(0.84, 0.50), [
		_socket("root_joint", Vector2(0.79, 0.50)),
		_socket("blade_tip", Vector2(0.91, 0.50)),
	], false, true, 2)
	var plan: Dictionary = service.plan_auto_connections({
		"node_facts": [torso, limb, weapon],
		"edges": [],
	})
	var expected := [
		"1:root_joint>0:torso_port:0",
		"2:root_joint>1:distal",
	]
	if _plan_edges(plan) != expected:
		_fail("Expected torso -> limb -> weapon plan, got %s." % str(_plan_edges(plan)))
	var occupied_limb := _fact(1, "limb_muscle", Vector2(0.66, 0.50), [
		_socket("root_joint", Vector2(0.62, 0.50), true),
		_socket("distal", Vector2(0.75, 0.50)),
	], false, false, 2)
	var occupied_plan: Dictionary = service.plan_auto_connections({
		"node_facts": [torso, occupied_limb, weapon],
		"edges": [],
	})
	if not Array(occupied_plan.get("unresolved_nodes", [])).has(1):
		_fail("Occupied child root should leave limb unresolved.")
	var reversed_plan: Dictionary = service.plan_auto_connections({
		"node_facts": [weapon, limb, torso],
		"edges": [],
	})
	if _plan_edges(reversed_plan) != expected:
		_fail("Input order must not change deterministic output, got %s." % str(_plan_edges(reversed_plan)))
	var passed: Dictionary = service.evaluate_connection({
		"topology_signature": "nodes=3|edges=2",
		"last_signature": "nodes=3|edges=2",
		"topology_note": "",
		"node_count": 3,
		"edge_count": 2,
		"torso_count": 1,
		"unconnected_nodes": [],
		"repairable_nodes": [],
	})
	if String(passed.get("state", "")) != "passed":
		_fail("Connected topology should pass, got %s." % str(passed))
	var repairable: Dictionary = service.evaluate_connection({
		"topology_signature": "nodes=3|edges=0",
		"last_signature": "",
		"topology_note": "INVALID: disconnected topology",
		"node_count": 3,
		"edge_count": 0,
		"torso_count": 1,
		"unconnected_nodes": [1, 2],
		"repairable_nodes": [1, 2],
	})
	if String(repairable.get("state", "")) != "repairable":
		_fail("Disconnected but repairable topology should be repairable, got %s." % str(repairable))
	var blocked: Dictionary = service.evaluate_connection({
		"topology_signature": "nodes=2|edges=0",
		"last_signature": "",
		"topology_note": "INVALID: missing torso",
		"node_count": 2,
		"edge_count": 0,
		"torso_count": 0,
		"unconnected_nodes": [0, 1],
		"repairable_nodes": [],
	})
	if String(blocked.get("state", "")) != "blocked":
		_fail("Missing torso should block, got %s." % str(blocked))
	var stale: Dictionary = service.evaluate_connection({
		"topology_signature": "nodes=3|edges=1",
		"last_signature": "nodes=3|edges=2",
		"topology_note": "",
		"node_count": 3,
		"edge_count": 1,
		"torso_count": 1,
		"unconnected_nodes": [],
		"repairable_nodes": [],
	})
	if String(stale.get("state", "")) != "stale":
		_fail("Signature mismatch should be stale, got %s." % str(stale))
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_AUTO_CONNECTION_SERVICE_PROBE ok")
	quit(0)
```

- [ ] **Step 2: Run the probe to verify it fails because the service does not exist**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_auto_connection_service_probe.gd
```

Expected: FAIL with `Missing UnitEditorAutoConnectionService script.`

- [ ] **Step 3: Add the pure service**

Create `scripts/services/unit_editor_auto_connection_service.gd` with these public methods and constants:

```gdscript
extends RefCounted
class_name UnitEditorAutoConnectionService

const STATE_PASSED := "passed"
const STATE_REPAIRABLE := "repairable"
const STATE_BLOCKED := "blocked"
const STATE_STALE := "stale"

const CHILD_SOCKET := "root_joint"
const PARENT_SOCKET_DISTAL := "distal"
const TORSO_PORT_PREFIX := "torso_port:"


func plan_auto_connections(context: Dictionary) -> Dictionary:
	var facts := _sorted_facts(Array(context.get("node_facts", [])))
	var occupied := _occupied_socket_map(facts)
	var intents: Array = []
	var unresolved: Array = []
	var connected := _initial_connected_nodes(facts)
	var pending := _pending_child_nodes(facts)
	var guard := 0
	while not pending.is_empty() and guard < facts.size() + 4:
		guard += 1
		var best := _best_candidate(pending, facts, connected, occupied)
		if best.is_empty():
			break
		intents.append(best)
		_mark_socket_occupied(occupied, int(best.get("child", -1)), String(best.get("child_socket", "")))
		_mark_socket_occupied(occupied, int(best.get("parent", -1)), String(best.get("parent_socket", "")))
		connected[int(best.get("child", -1))] = true
		_remove_pending_child(pending, int(best.get("child", -1)))
	for raw_fact in pending:
		if raw_fact is Dictionary:
			unresolved.append(int(Dictionary(raw_fact).get("index", -1)))
	return {
		"intents": intents,
		"unresolved_nodes": _sorted_ints(unresolved),
		"summary": _plan_summary(intents.size(), unresolved.size()),
	}


func evaluate_connection(context: Dictionary) -> Dictionary:
	var signature := String(context.get("topology_signature", ""))
	var last_signature := String(context.get("last_signature", ""))
	if last_signature != "" and signature != last_signature:
		return _evaluation(STATE_STALE, "连接已改动，请重新评估。", "Connection changed; evaluate again.", signature, context)
	var node_count := int(context.get("node_count", 0))
	var torso_count := int(context.get("torso_count", 0))
	var topology_note := String(context.get("topology_note", ""))
	var repairable_nodes := _sorted_ints(Array(context.get("repairable_nodes", [])))
	if node_count <= 0:
		return _evaluation(STATE_BLOCKED, "连接阻断：请先放置躯干或构件。", "Connection blocked: place a torso or component first.", signature, context)
	if torso_count <= 0:
		return _evaluation(STATE_BLOCKED, "连接阻断：请先放置躯干。", "Connection blocked: place a torso first.", signature, context)
	if topology_note == "" or not topology_note.begins_with("INVALID"):
		return _evaluation(STATE_PASSED, "连接评估通过：可以进入入场姿态。", "Connection passed: entry pose is available.", signature, context)
	if not repairable_nodes.is_empty():
		return _evaluation(STATE_REPAIRABLE, "部分构件未接入；可尝试自动连接。", "Some parts are unlinked; Auto Connect can try to repair them.", signature, context)
	return _evaluation(STATE_BLOCKED, "连接阻断：请先放置躯干或修正接口冲突。", "Connection blocked: fix torso or socket conflicts first.", signature, context)
```

Add these private helpers in the same file:

```gdscript
func topology_signature(nodes: Array, edges: Array) -> String:
	var node_parts: Array = []
	for i in range(nodes.size()):
		if not (nodes[i] is Dictionary):
			continue
		var node: Dictionary = nodes[i]
		var pos = node.get("pos", Vector2.ZERO)
		var pos_key := "0,0"
		if pos is Vector2:
			var v: Vector2 = pos
			pos_key = "%.3f,%.3f" % [snappedf(v.x, 0.001), snappedf(v.y, 0.001)]
		node_parts.append("%d:%s:%d:%s" % [i, String(node.get("slot", "")), int(node.get("part_index", node.get(String(node.get("slot", "")), -1))), pos_key])
	var edge_parts: Array = []
	for raw_edge in edges:
		if raw_edge is Dictionary:
			var edge: Dictionary = raw_edge
			edge_parts.append("%d:%s-%d:%s" % [int(edge.get("a_node", -1)), String(edge.get("a_socket", "")), int(edge.get("b_node", -1)), String(edge.get("b_socket", ""))])
		else:
			edge_parts.append(str(raw_edge))
	edge_parts.sort()
	return "nodes=%s|edges=%s" % [";".join(node_parts), ";".join(edge_parts)]


func _sorted_facts(facts: Array) -> Array:
	var result: Array = []
	for raw_fact in facts:
		if raw_fact is Dictionary and bool(Dictionary(raw_fact).get("is_component", false)):
			result.append(Dictionary(raw_fact).duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("index", -1)) < int(b.get("index", -1))
	)
	return result


func _pending_child_nodes(facts: Array) -> Array:
	var result: Array = []
	for raw_fact in facts:
		var fact: Dictionary = raw_fact
		if bool(fact.get("is_torso", false)):
			continue
		if int(fact.get("edge_count", 0)) > 0:
			continue
		if _socket_by_id(fact, CHILD_SOCKET).is_empty():
			continue
		result.append(fact)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := _child_priority(a)
		var pb := _child_priority(b)
		if pa == pb:
			return int(a.get("index", -1)) < int(b.get("index", -1))
		return pa < pb
	)
	return result


func _initial_connected_nodes(facts: Array) -> Dictionary:
	var result := {}
	for raw_fact in facts:
		var fact: Dictionary = raw_fact
		if bool(fact.get("is_torso", false)) or int(fact.get("edge_count", 0)) > 0:
			result[int(fact.get("index", -1))] = true
	return result


func _best_candidate(pending: Array, facts: Array, connected: Dictionary, occupied: Dictionary) -> Dictionary:
	var best := {}
	var best_score := INF
	for raw_child in pending:
		var child: Dictionary = raw_child
		var child_socket := _socket_by_id(child, CHILD_SOCKET)
		if child_socket.is_empty() or _socket_is_occupied(occupied, int(child.get("index", -1)), CHILD_SOCKET):
			continue
		for raw_parent in facts:
			var parent: Dictionary = raw_parent
			if not connected.has(int(parent.get("index", -1))):
				continue
			if int(parent.get("index", -1)) == int(child.get("index", -1)):
				continue
			for raw_socket in Array(parent.get("sockets", [])):
				if not (raw_socket is Dictionary):
					continue
				var parent_socket: Dictionary = raw_socket
				var parent_socket_id := String(parent_socket.get("id", ""))
				if not _socket_can_be_parent(parent_socket_id):
					continue
				if _socket_is_occupied(occupied, int(parent.get("index", -1)), parent_socket_id):
					continue
				var score := _candidate_score(child, child_socket, parent, parent_socket)
				if score < best_score:
					best_score = score
					best = {
						"child": int(child.get("index", -1)),
						"child_socket": CHILD_SOCKET,
						"parent": int(parent.get("index", -1)),
						"parent_socket": parent_socket_id,
						"score": score,
					}
	return best


func _candidate_score(child: Dictionary, child_socket: Dictionary, parent: Dictionary, parent_socket: Dictionary) -> float:
	var child_pos: Vector2 = child_socket.get("pos", child.get("pos", Vector2.ZERO))
	var parent_pos: Vector2 = parent_socket.get("pos", parent.get("pos", Vector2.ZERO))
	var distance := child_pos.distance_to(parent_pos)
	var size_delta := absf(float(child.get("size_rank", 2)) - float(parent.get("size_rank", 2)))
	var terminal_penalty := 0.35 if bool(child.get("is_terminal_weapon", false)) else 0.0
	var torso_bonus := -0.20 if bool(parent.get("is_torso", false)) else 0.0
	return distance + size_delta * 0.05 + terminal_penalty + torso_bonus + float(int(child.get("index", 0))) * 0.0001


func _child_priority(fact: Dictionary) -> int:
	if bool(fact.get("is_terminal_weapon", false)):
		return 20
	if String(fact.get("slot_key", "")) == "limb_muscle":
		return 5
	return 10


func _socket_by_id(fact: Dictionary, socket_id: String) -> Dictionary:
	for raw_socket in Array(fact.get("sockets", [])):
		if not (raw_socket is Dictionary):
			continue
		var socket: Dictionary = raw_socket
		if String(socket.get("id", "")) == socket_id:
			return socket
	return {}


func _socket_can_be_parent(socket_id: String) -> bool:
	return socket_id == PARENT_SOCKET_DISTAL or socket_id.begins_with(TORSO_PORT_PREFIX)


func _socket_key(node_index: int, socket_id: String) -> String:
	return "%d:%s" % [node_index, socket_id]


func _socket_is_occupied(occupied: Dictionary, node_index: int, socket_id: String) -> bool:
	return bool(occupied.get(_socket_key(node_index, socket_id), false))


func _occupied_socket_map(facts: Array) -> Dictionary:
	var result := {}
	for raw_fact in facts:
		var fact: Dictionary = raw_fact
		var node_index := int(fact.get("index", -1))
		for raw_socket in Array(fact.get("sockets", [])):
			if raw_socket is Dictionary:
				var socket: Dictionary = raw_socket
				if bool(socket.get("occupied", false)):
					result[_socket_key(node_index, String(socket.get("id", "")))] = true
	return result


func _mark_socket_occupied(occupied: Dictionary, node_index: int, socket_id: String) -> void:
	if node_index >= 0 and socket_id != "":
		occupied[_socket_key(node_index, socket_id)] = true


func _remove_pending_child(pending: Array, child_index: int) -> void:
	for i in range(pending.size() - 1, -1, -1):
		if pending[i] is Dictionary and int(Dictionary(pending[i]).get("index", -1)) == child_index:
			pending.remove_at(i)


func _sorted_ints(values: Array) -> Array:
	var result: Array = []
	for raw_value in values:
		var value := int(raw_value)
		if value >= 0 and not result.has(value):
			result.append(value)
	result.sort()
	return result


func _plan_summary(applied_count: int, unresolved_count: int) -> String:
	if applied_count <= 0 and unresolved_count <= 0:
		return "no_safe_links"
	if unresolved_count > 0:
		return "partial"
	return "complete"


func _evaluation(state: String, zh_note: String, en_note: String, signature: String, context: Dictionary) -> Dictionary:
	return {
		"state": state,
		"note": zh_note,
		"zh_note": zh_note,
		"en_note": en_note,
		"topology_signature": signature,
		"repairable_nodes": _sorted_ints(Array(context.get("repairable_nodes", []))),
		"blocked_nodes": _sorted_ints(Array(context.get("blocked_nodes", []))),
	}
```

- [ ] **Step 4: Run the pure-service probe and fix syntax until it passes**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_auto_connection_service_probe.gd
```

Expected: PASS with `UNIT_EDITOR_AUTO_CONNECTION_SERVICE_PROBE ok`.

- [ ] **Step 5: Commit the service and pure probe**

Run:

```bash
git add scripts/services/unit_editor_auto_connection_service.gd tools/unit_editor_auto_connection_service_probe.gd
git commit -m "Add unit editor auto connection service"
```

Expected: commit succeeds and does not include unrelated working-tree files.

---

### Task 2: Main Scene Auto-Connection Application

**Files:**
- Modify: `scripts/main.gd`
- Create: `tools/unit_editor_auto_connection_ui_probe.gd`

- [ ] **Step 1: Write the failing UI probe for action wiring**

Create `tools/unit_editor_auto_connection_ui_probe.gd` with this content:

```gdscript
extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main: Node, slot_key: String, predicate: Callable) -> int:
	var catalog: Array = main._catalog_for("hero", slot_key)
	for i in range(catalog.size()):
		if predicate.call(Dictionary(catalog[i])):
			return i
	return -1


func _place(main: Node, slot_key: String, part_index: int, pos: Vector2) -> int:
	main.editor_pending_place_slot = slot_key
	main.editor_pending_place_index = part_index
	var index := int(main._add_topology_node_at(pos))
	if index < 0:
		_fail("Failed to place %s #%d." % [slot_key, part_index])
	return index


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	for key in ["auto_connect", "evaluate_connection", "restore_suggested_connection"]:
		if not main.editor_action_buttons.has(key):
			_fail("Missing connection action button: %s" % key)
		var button: Button = main.editor_action_buttons[key]
		if not button.visible:
			_fail("Connection action should be visible for free-canvas body units: %s" % key)
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool:
		return bool(part.get("is_torso", false))
	)
	var limb_index := _find(main, "limb_muscle", func(part: Dictionary) -> bool:
		return int(part.get("connection_ends", 0)) >= 2
	)
	var weapon_index := _find(main, "muscle", func(part: Dictionary) -> bool:
		return bool(part.get("terminal_weapon", false)) or int(part.get("connection_ends", 2)) <= 1
	)
	if torso_index < 0 or limb_index < 0 or weapon_index < 0:
		_fail("Probe could not find torso, limb, and weapon catalog parts.")
	main._start_blank_topology()
	var torso_node := _place(main, "muscle", torso_index, Vector2(0.50, 0.50))
	var limb_node := _place(main, "limb_muscle", limb_index, Vector2(0.66, 0.50))
	var weapon_node := _place(main, "muscle", weapon_index, Vector2(0.84, 0.50))
	main._editor_action("evaluate_connection")
	if String(main.editor_connection_evaluation.get("state", "")) != "repairable":
		_fail("Disconnected beginner layout should be repairable, got %s." % str(main.editor_connection_evaluation))
	main._editor_action("auto_connect")
	var topology: Dictionary = main._editor_current_blueprint().get("custom_topology", {})
	var edges: Array = topology.get("edges", [])
	if edges.size() < 2:
		_fail("Auto Connect should create at least two edges, got %d." % edges.size())
	main._editor_action("evaluate_connection")
	if String(main.editor_connection_evaluation.get("state", "")) != "passed":
		_fail("Auto-connected beginner layout should pass, got %s." % str(main.editor_connection_evaluation))
	main._unlink_joint_edges(main._editor_current_blueprint(), weapon_node)
	if String(main.editor_connection_evaluation.get("state", "")) != "stale":
		_fail("Manual unlink should mark connection evaluation stale.")
	main._editor_action("restore_suggested_connection")
	main._editor_action("evaluate_connection")
	if String(main.editor_connection_evaluation.get("state", "")) != "passed":
		_fail("Restore Suggested followed by Evaluate should pass.")
	print("UNIT_EDITOR_AUTO_CONNECTION_UI_PROBE ok torso=%d limb=%d weapon=%d" % [torso_node, limb_node, weapon_node])
	quit(0)
```

- [ ] **Step 2: Run the UI probe to verify it fails because main is not wired**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_auto_connection_ui_probe.gd
```

Expected: FAIL with missing connection action button or missing `editor_connection_evaluation`.

- [ ] **Step 3: Preload and instantiate the service in `scripts/main.gd`**

Add near the existing service preload constants:

```gdscript
const UnitEditorAutoConnectionService = preload("res://scripts/services/unit_editor_auto_connection_service.gd")
```

Add near the existing editor service variables:

```gdscript
var unit_editor_auto_connection_service: UnitEditorAutoConnectionService
var editor_connection_evaluation := {
	"state": "stale",
	"note": "",
	"topology_signature": "",
	"repairable_nodes": [],
	"blocked_nodes": [],
}
var editor_connection_last_plan := {}
```

Instantiate in `_ready()` next to `unit_editor_assembly_guide_service = UnitEditorAssemblyGuideService.new()`:

```gdscript
unit_editor_auto_connection_service = UnitEditorAutoConnectionService.new()
```

- [ ] **Step 4: Add fact gathering and evaluation helpers to `scripts/main.gd`**

Add helpers near existing topology utility functions:

```gdscript
func _editor_connection_topology_signature(unit_bp: Dictionary) -> String:
	if unit_editor_auto_connection_service == null or not unit_bp.has("custom_topology"):
		return ""
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	return unit_editor_auto_connection_service.topology_signature(Array(topology.get("nodes", [])), Array(topology.get("edges", [])))


func _mark_editor_connection_evaluation_stale(reason: String = "connection.changed") -> void:
	editor_connection_evaluation["state"] = "stale"
	editor_connection_evaluation["note"] = "连接已改动，请重新评估。" if _ui_is_zh() else "Connection changed; evaluate again."
	editor_connection_evaluation["topology_signature"] = ""
	editor_connection_evaluation["reason"] = reason
	mark_editor_dirty(EDITOR_DIRTY_ACTION_BUTTONS | EDITOR_DIRTY_BOARD_UI, reason)


func _editor_connection_node_fact(role_key: String, unit_bp: Dictionary, nodes: Array, edges: Array, node_index: int) -> Dictionary:
	var node: Dictionary = nodes[node_index]
	var slot_key := _topology_node_slot(node)
	var part := _topology_node_part(role_key, node, unit_bp)
	var sockets: Array = []
	for socket_id in _topology_socket_ids_for_node(role_key, node, unit_bp):
		var canonical_id := _topology_canonical_socket_id(String(socket_id))
		sockets.append({
			"id": canonical_id,
			"pos": _topology_socket_position_by_id(role_key, unit_bp, nodes, edges, node_index, canonical_id, -1),
			"occupied": _topology_socket_occupied_count(edges, node_index, canonical_id) > 0,
		})
	return {
		"index": node_index,
		"slot_key": slot_key,
		"pos": _topology_node_position(node),
		"is_component": _topology_node_is_component(node),
		"is_torso": _topology_node_is_torso(role_key, node, unit_bp),
		"is_terminal_weapon": _part_counts_as_terminal_weapon(part, slot_key) or bool(part.get("terminal_weapon", false)) or int(part.get("connection_ends", 2)) <= 1,
		"size_rank": _size_tier_rank(_part_size_tier_label(part, slot_key)),
		"edge_count": _topology_node_edge_count(edges, node_index),
		"sockets": sockets,
	}


func _editor_connection_context(unit_bp: Dictionary, role_key: String) -> Dictionary:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", []))
	var edges: Array = Array(topology.get("edges", []))
	var facts: Array = []
	var unconnected_nodes: Array = []
	var torso_count := 0
	for i in range(nodes.size()):
		if not (nodes[i] is Dictionary) or not _topology_node_is_component(nodes[i]):
			continue
		var fact := _editor_connection_node_fact(role_key, unit_bp, nodes, edges, i)
		facts.append(fact)
		if bool(fact.get("is_torso", false)):
			torso_count += 1
		elif int(fact.get("edge_count", 0)) <= 0:
			unconnected_nodes.append(i)
	var plan := unit_editor_auto_connection_service.plan_auto_connections({
		"node_facts": facts,
		"edges": edges,
	})
	return {
		"node_facts": facts,
		"edges": edges,
		"nodes": nodes,
		"topology_signature": _editor_connection_topology_signature(unit_bp),
		"last_signature": String(editor_connection_evaluation.get("topology_signature", "")),
		"topology_note": _topology_rule_note(unit_bp, role_key, {}),
		"node_count": facts.size(),
		"edge_count": edges.size(),
		"torso_count": torso_count,
		"unconnected_nodes": unconnected_nodes,
		"repairable_nodes": Array(plan.get("unresolved_nodes", [])),
		"plan": plan,
	}
```

Use existing helper names when available. If `_topology_socket_occupied_count` is not public in this scope, add a small local helper:

```gdscript
func _topology_socket_occupied_count(edges: Array, node_index: int, socket_id: String) -> int:
	var count := 0
	var canonical := _topology_canonical_socket_id(socket_id)
	for edge in edges:
		if not _topology_edge_has_node(edge, node_index):
			continue
		if _topology_canonical_socket_id(_topology_edge_socket_for_node(edge, node_index)) == canonical:
			count += 1
	return count
```

- [ ] **Step 5: Add action handlers for auto, evaluate, and restore**

Add these methods near `_link_topology_node()`:

```gdscript
func _apply_editor_auto_connection_plan(replace_conflicts: bool, reason: String) -> Dictionary:
	var role_key: String = ROLE_ORDER[editor_role_index]
	var unit_bp: Dictionary = _editor_current_blueprint()
	if unit_editor_auto_connection_service == null or not _role_uses_body_board(role_key) or not unit_bp.has("custom_topology"):
		return {"applied": 0, "unresolved_nodes": []}
	var context := _editor_connection_context(unit_bp, role_key)
	var plan: Dictionary = context.get("plan", {})
	var intents: Array = Array(plan.get("intents", []))
	if intents.is_empty():
		editor_connection_last_plan = plan
		return {"applied": 0, "unresolved_nodes": Array(plan.get("unresolved_nodes", []))}
	_record_editor_undo_state("自动连接" if _ui_is_zh() else "auto connect")
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", [])).duplicate(true)
	var edges: Array = Array(topology.get("edges", [])).duplicate(true)
	var changed_nodes: Array = []
	var applied := 0
	for raw_intent in intents:
		if not (raw_intent is Dictionary):
			continue
		var intent: Dictionary = raw_intent
		var child := int(intent.get("child", -1))
		var parent := int(intent.get("parent", -1))
		var child_socket := String(intent.get("child_socket", ""))
		var parent_socket := String(intent.get("parent_socket", ""))
		if child < 0 or parent < 0 or child >= nodes.size() or parent >= nodes.size():
			continue
		if _topology_edge_exists(edges, child, parent):
			continue
		var connect_result := _topology_try_connect_sockets(role_key, unit_bp, nodes, edges, child, child_socket, parent, parent_socket)
		if not bool(connect_result.get("ok", false)):
			continue
		var target_pos := _topology_socket_position_by_id(role_key, unit_bp, nodes, edges, parent, parent_socket, child)
		var child_node: Dictionary = nodes[child]
		child_node = _topology_apply_socket_alignment(role_key, unit_bp, nodes, edges, child, child_socket, target_pos, _topology_node_position(child_node))
		nodes[child] = child_node
		for index in [child, parent]:
			if not changed_nodes.has(index):
				changed_nodes.append(index)
		applied += 1
	topology["nodes"] = nodes
	topology["edges"] = edges
	unit_bp["custom_topology"] = topology
	_topology_update_local_pose_fields(role_key, unit_bp)
	editor_connection_last_plan = plan
	_mark_editor_connection_evaluation_stale(reason)
	if applied > 0:
		_clear_cached_board_socket_candidate()
		_refresh_editor_visual_views_fast_drag(changed_nodes)
		_schedule_editor_stats_idle_refresh(reason)
		_play_sfx_wave("clack", 720.0, 0.055, -17.0)
	return {"applied": applied, "unresolved_nodes": Array(plan.get("unresolved_nodes", []))}


func _auto_connect_editor_topology() -> void:
	var result := _apply_editor_auto_connection_plan(false, "board.auto_connect")
	var applied := int(result.get("applied", 0))
	if editor_board_hint_label != null:
		if applied > 0:
			editor_board_hint_label.text = "自动连接已应用 %d 条建议；请评估连接。" % applied if _ui_is_zh() else "Auto Connect applied %d suggestion(s); evaluate connection." % applied
		else:
			editor_board_hint_label.text = "没有可自动连接的安全建议；请手动调整后评估。" if _ui_is_zh() else "No safe auto-connection suggestion; adjust manually and evaluate."
	mark_editor_dirty(EDITOR_DIRTY_ACTION_BUTTONS | EDITOR_DIRTY_BOARD_UI, "board.auto_connect")
	flush_editor_dirty(600)


func _evaluate_editor_connection() -> void:
	var role_key: String = ROLE_ORDER[editor_role_index]
	var unit_bp: Dictionary = _editor_current_blueprint()
	if unit_editor_auto_connection_service == null or not _role_uses_body_board(role_key) or not unit_bp.has("custom_topology"):
		return
	var context := _editor_connection_context(unit_bp, role_key)
	var evaluation: Dictionary = unit_editor_auto_connection_service.evaluate_connection(context)
	editor_connection_evaluation = evaluation
	if editor_board_hint_label != null:
		editor_board_hint_label.text = String(evaluation.get("note", ""))
	mark_editor_dirty(EDITOR_DIRTY_ACTION_BUTTONS | EDITOR_DIRTY_BOARD_UI, "board.evaluate_connection")
	flush_editor_dirty(600)


func _restore_suggested_editor_connection() -> void:
	var result := _apply_editor_auto_connection_plan(true, "board.restore_suggested_connection")
	var applied := int(result.get("applied", 0))
	if editor_board_hint_label != null:
		editor_board_hint_label.text = "已恢复建议连接 %d 条；请重新评估。" % applied if _ui_is_zh() else "Restored %d suggested link(s); evaluate again." % applied
	mark_editor_dirty(EDITOR_DIRTY_ACTION_BUTTONS | EDITOR_DIRTY_BOARD_UI, "board.restore_suggested_connection")
	flush_editor_dirty(600)
```

If `replace_conflicts` is true, remove only edges connected to the same child `root_joint` before applying that intent. Do not delete unrelated valid player-authored edges.

- [ ] **Step 6: Wire the new actions into `_editor_action()`**

Add cases in the existing `match action_key`:

```gdscript
"auto_connect":
	_auto_connect_editor_topology()
"evaluate_connection":
	_evaluate_editor_connection()
"restore_suggested_connection":
	_restore_suggested_editor_connection()
```

- [ ] **Step 7: Mark manual topology edits stale**

Call `_mark_editor_connection_evaluation_stale(...)` after successful topology-changing operations:

```gdscript
_mark_editor_connection_evaluation_stale("board.unlink_edge")
_mark_editor_connection_evaluation_stale("board.unlink_joint")
_mark_editor_connection_evaluation_stale("board.link")
_mark_editor_connection_evaluation_stale("board.add_node")
_mark_editor_connection_evaluation_stale("board.delete_node")
_mark_editor_connection_evaluation_stale("drag.finish")
_mark_editor_connection_evaluation_stale("paste.nodes")
_mark_editor_connection_evaluation_stale("cut.nodes")
_mark_editor_connection_evaluation_stale("clear_canvas")
```

Place each call only after the operation actually changes `custom_topology`, not in early-return failure branches. Avoid marking stale for pose-only changes, module binding, engine allocation, color changes, and catalog navigation.

- [ ] **Step 8: Run the UI probe and fix action/application errors**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_auto_connection_ui_probe.gd
```

Expected: PASS with `UNIT_EDITOR_AUTO_CONNECTION_UI_PROBE ok`.

- [ ] **Step 9: Commit main-scene auto-connection application**

Run:

```bash
git add scripts/main.gd tools/unit_editor_auto_connection_ui_probe.gd
git commit -m "Wire unit editor auto connection actions"
```

Expected: commit succeeds. If `scripts/main.gd` already contains uncommitted assembly-guide changes, include them only if they are direct prerequisites for this feature; otherwise keep a separate commit boundary.

---

### Task 3: Connection UI Controls and Guide Gate

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scripts/services/unit_editor_assembly_guide_service.gd`
- Modify: `tools/unit_editor_assembly_guide_service_probe.gd`
- Modify: `tools/unit_editor_assembly_guide_ui_probe.gd`

- [ ] **Step 1: Write failing expectations for the connection guide step**

Update `tools/unit_editor_assembly_guide_service_probe.gd` expected hero labels:

```gdscript
var expected_zh := ["躯干", "关节/肌肉", "武器", "连接", "引擎", "散热", "推进", "英魂", "行动模块"]
var expected_en := ["TORSO", "JOINT/MUSCLE", "WEAPON", "CONNECT", "ENGINE", "COOLING", "BOOSTER", "SOUL", "ACTION"]
```

Update the expected count:

```gdscript
if hero_steps.size() != 9:
	_fail("Hero guide should expose nine recommended assembly steps, got %d." % hero_steps.size())
```

Add:

```gdscript
var connection_model: Dictionary = service.step_model("hero", 3, true)
if String(connection_model.get("key", "")) != "connection":
	_fail("Step 4 should be the connection step, got %s." % str(connection_model))
if String(connection_model.get("instruction", "")).find("自动连接") < 0:
	_fail("Connection step should explicitly point players to Auto Connect.")
```

Update catalog-state assertions after the weapon step so engine is at index `4`, cooling `5`, booster `6`, identity `7`, and action module `8`.

- [ ] **Step 2: Run the guide service probe to verify it fails**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_assembly_guide_service_probe.gd
```

Expected: FAIL because the guide has no connection step.

- [ ] **Step 3: Add the connection step to `UnitEditorAssemblyGuideService`**

Insert after the weapon step in `BODY_STEPS`:

```gdscript
{
	"key": "connection",
	"slot_key": "",
	"part_group_mode": "",
	"part_filter_mode": "",
	"zh_title": "连接",
	"en_title": "CONNECT",
	"zh_instruction": "运行自动连接，检查拓扑，再用评估连接确认能进入入场姿态。",
	"en_instruction": "Run Auto Connect, inspect topology, then Evaluate Connection before entry pose.",
},
```

Update `catalog_state_for_step()` so the connection step returns a valid non-catalog action state:

```gdscript
if String(model.get("key", "")) == "connection":
	return {
		"valid": true,
		"action_key": "auto_connect",
		"part_group_mode": part_group_mode,
		"part_filter_mode": part_filter_mode,
		"slot_index": -1,
	}
```

Update `_select_editor_assembly_guide_step()` in `scripts/main.gd` to handle `action_key == "auto_connect"` by setting `editor_board_tool = "layout"`, showing the connection hint, and avoiding catalog selection.

- [ ] **Step 4: Add UI buttons in `scripts/main.gd`**

In `_build_editor_ui()`, add the three actions to `canvas_tools` immediately after `link_node`:

```gdscript
["auto_connect", "自动连接"],
["evaluate_connection", "评估连接"],
["restore_suggested_connection", "恢复建议"],
```

In `_apply_editor_panel_visibility()`, add them to `canvas_action_keys` after `link_node`:

```gdscript
var canvas_action_keys := ["blank_canvas", "board_tool_layout", "board_tool_pose", "add_node", "link_node", "auto_connect", "evaluate_connection", "restore_suggested_connection", "copy_selection", "cut_selection", "paste_selection", "delete_selected_part", "undo_canvas", "clear_canvas", "toggle_barrier_grid", "board_zoom_out", "board_zoom_in", "board_zoom_reset"]
```

For these keys, use compact labels and state color:

```gdscript
elif canvas_key == "auto_connect":
	_set_control_text_if_changed(action_button, "自动连接" if _ui_is_zh() else "AUTO")
	_set_control_tooltip_if_changed(action_button, "按当前部件位置生成最合理的连接建议。" if _ui_is_zh() else "Create the most reasonable safe links for the current parts.")
	_set_canvas_item_modulate_if_changed(action_button, Color(0.42, 1.0, 0.82, 1.0))
elif canvas_key == "evaluate_connection":
	_set_control_text_if_changed(action_button, "评估连接" if _ui_is_zh() else "EVAL")
	_set_control_tooltip_if_changed(action_button, "检查连接是否可以进入入场姿态。" if _ui_is_zh() else "Check whether connection is ready for entry pose.")
	_set_canvas_item_modulate_if_changed(action_button, _editor_connection_state_color())
elif canvas_key == "restore_suggested_connection":
	_set_control_text_if_changed(action_button, "恢复建议" if _ui_is_zh() else "RESTORE")
	_set_control_tooltip_if_changed(action_button, "重新应用系统建议的安全连接。" if _ui_is_zh() else "Reapply the system's safe suggested links.")
	_set_canvas_item_modulate_if_changed(action_button, Color(0.78, 0.9, 1.0, 0.82))
```

Add:

```gdscript
func _editor_connection_state_color() -> Color:
	match String(editor_connection_evaluation.get("state", "stale")):
		"passed":
			return Color(0.42, 1.0, 0.62, 1.0)
		"repairable":
			return Color(1.0, 0.86, 0.28, 1.0)
		"blocked":
			return Color(1.0, 0.38, 0.32, 1.0)
		_:
			return Color(0.82, 0.9, 1.0, 0.82)
```

- [ ] **Step 5: Gate recommended guide advancement to entry pose**

Add:

```gdscript
func _editor_connection_evaluation_passed() -> bool:
	return String(editor_connection_evaluation.get("state", "")) == "passed" and String(editor_connection_evaluation.get("topology_signature", "")) == _editor_connection_topology_signature(_editor_current_blueprint())
```

In `_select_editor_assembly_guide_step()`, when the current step is `connection` and the requested next step is after it, block movement unless `_editor_connection_evaluation_passed()` is true:

```gdscript
var current_model: Dictionary = unit_editor_assembly_guide_service.step_model(role_key, editor_assembly_guide_step_index, _ui_is_zh())
if String(current_model.get("key", "")) == "connection" and step_index > editor_assembly_guide_step_index and not _editor_connection_evaluation_passed():
	if editor_board_hint_label != null:
		editor_board_hint_label.text = "请先运行自动连接并通过连接评估，再进入入场姿态。" if _ui_is_zh() else "Run Auto Connect and pass Evaluate Connection before entry pose."
	return
```

If the guide has no explicit entry-pose step yet, this gate should block advancing from `connection` to `engine` until the connection evaluation passes. That keeps the current recommended order simple while still enforcing the connection checkpoint.

- [ ] **Step 6: Update the guide UI probe**

Update `tools/unit_editor_assembly_guide_ui_probe.gd`:

```gdscript
if guide_label.text.find("1/9") < 0 or guide_label.text.find("躯干") < 0:
	_fail("Assembly guide should start at the torso step, got: %s." % guide_label.text)
for action_key in ["assembly_guide_prev", "assembly_guide_apply", "assembly_guide_next", "auto_connect", "evaluate_connection", "restore_suggested_connection"]:
	if not main.editor_action_buttons.has(action_key):
		_fail("Missing guide or connection action button: %s." % action_key)
```

After moving from weapon to connection:

```gdscript
main._editor_action("assembly_guide_next")
if guide_label.text.find("4/9") < 0 or guide_label.text.find("连接") < 0:
	_fail("Guide should expose connection as step 4, got: %s." % guide_label.text)
main._editor_action("assembly_guide_next")
if guide_label.text.find("4/9") < 0:
	_fail("Guide should stay on connection until evaluation passes, got: %s." % guide_label.text)
```

- [ ] **Step 7: Run guide probes**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_assembly_guide_service_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_assembly_guide_ui_probe.gd
```

Expected:

```text
UNIT_EDITOR_ASSEMBLY_GUIDE_SERVICE_PROBE ok
UNIT_EDITOR_ASSEMBLY_GUIDE_UI_PROBE ok
```

- [ ] **Step 8: Commit guide and UI control changes**

Run:

```bash
git add scripts/main.gd scripts/services/unit_editor_assembly_guide_service.gd tools/unit_editor_assembly_guide_service_probe.gd tools/unit_editor_assembly_guide_ui_probe.gd
git commit -m "Add connection checkpoint to unit editor guide"
```

Expected: commit succeeds.

---

### Task 4: Verification and Integration Guardrails

**Files:**
- Modify only if a probe exposes a real issue: `scripts/main.gd`, `scripts/services/unit_editor_auto_connection_service.gd`, or relevant probe files.

- [ ] **Step 1: Run all targeted probes**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_auto_connection_service_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_auto_connection_ui_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_assembly_guide_service_probe.gd
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/unit_editor_assembly_guide_ui_probe.gd
```

Expected: all four probes print their `ok` line and exit with status `0`.

- [ ] **Step 2: Run existing layout and syntax checks**

Run:

```bash
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --check-only --quit-after 1
arch -arm64 /Volumes/vol1/Godot/4.6.2-stable/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/vol1/Eidolon-Circuit-yhzlxp --script res://tools/text_overflow_probe.gd
git diff --check
```

Expected:

```text
SCRIPT ERROR count is 0
TEXT_OVERFLOW_PROBE ok
git diff --check prints no output
```

- [ ] **Step 3: Review worktree scope**

Run:

```bash
git status --short
git diff --stat
git diff --name-only
```

Expected changed files are limited to:

```text
scripts/main.gd
scripts/services/unit_editor_auto_connection_service.gd
scripts/services/unit_editor_assembly_guide_service.gd
tools/unit_editor_auto_connection_service_probe.gd
tools/unit_editor_auto_connection_ui_probe.gd
tools/unit_editor_assembly_guide_service_probe.gd
tools/unit_editor_assembly_guide_ui_probe.gd
```

- [ ] **Step 4: Commit verification fixes if any were needed**

If Step 1 or Step 2 required code fixes, run:

```bash
git add scripts/main.gd scripts/services/unit_editor_auto_connection_service.gd scripts/services/unit_editor_assembly_guide_service.gd tools/unit_editor_auto_connection_service_probe.gd tools/unit_editor_auto_connection_ui_probe.gd tools/unit_editor_assembly_guide_service_probe.gd tools/unit_editor_assembly_guide_ui_probe.gd
git commit -m "Stabilize unit editor auto connection workflow"
```

Expected: commit succeeds only when real fixes were made.

---

## Spec Coverage Self-Review

- Auto connection on existing nodes: Task 1 creates deterministic plans; Task 2 applies them without creating or deleting parts.
- Manual adjustment remains available: Task 2 marks manual topology edits stale but does not remove existing edit controls.
- Evaluation before entry pose: Task 2 creates evaluation state; Task 3 gates guide advancement.
- Existing topology authority remains intact: Task 2 uses `_topology_try_connect_sockets()`, `_topology_rule_note()`, and existing socket helpers.
- UI controls: Task 3 adds `自动连接`, `评估连接`, and `恢复建议`.
- Barrier and non-body behavior: Task 3 visibility rules hide these controls on screen-board barrier editing.
- Side-mounted weapon behavior: Task 2 keeps `_finalize_topology_link_success()` style side effects and does not remove handedness controls.
- Testing: Tasks 1 through 4 cover pure service, UI integration, guide behavior, syntax, overflow, and diff cleanliness.
