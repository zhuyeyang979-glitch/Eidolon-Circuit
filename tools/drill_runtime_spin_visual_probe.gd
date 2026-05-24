extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _drill_node(progress: float) -> Dictionary:
	return {
		"slot": "muscle",
		"terminal_weapon": true,
		"terminal_weapon_kind": "melee",
		"weapon_family": "drill",
		"shape": "drill",
		"source_shape": "drill",
		"damage_type": "pierce",
		"material_class": "weapon",
		"connection_ends": 1,
		"component_name": "MONOCHROME BREACH DRILL",
		"runtime_action": true,
		"runtime_action_progress": progress,
	}


func _init() -> void:
	var idle := _drill_node(0.0)
	idle["runtime_action"] = false
	if absf(Renderer.terminal_drill_spiral_offset(idle)) > 0.0001:
		_fail("Idle drill visual should not animate its spiral texture.")
		return
	var early := Renderer.terminal_drill_spiral_offset(_drill_node(0.1))
	var late := Renderer.terminal_drill_spiral_offset(_drill_node(0.7))
	if absf(early - late) <= 0.01:
		_fail("Runtime drill action should move the spiral texture offset; early=%.3f late=%.3f" % [early, late])
		return
	if Renderer.terminal_shape_family(_drill_node(0.4)) != "drill":
		_fail("Runtime drill node lost drill visual family.")
		return
	print("DRILL_RUNTIME_SPIN_VISUAL_PROBE ok early=%.3f late=%.3f" % [early, late])
	quit()
