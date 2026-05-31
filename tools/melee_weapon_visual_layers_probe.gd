extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _node(family: String, damage_type: String, extra: Dictionary = {}) -> Dictionary:
	var result := {
		"slot": "muscle",
		"terminal_weapon": true,
		"terminal_weapon_kind": "melee",
		"weapon_family": family,
		"shape": family,
		"source_shape": family,
		"damage_type": damage_type,
		"material_class": "weapon",
		"connection_ends": 1,
		"component_name": family.to_upper(),
	}
	for key in extra.keys():
		result[key] = extra[key]
	return result


func _assert_tags(label: String, node: Dictionary, expected: Array[String]) -> void:
	var tags := Renderer.terminal_visual_detail_tags(node)
	for tag in expected:
		if not tags.has(tag):
			_fail("%s missing visual detail tag %s in %s" % [label, tag, tags])


func _init() -> void:
	_assert_tags("scythe", _node("scythe", "tear"), ["long_handle", "right_angle_scythe", "crescent_hook_blade", "inner_cutting_edge"])
	_assert_tags("saber", _node("saber", "tear"), ["curved_saber_edge", "single_edge_blade", "old_scythe_art_reassigned"])
	_assert_tags("shield", _node("shield", "blunt", {"blunt_shield": true}), ["thick_arc_shield", "top_down_curved_plate", "inner_grip_ridge"])
	_assert_tags("drill", _node("drill", "pierce"), ["powered_drill_body", "chuck_collar", "animated_spiral_texture", "bit_ridges"])
	_assert_tags("gauntlet", _node("gauntlet", "blunt", {"blunt_gauntlet": true}), ["piston_rod_handle", "wrist_cuff", "finger_knuckles", "iron_fist_front"])
	_assert_tags("katana", _node("katana", "tear"), ["single_edge_curve", "short_guard", "wrapped_grip"])
	_assert_tags("greatsword", _node("greatsword", "tear"), ["broad_double_edge", "cross_guard", "heavy_tip"])
	_assert_tags("hammer", _node("hammer", "blunt", {"blunt_hammer": true}), ["long_handle", "hammer_head", "counterweight"])
	_assert_tags("lance", _node("lance", "pierce"), ["long_shaft", "spear_tip", "barbed_point"])
	_assert_tags("rapier", _node("rapier", "pierce"), ["needle_blade", "cup_guard", "thin_thrust_line"])
	_assert_tags("claw", _node("claw", "blunt"), ["paired_claws", "hinge_palm", "hook_tips"])
	_assert_tags("racket", _node("racket", "blunt", {"material_class": "racket"}), ["racket_frame", "inner_mesh", "long_grip"])
	_assert_tags("chain", _node("chain", "blunt"), ["chain_links", "flex_segments", "weighted_tip"])
	_assert_tags("sniper", _node("", "bullet", {"projectile": true, "gun_kind": "sniper", "projectile_style": "true_bullet", "material_class": "gun"}), ["long_barrel", "scope", "stock"])
	_assert_tags("rifle", _node("", "bullet", {"projectile": true, "gun_kind": "rifle", "projectile_style": "bullet_hell", "material_class": "gun"}), ["rifle_barrel", "magazine", "stock"])
	_assert_tags("laser_gun", _node("", "laser", {"projectile": true, "gun_kind": "laser_gun", "projectile_style": "beam", "material_class": "gun"}), ["prism_lens", "focus_coils", "slim_emitter"])
	_assert_tags("sprayer", _node("", "chemical", {"projectile": true, "gun_kind": "sprayer", "projectile_style": "spray", "projectile_damage_type": "chemical", "material_class": "gun"}), ["fluid_tank", "wide_nozzle", "hose_line"])
	_assert_tags("grenade", _node("", "bullet", {"projectile": true, "gun_kind": "grenade_launcher", "projectile_style": "explosive", "material_class": "gun"}), ["thick_barrel", "breech_block", "muzzle_ring"])
	_assert_tags("missile", _node("", "bullet", {"projectile": true, "gun_kind": "missile_launcher", "projectile_style": "missile", "material_class": "missile_launcher"}), ["missile_tubes", "rack_body", "nose_caps"])
	_assert_tags("web", _node("", "blunt", {"projectile": true, "gun_kind": "web_gun", "projectile_style": "web", "material_class": "web_gun"}), ["spool_body", "anchor_muzzle", "tether_line"])
	print("MELEE_WEAPON_VISUAL_LAYERS_PROBE ok")
	quit()
