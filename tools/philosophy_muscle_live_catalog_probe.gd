extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const SAFE_LIMB_MUSCLES := [
	"SYNTAX STANDARD LINK",
	"CRUSTA CARAPACE FORELIMB",
	"COINRUN LIGHT STRIDER",
	"HUMANOVA DUEL FOREARM",
	"RAZOR FLEX TENDON",
	"COLOSSUS SINEW GIRDER",
]

const SAFE_TORSOS := [
	"SYNTAX MIDFIELD CORE",
	"FOLD STAGE TORSO",
	"HUMANOVA DUEL CORE",
]

const SAFE_MELEE := {
	"CRUSTA PRESS CLAW": "blunt",
	"COLOSSUS ARENA MAUL": "hammer",
	"HUMANOVA NEEDLE RAPIER": "rapier",
	"SHORT CRESCENT SCYTHE": "scythe",
	"WAKIZASHI KATANA MUSCLE": "katana",
	"STANDARD GREATSWORD MUSCLE": "greatsword",
	"SHORT JOUSTING LANCE": "lance",
	"DUELING RAPIER MUSCLE": "rapier",
	"MICRO DRILL BIT": "drill",
}

const SAFE_BARRIERS := [
	"VAULT DIVIDEND BULKHEAD",
	"CRUSTA PRESSURE GATE PANEL",
	"LONGSIGHT ONE-WAY SNIPER SCREEN",
	"COINRUN JACKPOT BLOCK",
	"MAZE RIGHT GRAVITY FLOOR PANEL",
	"MAZE REPAIR DOCK FLOOR PANEL",
	"MAZE SPEED RAIL STRIP PANEL",
	"MAZE BULLET RICOCHET WALL PANEL",
	"MAZE ENTRY BREACH CHARGE PANEL",
	"MAZE HARDLIGHT CAGE WALL PANEL",
]

const FROZEN_MUSCLES := [
	"REDLINE MIRV POD",
	"LIGHT-SINK NEEDLE",
	"TRACKING MISSILE POD",
	"MICRO SEEKER HIVE",
	"REDLINE FIXED BARRAGE RIFLE",
	"ORBITAL STARBURST LASER NODE",
]

const FROZEN_MODULES := [
	"GUNNER WRIST: QE MANUAL SWEEP",
	"RECOIL LOCK: BRACED GUN SWEEP",
	"TETHER CAST: AUTOSWING EJECT",
	"HIJACK ROUTER: PIN AND INSERT",
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _part(main, slot_key: String, item_name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", slot_key, item_name)
	if index < 0:
		_fail("Missing %s catalog part: %s" % [slot_key, item_name])
		return {}
	var catalog: Array = main._catalog_for("hero", slot_key)
	if index < 0 or index >= catalog.size():
		_fail("%s/%s index is outside _catalog_for()." % [slot_key, item_name])
		return {}
	var part: Dictionary = main._selected_component("hero", slot_key, index)
	if String(part.get("name", "")) != item_name:
		_fail("_selected_component() returned %s for %s/%s." % [String(part.get("name", "")), slot_key, item_name])
	return part


func _assert_live(main, slot_key: String, item_name: String) -> Dictionary:
	var part := _part(main, slot_key, item_name)
	if part.is_empty():
		return {}
	if main._part_is_catalog_frozen(slot_key, part):
		var lifecycle: Dictionary = main._catalog_lifecycle_for_part(slot_key, part)
		_fail("%s should be live, got %s/%s." % [item_name, String(lifecycle.get("catalog_lifecycle", "")), String(lifecycle.get("future_dev_tag", ""))])
	if String(part.get("catalog_lifecycle", "live")) != "live":
		_fail("%s should carry live lifecycle metadata." % item_name)
	if String(part.get("future_dev_tag", "")) != "":
		_fail("%s should not carry a future_dev_tag." % item_name)
	return part


func _assert_frozen(main, slot_key: String, item_name: String) -> void:
	var part := _part(main, slot_key, item_name)
	if part.is_empty():
		return
	if not main._part_is_catalog_frozen(slot_key, part):
		_fail("%s should remain frozen." % item_name)
	var lifecycle: Dictionary = main._catalog_lifecycle_for_part(slot_key, part)
	if String(lifecycle.get("future_dev_tag", "")) == "":
		_fail("%s should report a future_dev_tag." % item_name)


func _entries_for_filter(main, group_key: String, filter_key: String, slot_key: String = "muscle") -> Array:
	main.editor_part_group_mode = group_key
	main.editor_part_filter_mode = filter_key
	main._invalidate_editor_catalog_cache()
	return main._editor_catalog_raw_entries("hero", slot_key)


func _assert_visible_in_filter(main, item_name: String, group_key: String, filter_key: String, slot_key: String = "muscle") -> void:
	for raw_entry in _entries_for_filter(main, group_key, filter_key, slot_key):
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var part: Dictionary = entry.get("part", {})
		if String(part.get("name", "")) == item_name:
			return
	_fail("%s should be visible in %s/%s editor entries." % [item_name, group_key, filter_key])


func _assert_not_visible_in_filter(main, item_name: String, group_key: String, filter_key: String) -> void:
	for raw_entry in _entries_for_filter(main, group_key, filter_key):
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var part: Dictionary = entry.get("part", {})
		if String(part.get("name", "")) == item_name:
			_fail("%s should not be visible in %s/%s editor entries." % [item_name, group_key, filter_key])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	for item_name in SAFE_LIMB_MUSCLES:
		var part := _assert_live(main, "limb_muscle", String(item_name))
		if not bool(part.get("limb_segment", false)) or bool(part.get("terminal_weapon", true)) or int(part.get("connection_ends", 0)) != 2:
			_fail("%s should be normalized as a two-ended limb segment." % String(item_name))
		if float(part.get("joint_output_momentum_base", 0.0)) <= 0.0:
			_fail("%s should keep limb drive defaults." % String(item_name))
		_assert_visible_in_filter(main, String(item_name), "limb", "ordinary", "limb_muscle")
	for item_name in SAFE_TORSOS:
		var part := _assert_live(main, "muscle", String(item_name))
		if not main._component_is_torso(part) or int(part.get("joint_ports", 0)) <= 0:
			_fail("%s should be a runtime torso component." % String(item_name))
		_assert_visible_in_filter(main, String(item_name), "torso", "connector_torso")
	for item_name in SAFE_MELEE.keys():
		var part := _assert_live(main, "muscle", String(item_name))
		if main._terminal_weapon_kind_for_part(part, "muscle") != "melee":
			_fail("%s should be a melee terminal." % String(item_name))
		var expected_family := String(SAFE_MELEE[item_name])
		if expected_family in ["scythe", "katana", "greatsword", "shield", "hammer", "gauntlet", "lance", "rapier", "drill"]:
			if String(part.get("weapon_family", "")) != expected_family:
				_fail("%s family expected %s, got %s." % [String(item_name), expected_family, String(part.get("weapon_family", ""))])
			_assert_visible_in_filter(main, String(item_name), "terminal_weapon", "weapon_%s" % expected_family)
		else:
			_assert_visible_in_filter(main, String(item_name), "terminal_weapon", "weapon_%s" % expected_family)
	for item_name in SAFE_BARRIERS:
		var part := _assert_live(main, "muscle", String(item_name))
		if not bool(part.get("barrier_panel", false)) or not bool(part.get("barrier_tile_component", false)):
			_fail("%s should be a live barrier tile muscle." % String(item_name))
		_assert_visible_in_filter(main, String(item_name), "barrier_panel", "barrier_muscle")
	for item_name in FROZEN_MUSCLES:
		_assert_frozen(main, "muscle", String(item_name))
		_assert_not_visible_in_filter(main, String(item_name), "terminal_weapon", "terminal_ranged")
	for item_name in FROZEN_MODULES:
		_assert_frozen(main, "module", String(item_name))
	print("PHILOSOPHY_MUSCLE_LIVE_CATALOG_PROBE ok limbs=%d melee=%d barriers=%d" % [SAFE_LIMB_MUSCLES.size(), SAFE_MELEE.size(), SAFE_BARRIERS.size()])
	quit()
