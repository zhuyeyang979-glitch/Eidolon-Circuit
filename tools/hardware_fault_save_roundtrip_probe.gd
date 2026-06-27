extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")

const TRANSIENT_KEYS := [
	"hardware_fault_state_table",
	"hardware_fault_transition_events",
	"hardware_fault_destruction_intents",
	"hardware_fault_state",
	"hardware_fault_transition_sequence",
	"hardware_fault_runtime_momentum_capacity",
	"runtime_momentum_capacity",
	"transition_sequence",
	"pre_state",
	"post_state",
	"destruction_intent",
]

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _remove_saved_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _contains_key(value, key: String) -> bool:
	if value is Dictionary:
		var dict: Dictionary = value
		if dict.has(key):
			return true
		for child_key in dict.keys():
			if _contains_key(dict[child_key], key):
				return true
	elif value is Array:
		for child in Array(value):
			if _contains_key(child, key):
				return true
	return false


func _inject_transient_fault_state(unit_bp: Dictionary) -> Dictionary:
	var polluted := unit_bp.duplicate(true)
	polluted["hardware_fault_state_table"] = {
		"body-a": {
			0: {"state": "faulted", "runtime_momentum_capacity": 12.0, "transition_sequence": 1},
		},
	}
	polluted["hardware_fault_transition_events"] = [{
		"simulation_tick": 4,
		"contact_sequence": 1,
		"runtime_momentum_capacity": 12.0,
		"pre_state": "normal",
		"post_state": "faulted",
	}]
	polluted["hardware_fault_destruction_intents"] = [{
		"destruction_intent": "destroy_hardware",
		"hardware_node_id": 2,
	}]
	var topology: Dictionary = Dictionary(polluted.get("custom_topology", {})).duplicate(true)
	var nodes: Array = Array(topology.get("nodes", [])).duplicate(true)
	if not nodes.is_empty() and nodes[0] is Dictionary:
		var node: Dictionary = Dictionary(nodes[0]).duplicate(true)
		node["hardware_fault_state"] = "destroyed"
		node["hardware_fault_transition_sequence"] = 3
		node["hardware_fault_runtime_momentum_capacity"] = 99.0
		node["runtime_momentum_capacity"] = 99.0
		node["transition_sequence"] = 2
		node["pre_state"] = "faulted"
		node["post_state"] = "destroyed"
		nodes[0] = node
	topology["nodes"] = nodes
	polluted["custom_topology"] = topology
	return polluted


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_editor(true)

	var legal_bp := LegalStarterBlueprintFixture.build(main, "Hardware Fault Save Roundtrip")
	_require(not legal_bp.is_empty(), "Could not build legal starter fixture.")
	if failed:
		quit(1)
		return
	var polluted := _inject_transient_fault_state(legal_bp)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = polluted
	main.editor_canvas_mode = "blank"

	var save_path := "%s/hardware_fault_roundtrip_%d.json" % [MainScene.SAVED_UNITS_DIR, int(Time.get_ticks_msec())]
	var result := main._save_editor_current_unit_to_library_named("Hardware Fault Save Roundtrip", save_path, true)
	_require(result == save_path and FileAccess.file_exists(save_path), "Polluted legal starter should save after stripping transient hardware fault fields, got %s" % result)
	if result == save_path and FileAccess.file_exists(save_path):
		var payload_raw := FileAccess.get_file_as_string(ProjectSettings.globalize_path(save_path))
		var parsed = JSON.parse_string(payload_raw)
		_require(parsed is Dictionary, "Saved payload should parse as dictionary.")
		if parsed is Dictionary:
			var payload: Dictionary = parsed
			for key in TRANSIENT_KEYS:
				_require(not _contains_key(payload, key), "Saved payload should not contain transient hardware fault key %s: %s" % [key, str(payload)])
			var readback := main._unit_library_entry_from_file(save_path)
			_require(not readback.is_empty(), "Saved payload should read back into the unit library.")
			for key in TRANSIENT_KEYS:
				_require(not _contains_key(readback, key), "Readback entry should not contain transient hardware fault key %s: %s" % [key, str(readback)])
		_remove_saved_file(save_path)

	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_SAVE_ROUNDTRIP_PROBE ok")
	quit(0)
