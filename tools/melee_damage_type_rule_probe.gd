extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_close(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > 0.001:
		_fail("%s expected %.3f, got %.3f." % [label, expected, actual])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main._melee_damage_adjusted({"damage_type": "tear"}, 100) != 150:
		_fail("Legacy tear should apply slash 1.5x damage.")
	if main._melee_damage_adjusted({"damage_type": "slash"}, 100) != 150:
		_fail("Slash alias should apply 1.5x damage.")
	if main._melee_damage_adjusted({"damage_type": "pierce"}, 100) != 100:
		_fail("Legacy pierce should not add direct damage.")
	if main._melee_damage_adjusted({"damage_type": "stab"}, 100) != 100:
		_fail("Stab alias should not add direct damage.")
	_assert_close(main._break_value_adjustment_for_event({"damage_type": "pierce"}), 0.5, "pierce break adjustment")
	_assert_close(main._break_value_adjustment_for_event({"damage_type": "stab"}), 0.5, "stab break adjustment")
	_assert_close(main._knock_adjustment_for_event({"damage_type": "blunt"}), 2.0, "blunt knock adjustment")
	if main._melee_damage_adjusted({"damage_type": "tear", "projectile": true}, 100) != 100:
		_fail("Projectile damage should not receive melee slash adjustment.")
	_assert_close(main._break_value_adjustment_for_event({"damage_type": "pierce", "projectile": true}), 1.0, "projectile break adjustment")
	_assert_close(main._knock_adjustment_for_event({"damage_type": "blunt", "projectile": true}), 1.0, "projectile knock adjustment")
	print("MELEE_DAMAGE_TYPE_RULE_PROBE ok")
	quit(0)
