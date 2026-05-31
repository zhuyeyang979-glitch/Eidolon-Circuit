extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const Renderer := preload("res://scripts/assembly_board_renderer.gd")
const PartArt := preload("res://scripts/part_art.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _entries_for_filter(main, filter_key: String) -> Array:
	main.editor_part_group_mode = "terminal_weapon"
	main.editor_part_filter_mode = filter_key
	return main._editor_catalog_raw_entries("hero", "muscle")


func _assert_filter_family(main, filter_key: String, expected_family: String) -> void:
	var entries := _entries_for_filter(main, filter_key)
	if entries.is_empty():
		_fail("No catalog entries for %s" % filter_key)
	var expected_profile: String = String({
		"scythe": "right_angle_scythe",
		"saber": "curved_saber",
		"katana": "single_edge_katana",
		"greatsword": "broad_greatsword",
		"shield": "thick_arc_shield",
		"hammer": "hammer_head",
		"lance": "spear_lance",
		"rapier": "needle_rapier",
		"drill": "powered_spiral_drill",
		"gauntlet": "piston_fist",
		"sniper": "scoped_sniper",
		"rifle": "stocked_rifle",
		"laser_gun": "prism_laser_gun",
		"sprayer": "chemical_sprayer",
		"grenade_launcher": "grenade_launcher",
		"missile_launcher": "missile_tube_pod",
		"web_gun": "web_spool_gun",
	}.get(expected_family, ""))
	var saw_expected := false
	for raw_entry in entries:
		var entry: Dictionary = raw_entry
		var part: Dictionary = entry.get("part", {})
		var node := Renderer.part_to_component_node("muscle", part)
		var family := Renderer.terminal_shape_family(node)
		if family != expected_family:
			_fail("%s expected %s but renderer classified %s as %s" % [filter_key, expected_family, String(part.get("name", "")), family])
		if expected_profile != "" and PartArt.terminal_profile_for(part) != expected_profile:
			_fail("%s expected PartArt profile %s for %s, got %s" % [filter_key, expected_profile, String(part.get("name", "")), PartArt.terminal_profile_for(part)])
		saw_expected = true
	if not saw_expected:
		_fail("No checked entries for %s" % filter_key)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	_assert_filter_family(main, "weapon_scythe", "scythe")
	_assert_filter_family(main, "weapon_greatsword", "greatsword")
	_assert_filter_family(main, "weapon_shield", "shield")
	_assert_filter_family(main, "weapon_hammer", "hammer")
	_assert_filter_family(main, "weapon_drill", "drill")
	_assert_filter_family(main, "weapon_gauntlet", "gauntlet")
	_assert_filter_family(main, "gun_sniper", "sniper")
	_assert_filter_family(main, "gun_rifle", "rifle")
	_assert_filter_family(main, "gun_laser_gun", "laser_gun")
	_assert_filter_family(main, "gun_missile_launcher", "missile_launcher")
	_assert_filter_family(main, "gun_web", "web_gun")
	var saber_node := Renderer.part_to_component_node("muscle", {"name": "ROACH WING SABER", "weapon_family": "saber", "shape": "saber", "damage_type": "tear", "terminal_weapon": true, "material_class": "weapon", "connection_ends": 1})
	if Renderer.terminal_shape_family(saber_node) != "saber" or PartArt.terminal_profile_for(saber_node) != "curved_saber":
		_fail("Saber visual family/profile was not recognized.")
	var katana_node := Renderer.part_to_component_node("muscle", {"name": "WAKIZASHI KATANA MUSCLE", "weapon_family": "katana", "shape": "katana", "damage_type": "tear", "terminal_weapon": true, "material_class": "weapon", "connection_ends": 1})
	if Renderer.terminal_shape_family(katana_node) != "katana" or PartArt.terminal_profile_for(katana_node) != "single_edge_katana":
		_fail("Katana visual family/profile was not recognized.")
	var claw_node := Renderer.part_to_component_node("muscle", {"name": "CRUSTA PRESS CLAW", "weapon_family": "claw", "shape": "claw", "damage_type": "blunt", "terminal_weapon": true, "material_class": "weapon", "connection_ends": 1})
	if Renderer.terminal_shape_family(claw_node) != "claw" or PartArt.terminal_profile_for(claw_node) != "paired_claw":
		_fail("Claw visual family/profile was not recognized.")
	var lance_node := Renderer.part_to_component_node("muscle", {"name": "STANDARD KNIGHT LANCE", "weapon_family": "lance", "shape": "lance", "damage_type": "pierce", "terminal_weapon": true, "material_class": "weapon", "connection_ends": 1})
	if Renderer.terminal_shape_family(lance_node) != "lance" or PartArt.terminal_profile_for(lance_node) != "spear_lance":
		_fail("Lance visual family/profile was not recognized.")
	var rapier_node := Renderer.part_to_component_node("muscle", {"name": "DUELING RAPIER MUSCLE", "weapon_family": "rapier", "shape": "rapier", "damage_type": "pierce", "terminal_weapon": true, "material_class": "weapon", "connection_ends": 1})
	if Renderer.terminal_shape_family(rapier_node) != "rapier" or PartArt.terminal_profile_for(rapier_node) != "needle_rapier":
		_fail("Rapier visual family/profile was not recognized.")
	var racket_node := Renderer.part_to_component_node("muscle", {"name": "SIEGE RACKET FRAME", "weapon_family": "racket", "shape": "racket", "damage_type": "blunt", "terminal_weapon": true, "material_class": "racket", "connection_ends": 1})
	if Renderer.terminal_shape_family(racket_node) != "racket" or PartArt.terminal_profile_for(racket_node) != "racket_frame":
		_fail("Racket visual family/profile was not recognized.")
	var chain_node := Renderer.part_to_component_node("muscle", {"name": "ANTENNA WHIP", "weapon_family": "chain", "shape": "chain", "damage_type": "blunt", "terminal_weapon": true, "material_class": "weapon", "connection_ends": 1})
	if Renderer.terminal_shape_family(chain_node) != "chain" or PartArt.terminal_profile_for(chain_node) != "chain_whip":
		_fail("Chain visual family/profile was not recognized.")
	var sprayer_node := Renderer.part_to_component_node("muscle", {"name": "标准化学喷射器 / STANDARD CAUSTIC SPRAYER", "gun_kind": "sprayer", "projectile_style": "spray", "projectile_damage_type": "chemical", "projectile": true, "terminal_weapon": true, "material_class": "gun", "connection_ends": 1})
	if Renderer.terminal_shape_family(sprayer_node) != "sprayer" or PartArt.terminal_profile_for(sprayer_node) != "chemical_sprayer":
		_fail("Sprayer visual family/profile was not recognized.")
	var grenade_node := Renderer.part_to_component_node("muscle", {"name": "红线跳爆榴弹枪 / REDLINE HOPPER GRENADE LAUNCHER", "gun_kind": "grenade_launcher", "projectile_style": "explosive", "projectile": true, "terminal_weapon": true, "material_class": "gun", "connection_ends": 1, "shape": "mortar"})
	if Renderer.terminal_shape_family(grenade_node) != "grenade_launcher" or PartArt.terminal_profile_for(grenade_node) != "grenade_launcher":
		_fail("Grenade launcher visual family/profile was not recognized.")
	print("MELEE_WEAPON_SHAPE_FAMILY_PROBE ok")
	quit()
