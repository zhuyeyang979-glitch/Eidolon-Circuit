extends SceneTree


const SCRIPT_PATHS := [
	"res://scripts/main.gd",
	"res://scripts/fighter.gd",
	"res://scripts/part_art.gd",
]

const FORBIDDEN_SYMBOLS := [
	"_damage_after_damage_unit_gate",
	"_target_damage_unit_threshold",
	"_runtime_damage_threshold_for_event",
	"damage_unit_threshold",
	"torso_damage_units",
	"reference_damage",
	"_attack_groups_for",
	"_fallback_attack_group",
	"_part_segments_for_group",
	"_base_anchor_for_part",
	"_synthetic_collision_group",
	"_fallback_lane_bias",
	"editor_cad_reference",
	"_draw_atlas_icon",
]

const FORBIDDEN_PLAYER_TERMS := [
	"DAMAGE UNIT",
	"Momentum Cap",
	"Load Capacity",
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Cannot read %s" % path)
		return ""
	return file.get_as_text()


func _init() -> void:
	for path in SCRIPT_PATHS:
		var text := _read_text(path)
		for symbol in FORBIDDEN_SYMBOLS:
			if text.find(symbol) >= 0:
				_fail("Old combat symbol '%s' still appears in %s" % [symbol, path])
		for term in FORBIDDEN_PLAYER_TERMS:
			if text.find("\"%s\"" % term) >= 0:
				_fail("Old player-facing combat term '%s' still appears in %s" % [term, path])
	print("NO_OLD_COMBAT_TERMS_PROBE ok")
	quit()
