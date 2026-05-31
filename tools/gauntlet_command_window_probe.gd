extends SceneTree

const MainScene := preload("res://scripts/main.gd")


class FakeHero:
	extends RefCounted
	var owner_id := 1
	func forward_vector() -> Vector2:
		return Vector2.RIGHT


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _binding() -> Dictionary:
	return {
		"module_action_profile": "blunt_gauntlet_extend_swing",
		"command_window_profile": "gauntlet_4_6_236_214",
		"module_part": {
			"module_action_profile": "blunt_gauntlet_extend_swing",
			"command_window_profile": "gauntlet_4_6_236_214",
		},
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var hero := FakeHero.new()
	var binding := _binding()
	main.command_buffers[1] = []
	if main._gauntlet_command_variant_for_binding(1, hero, binding, Vector2.ZERO, "normal") != "normal_extend":
		_fail("No command should produce normal extension.")
	main.command_buffers[1] = ["4"]
	if main._gauntlet_command_variant_for_binding(1, hero, binding, Vector2.ZERO, "normal") != "normal_outward_swing":
		_fail("4X should produce outward swing.")
	main.command_buffers[1] = ["6"]
	if main._gauntlet_command_variant_for_binding(1, hero, binding, Vector2.ZERO, "normal") != "normal_inward_swing":
		_fail("6X should produce inward swing.")
	main.command_buffers[1] = ["2", "6"]
	if main._runtime_module_state_for_binding(1, hero, binding, Vector2.ZERO, "normal") != "armor":
		_fail("236X shorthand 26 should resolve to armor for Gauntlet.")
	if main._gauntlet_command_variant_for_binding(1, hero, binding, Vector2.ZERO, "armor") != "armor_inward_extend":
		_fail("236X should produce armor inward extend-swing.")
	main.command_buffers[1] = ["2", "4"]
	if main._runtime_module_state_for_binding(1, hero, binding, Vector2.ZERO, "normal") != "active":
		_fail("214X shorthand 24 should resolve to active for Gauntlet.")
	if main._gauntlet_command_variant_for_binding(1, hero, binding, Vector2.ZERO, "active") != "active_outward_extend":
		_fail("214X should produce active outward extend-swing.")
	print("GAUNTLET_COMMAND_WINDOW_PROBE ok")
	quit()
