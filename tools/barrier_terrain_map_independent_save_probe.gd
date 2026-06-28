extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FORBIDDEN_RUNTIME_KEYS := [
	"barrier_terrain_placement_intents",
	"barrier_terrain_deployment_intents",
	"barrier_terrain_blocked_tiles",
	"barrier_terrain_snapshot_arena_id",
	"terrain_collision_feature_id",
	"terrain_collision_kind",
	"terrain_collision_source",
	"terrain_collision_blocker_name",
]

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _first_forbidden_key_path(value, path: String = "$") -> String:
	if value is Dictionary:
		var dict: Dictionary = value
		for raw_key in dict.keys():
			var key := String(raw_key)
			var key_path := "%s.%s" % [path, key]
			if FORBIDDEN_RUNTIME_KEYS.has(key):
				return key_path
			var child_path := _first_forbidden_key_path(dict[raw_key], key_path)
			if child_path != "":
				return child_path
	if value is Array:
		var array_value: Array = value
		for i in range(array_value.size()):
			var child_path := _first_forbidden_key_path(array_value[i], "%s[%d]" % [path, i])
			if child_path != "":
				return child_path
	return ""


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"BATTLE_TERRAIN_TRANSIENT_SAVE_KEYS",
		"barrier_terrain_snapshot_arena_id",
		"terrain_collision_feature_id",
		"_strip_hardware_fault_transient_save_fields",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing map-independent terrain save token: %s" % token)

	var main = MainScene.new()
	root.add_child(main)
	main._ready()

	var terrain_policy := {
		"attach_kinds": ["wall"],
		"anchor_support": "barrier_panel",
		"inherit_orientation": true,
	}
	var source_bp := {
		"role": "barrier",
		"unit_id": "terrain-save-probe",
		"unit_name": "Terrain Save Probe",
		"name": "Terrain Save Probe",
		"barrier_tiles": [
			{
				"index": 3,
				"joint": 30,
				"terrain_policy": terrain_policy.duplicate(true),
				"barrier_terrain_placement_intents": [{"feature_id": "runtime-wall"}],
				"nested_runtime": {
					"terrain_collision_source": "terrain",
				},
			},
		],
		"barrier_terrain_snapshot_arena_id": "mobius_default_arena",
		"barrier_terrain_deployment_intents": [{"action": "attach_to_terrain"}],
		"custom_topology": {
			"nodes": [
				{"slot_key": "joint", "terrain_collision_kind": "wall"},
			],
			"edges": [],
		},
		"entry_pose": {
			"0": {"barrier_terrain_blocked_tiles": [0]},
		},
	}
	var source_before := str(source_bp)
	var saved: Dictionary = main._unit_blueprint_for_library("barrier", source_bp)
	if not _expect(str(source_bp) == source_before, "_unit_blueprint_for_library should not mutate source blueprint"):
		return

	var violation := _first_forbidden_key_path(saved)
	if violation != "":
		_fail("Saved barrier blueprint should strip runtime terrain fields before library write: %s" % violation)
	var saved_tiles: Array = Array(saved.get("barrier_tiles", []))
	if _expect(saved_tiles.size() == 1, "Saved barrier should preserve its authored tile."):
		var saved_tile: Dictionary = Dictionary(saved_tiles[0])
		if not _expect(saved_tile.has("terrain_policy"), "Saved barrier tile should preserve map-independent terrain_policy."):
			return
		var saved_policy: Dictionary = Dictionary(saved_tile.get("terrain_policy", {}))
		if not _expect(Array(saved_policy.get("attach_kinds", [])).has("wall"), "terrain_policy attach_kinds should survive save: %s" % str(saved_policy)):
			return
		if not _expect(String(saved_policy.get("anchor_support", "")) == "barrier_panel", "terrain_policy anchor_support should survive save: %s" % str(saved_policy)):
			return
		if not _expect(saved_tile.has("pos") and not saved_tile.has("index"), "Saved barrier tile should still use map-independent screen pos format: %s" % str(saved_tile)):
			return

	var payload: Dictionary = main._saved_unit_library_service().build_save_payload(
		saved,
		"barrier",
		MainScene.SAVED_UNIT_SCHEMA_VERSION,
		main._json_safe_value(saved),
		MainScene.SAVE_KIND_SINGLE_UNIT
	)
	var payload_violation := _first_forbidden_key_path(payload)
	if payload_violation != "":
		_fail("Saved-unit payload should not reintroduce runtime terrain fields: %s" % payload_violation)

	if not failures.is_empty():
		print("BARRIER_TERRAIN_MAP_INDEPENDENT_SAVE_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BARRIER_TERRAIN_MAP_INDEPENDENT_SAVE_PROBE ok tiles=%d" % saved_tiles.size())
	quit(0)
