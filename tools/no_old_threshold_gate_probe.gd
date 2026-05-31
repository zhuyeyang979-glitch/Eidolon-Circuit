extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	if file == null:
		_fail("Could not read main.gd")
	var text := file.get_as_text()
	var runtime_damage_pos := text.find("func _apply_runtime_contact_damage")
	var recovery_pos := text.find("func _force_runtime_collision_recovery")
	if runtime_damage_pos < 0 or recovery_pos <= runtime_damage_pos:
		_fail("Could not locate runtime contact damage block.")
	var block := text.substr(runtime_damage_pos, recovery_pos - runtime_damage_pos)
	for forbidden in ["_damage_after_damage_unit_gate", "_projectile_event_has_gun_source", "damage_unit_gate", "projectile gate"]:
		if block.find(forbidden) >= 0:
			_fail("Runtime contact damage still references old gate: %s" % forbidden)
	if block.find("_runtime_contact_path_stiffness") < 0 or block.find("usable_contact_momentum") < 0:
		_fail("Runtime contact damage does not expose stiffness-capped momentum.")
	for forbidden in ["func _damage_after_damage_unit_gate", "func _target_damage_unit_threshold", "func _runtime_damage_threshold_for_event", "damage_unit_block_reason"]:
		if text.find(forbidden) >= 0:
			_fail("Old threshold gate symbol still exists: %s" % forbidden)
	print("NO_OLD_THRESHOLD_GATE_PROBE ok")
	quit()
