extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _bounds(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var min_p := poly[0]
	var max_p := poly[0]
	for p in poly:
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)
	return Rect2(min_p, max_p - min_p)


func _gun_node(label: String, extra: Dictionary) -> Dictionary:
	var result := {
		"slot": "muscle",
		"terminal_weapon": true,
		"terminal_weapon_kind": "ranged",
		"projectile": true,
		"material_class": "gun",
		"connection_ends": 1,
		"component_name": label,
		"label": label,
		"shape": label.to_lower(),
		"source_shape": label.to_lower(),
		"damage_type": "bullet",
		"projectile_damage_type": "bullet",
	}
	for key in extra.keys():
		result[key] = extra[key]
	return result


func _assert_family(label: String, expected_family: String, node: Dictionary, min_points: int, min_width: float) -> void:
	var family := Renderer.terminal_shape_family(node)
	if family != expected_family:
		_fail("%s expected visual family %s, got %s" % [label, expected_family, family])
		return
	var poly := Renderer.terminal_polygon(Vector2.ZERO, node, Vector2.RIGHT, 16.0, 100.0)
	if poly.size() < min_points:
		_fail("%s polygon too sparse: %d points" % [label, poly.size()])
	var rect := _bounds(poly)
	if rect.size.y < min_width:
		_fail("%s polygon too narrow to read in top view: %s" % [label, rect])


func _init() -> void:
	_assert_family("sniper", "sniper", _gun_node("STANDARD BULLET SNIPER", {"gun_kind": "sniper", "projectile_style": "true_bullet", "shape": "rifle"}), 10, 12.0)
	_assert_family("rifle", "rifle", _gun_node("LONGSIGHT PATTERN RIFLE", {"gun_kind": "rifle", "projectile_style": "bullet_hell", "shape": "rifle"}), 10, 14.0)
	_assert_family("laser", "laser_gun", _gun_node("LONGSIGHT PRISM LASER", {"gun_kind": "laser_gun", "projectile_style": "beam", "projectile_damage_type": "laser", "shape": "laser_gun"}), 8, 18.0)
	_assert_family("sprayer", "sprayer", _gun_node("STANDARD CAUSTIC SPRAYER", {"gun_kind": "sprayer", "projectile_style": "spray", "projectile_damage_type": "chemical", "shape": "sprayer_nozzle"}), 8, 18.0)
	_assert_family("grenade", "grenade_launcher", _gun_node("REDLINE HOPPER GRENADE LAUNCHER", {"gun_kind": "grenade_launcher", "projectile_style": "explosive", "shape": "mortar"}), 9, 22.0)
	_assert_family("mortar", "mortar", _gun_node("CAUSTIC BURST MORTAR", {"projectile_style": "spray", "projectile_damage_type": "chemical", "shape": "mortar"}), 9, 22.0)
	_assert_family("missile", "missile_launcher", _gun_node("REDLINE KESTREL MISSILE POD", {"material_class": "missile_launcher", "gun_kind": "missile_launcher", "projectile_style": "missile", "shape": "missile_rack"}), 10, 20.0)
	_assert_family("web", "web_gun", _gun_node("STANDARD WEB TETHER GUN", {"material_class": "web_gun", "gun_kind": "web_gun", "projectile_style": "web", "shape": "web_spool"}), 10, 18.0)
	if failed:
		quit(1)
		return
	print("RANGED_WEAPON_SPECIFIC_POLYGON_PROBE ok")
	quit()
