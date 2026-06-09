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
		"module_action_profile": "blade_arc_return",
		"command_window_profile": "blade_simple_4_6",
		"module_part": {
			"module_action_profile": "blade_arc_return",
			"command_window_profile": "blade_simple_4_6",
		},
	}


func _runtime_variant(main, hero, binding: Dictionary, action_state: String) -> String:
	return main._battle_action_event_service().command_window_runtime_variant(
		String(binding.get("module_action_profile", "")),
		String(binding.get("command_window_profile", "")),
		main._command_text(1),
		action_state,
		Vector2.ZERO,
		main._latest_command_direction(1),
		main._unit_forward_vector(hero),
		main._runtime_gauntlet_command_profiles(),
		main._runtime_blunt_command_profiles(),
		main._runtime_blade_command_profiles()
	)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var hero := FakeHero.new()
	var binding := _binding()
	main.command_buffers[1] = []
	if main._runtime_module_state_for_binding(1, hero, binding, Vector2.ZERO, "normal") != "normal":
		_fail("No blade command should stay normal.")
	main.command_buffers[1] = ["6"]
	if main._runtime_module_state_for_binding(1, hero, binding, Vector2.ZERO, "normal") != "armor":
		_fail("6X should resolve to armor for simple blade profile.")
	if _runtime_variant(main, hero, binding, "armor") != "armor_forward_cut":
		_fail("6X should produce blade armor forward cut.")
	main.command_buffers[1] = ["4"]
	if main._runtime_module_state_for_binding(1, hero, binding, Vector2.ZERO, "normal") != "active":
		_fail("4X should resolve to active for simple blade profile.")
	if _runtime_variant(main, hero, binding, "active") != "active_reverse_cut":
		_fail("4X should produce blade active reverse cut.")
	main.command_buffers[1] = []
	if main._attack_window_state_for_binding(hero, binding, Vector2.RIGHT) != "armor":
		_fail("Front direction should resolve armor for simple blade profile.")
	if main._attack_window_state_for_binding(hero, binding, Vector2.LEFT) != "active":
		_fail("Rear direction should resolve active for simple blade profile.")
	print("BLADE_SIMPLE_COMMAND_PROBE ok")
	quit()
