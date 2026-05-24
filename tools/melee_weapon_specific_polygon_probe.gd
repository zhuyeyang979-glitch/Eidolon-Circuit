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


func _init() -> void:
	var center := Vector2.ZERO
	var axis := Vector2.RIGHT
	var radius := 16.0
	var length := 100.0
	var generic_blade := Renderer.terminal_polygon(center, _node("", "tear", {"weapon_family": "", "shape": "blade"}), axis, radius, length)
	var scythe := Renderer.terminal_polygon(center, _node("scythe", "tear"), axis, radius, length)
	var saber := Renderer.terminal_polygon(center, _node("saber", "tear"), axis, radius, length)
	var katana := Renderer.terminal_polygon(center, _node("katana", "tear"), axis, radius, length)
	var greatsword := Renderer.terminal_polygon(center, _node("greatsword", "tear"), axis, radius, length)
	var shield := Renderer.terminal_polygon(center, _node("shield", "blunt", {"blunt_shield": true}), axis, radius, length)
	var hammer := Renderer.terminal_polygon(center, _node("hammer", "blunt", {"blunt_hammer": true}), axis, radius, length)
	var lance := Renderer.terminal_polygon(center, _node("lance", "pierce"), axis, radius, length)
	var rapier := Renderer.terminal_polygon(center, _node("rapier", "pierce"), axis, radius, length)
	var drill := Renderer.terminal_polygon(center, _node("drill", "pierce"), axis, radius, length)
	var gauntlet := Renderer.terminal_polygon(center, _node("gauntlet", "blunt", {"blunt_gauntlet": true}), axis, radius, length)
	var claw := Renderer.terminal_polygon(center, _node("claw", "blunt"), axis, radius, length)
	var racket := Renderer.terminal_polygon(center, _node("racket", "blunt", {"material_class": "racket"}), axis, radius, length)
	var chain := Renderer.terminal_polygon(center, _node("chain", "blunt"), axis, radius, length)
	var generic_blunt := Renderer.terminal_polygon(center, _node("", "blunt", {"weapon_family": "", "shape": "club"}), axis, radius, length)
	if scythe.size() < 10:
		_fail("Scythe polygon needs enough points to read as a hooked crescent, got %d." % scythe.size())
	if scythe.size() == generic_blade.size() and _bounds(scythe).size.is_equal_approx(_bounds(generic_blade).size):
		_fail("Scythe polygon still matches generic blade metrics.")
	var scythe_bounds := _bounds(scythe)
	if scythe_bounds.end.y < radius * 1.25 or absf(scythe_bounds.position.y) > radius * 0.32:
		_fail("Scythe polygon should read as a straight handle with a 90-degree upper hook blade: %s" % scythe_bounds)
	var saber_bounds := _bounds(saber)
	if saber_bounds.size.y <= radius * 0.85 or saber_bounds.size.y >= scythe_bounds.size.y * 0.75:
		_fail("Saber polygon should be a curved single-edge blade, not the scythe hook: saber=%s scythe=%s" % [saber_bounds, scythe_bounds])
	var katana_bounds := _bounds(katana)
	if katana_bounds.size.y <= radius * 0.65 or katana_bounds.size.y >= saber_bounds.size.y * 1.05:
		_fail("Katana polygon should be a thin single-edge sword, not a hook or generic stick: katana=%s saber=%s" % [katana_bounds, saber_bounds])
	var greatsword_bounds := _bounds(greatsword)
	if greatsword_bounds.size.y <= katana_bounds.size.y * 1.35 or greatsword.size() <= katana.size():
		_fail("Greatsword polygon should read as a broad two-edge blade: greatsword=%s katana=%s" % [greatsword_bounds, katana_bounds])
	var shield_bounds := _bounds(shield)
	var generic_blunt_bounds := _bounds(generic_blunt)
	if shield_bounds.size.y <= generic_blunt_bounds.size.y * 1.2:
		_fail("Shield polygon is not visibly wider than generic blunt: shield=%s generic=%s" % [shield_bounds, generic_blunt_bounds])
	if shield_bounds.end.x < length * 0.49 or shield_bounds.position.x > -length * 0.49:
		_fail("Shield polygon should keep a thick top-down arc plate over the full terminal length: %s" % shield_bounds)
	var hammer_bounds := _bounds(hammer)
	if hammer_bounds.size.y <= generic_blunt_bounds.size.y * 1.12 or hammer_bounds.end.x < length * 0.49:
		_fail("Hammer polygon should keep a long handle with a broad head: hammer=%s generic=%s" % [hammer_bounds, generic_blunt_bounds])
	var lance_bounds := _bounds(lance)
	var rapier_bounds := _bounds(rapier)
	if lance_bounds.size.y >= shield_bounds.size.y * 0.58 or lance_bounds.end.x < length * 0.49:
		_fail("Lance polygon should read as a long shaft with spear point: %s" % lance_bounds)
	if rapier_bounds.size.y >= shield_bounds.size.y * 0.65 or rapier_bounds.size.y <= radius * 0.9:
		_fail("Rapier polygon should be a needle blade with a visible guard: rapier=%s lance=%s" % [rapier_bounds, lance_bounds])
	if drill.size() < 8 or drill.size() > 10:
		_fail("Drill polygon should be a stable ribbed cone profile, got %d points" % drill.size())
	var drill_bounds := _bounds(drill)
	if drill_bounds.end.x < length * 0.49 or drill_bounds.size.y <= radius * 1.45:
		_fail("Drill polygon should keep a pointed front and readable rear body: %s" % drill_bounds)
	var gauntlet_bounds := _bounds(gauntlet)
	if gauntlet_bounds.size.y <= generic_blunt_bounds.size.y * 1.2:
		_fail("Gauntlet polygon is not broad enough to read as a fist: gauntlet=%s generic=%s" % [gauntlet_bounds, generic_blunt_bounds])
	if gauntlet.size() < 10:
		_fail("Gauntlet polygon needs a cuff, palm, and knuckle profile, got %d points." % gauntlet.size())
	if gauntlet_bounds.position.x > -length * 0.49 or gauntlet_bounds.size.y < radius * 2.1:
		_fail("Gauntlet should combine a slim piston handle with a broad fist front: %s" % gauntlet_bounds)
	var claw_bounds := _bounds(claw)
	if claw_bounds.size.y <= generic_blunt_bounds.size.y * 1.15 or claw.size() < 9:
		_fail("Claw polygon should show paired pincers around a palm: %s" % claw_bounds)
	var racket_bounds := _bounds(racket)
	if racket_bounds.size.y <= generic_blunt_bounds.size.y * 1.2 or racket_bounds.end.x < length * 0.49:
		_fail("Racket polygon should show a wide head and handle: %s" % racket_bounds)
	var chain_bounds := _bounds(chain)
	if chain_bounds.size.y <= radius * 0.75 or chain.size() < 6:
		_fail("Chain polygon should keep a flexible strand with weighted tip: %s" % chain_bounds)
	if failed:
		quit(1)
		return
	print("MELEE_WEAPON_SPECIFIC_POLYGON_PROBE ok")
	quit()
