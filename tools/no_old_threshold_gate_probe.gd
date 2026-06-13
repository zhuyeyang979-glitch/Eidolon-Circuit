extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	if file == null:
		_fail("Could not read main.gd")
		return
	var text := file.get_as_text()
	var runtime_damage_pos := text.find("func _apply_runtime_contact_damage")
	var recovery_pos := text.find("func _force_runtime_collision_recovery(")
	if runtime_damage_pos < 0 or recovery_pos <= runtime_damage_pos:
		_fail("Could not locate runtime contact damage block.")
		return
	var block := text.substr(runtime_damage_pos, recovery_pos - runtime_damage_pos)
	for forbidden in ["_damage_after_damage_unit_gate", "_projectile_event_has_gun_source", "damage_unit_gate", "projectile gate"]:
		if block.find(forbidden) >= 0:
			_fail("Runtime contact damage still references old gate: %s" % forbidden)
			return
	if block.find("_runtime_contact_path_stiffness") < 0 or block.find("usable_contact_momentum") < 0:
		var service_file := FileAccess.open("res://scripts/services/runtime_contact_service.gd", FileAccess.READ)
		if service_file == null:
			_fail("Could not read RuntimeContactService.")
			return
		var service_text := service_file.get_as_text()
		var service_damage_pos := service_text.find("func damage_intent")
		if service_damage_pos < 0:
			_fail("RuntimeContactService does not expose damage_intent.")
			return
		var service_damage_block := service_text.substr(service_damage_pos)
		for required in [
			"var usable_momentum := minf(contact_momentum, attacker_path_stiffness)",
			"\"usable_contact_momentum\": usable_momentum",
			"\"attacker_path_stiffness\": attacker_path_stiffness",
		]:
			if service_damage_block.find(required) < 0:
				_fail("Runtime contact damage does not expose stiffness-capped momentum: %s" % required)
				return
		if block.find("_runtime_contact_service().damage_intent") < 0 or block.find("\"attacker_path_stiffness\": attacker_path_stiffness") < 0:
			_fail("main.gd should feed stiffness data into RuntimeContactService.damage_intent.")
			return
	for forbidden in ["func _damage_after_damage_unit_gate", "func _target_damage_unit_threshold", "func _runtime_damage_threshold_for_event", "damage_unit_block_reason"]:
		if text.find(forbidden) >= 0:
			_fail("Old threshold gate symbol still exists: %s" % forbidden)
			return
	print("NO_OLD_THRESHOLD_GATE_PROBE ok")
	quit()
