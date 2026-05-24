extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _nearly_same(a: PackedVector2Array, b: PackedVector2Array, tolerance: float = 0.01) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i].distance_to(b[i]) > tolerance:
			return false
	return true


func _assert_runtime_shape(family: String, damage_type: String, extra: Dictionary = {}) -> void:
	var segment := {
		"part_kind": "terminal",
		"name": family.to_upper(),
		"damage_type": damage_type,
		"material_class": "weapon",
		"terminal_weapon_kind": "melee",
		"weapon_family": family,
		"source_shape": family,
		"shape": family,
		"a": Vector2(-0.5, 0.0),
		"b": Vector2(0.5, 0.0),
		"a_local": Vector2(-0.5, 0.0),
		"b_local": Vector2(0.5, 0.0),
		"radius": 0.08,
	}
	for key in extra.keys():
		segment[key] = extra[key]
	var overlay := Renderer.runtime_segment_overlay_polygon(segment, Vector2.ZERO, 0.0, 1.0)
	var node := Renderer.segment_to_component_node(segment)
	var visual := Renderer.component_polygon(Vector2.ZERO, node, Vector2.RIGHT, 2.0, 1.0, true)
	if not _nearly_same(overlay, visual):
		_fail("%s runtime overlay and component polygon diverged: %d vs %d" % [family, overlay.size(), visual.size()])
		return


func _init() -> void:
	_assert_runtime_shape("scythe", "tear")
	_assert_runtime_shape("saber", "tear")
	_assert_runtime_shape("katana", "tear")
	_assert_runtime_shape("greatsword", "tear")
	_assert_runtime_shape("shield", "blunt", {"blunt_shield": true})
	_assert_runtime_shape("hammer", "blunt", {"blunt_hammer": true})
	_assert_runtime_shape("lance", "pierce")
	_assert_runtime_shape("rapier", "pierce")
	_assert_runtime_shape("drill", "pierce")
	_assert_runtime_shape("gauntlet", "blunt", {"blunt_gauntlet": true})
	_assert_runtime_shape("claw", "blunt")
	_assert_runtime_shape("racket", "blunt", {"material_class": "racket"})
	_assert_runtime_shape("chain", "blunt")
	_assert_runtime_shape("sniper", "bullet", {"material_class": "gun", "projectile": true, "gun_kind": "sniper", "projectile_style": "true_bullet"})
	_assert_runtime_shape("rifle", "bullet", {"material_class": "gun", "projectile": true, "gun_kind": "rifle", "projectile_style": "bullet_hell"})
	_assert_runtime_shape("laser_gun", "laser", {"material_class": "gun", "projectile": true, "gun_kind": "laser_gun", "projectile_style": "beam", "projectile_damage_type": "laser"})
	_assert_runtime_shape("sprayer", "chemical", {"material_class": "gun", "projectile": true, "gun_kind": "sprayer", "projectile_style": "spray", "projectile_damage_type": "chemical"})
	_assert_runtime_shape("grenade_launcher", "bullet", {"material_class": "gun", "projectile": true, "gun_kind": "grenade_launcher", "projectile_style": "explosive"})
	_assert_runtime_shape("missile_launcher", "bullet", {"material_class": "missile_launcher", "projectile": true, "gun_kind": "missile_launcher", "projectile_style": "missile"})
	_assert_runtime_shape("web_gun", "blunt", {"material_class": "web_gun", "projectile": true, "gun_kind": "web_gun", "projectile_style": "web"})
	print("RUNTIME_CONTACT_VISUAL_IDENTITY_PROBE ok")
	quit()
