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
		"module_action_profile": "scythe_hook_return",
		"command_window_profile": "blade_complex_236_214",
		"module_part": {
			"module_action_profile": "scythe_hook_return",
			"command_window_profile": "blade_complex_236_214",
		},
	}


func _assert_state(main, hero, binding: Dictionary, commands: Array, expected: String, label: String) -> void:
	main.command_buffers[1] = commands
	var actual: String = main._runtime_module_state_for_binding(1, hero, binding, Vector2.ZERO, "normal")
	if actual != expected:
		_fail("%s expected %s got %s" % [label, expected, actual])


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
	_assert_state(main, hero, binding, ["2", "3", "6"], "armor", "236X")
	if _runtime_variant(main, hero, binding, "armor") != "armor_special":
		_fail("236X should produce blade armor special.")
	_assert_state(main, hero, binding, ["2", "6"], "armor", "26X relaxed")
	_assert_state(main, hero, binding, ["2", "1", "4"], "active", "214X")
	if _runtime_variant(main, hero, binding, "active") != "active_special":
		_fail("214X should produce blade active special.")
	_assert_state(main, hero, binding, ["2", "4"], "active", "24X relaxed")
	_assert_state(main, hero, binding, ["6"], "normal", "bare 6 should not trigger complex blade armor")
	print("BLADE_COMPLEX_COMMAND_PROBE ok")
	quit()
