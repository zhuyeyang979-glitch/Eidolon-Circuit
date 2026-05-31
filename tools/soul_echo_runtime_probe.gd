extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"unit_name": "Soul Echo Probe",
		"stats": {
			"health": 120.0,
			"mass": 48.0,
			"soul_archetype": "duelist_oath",
			"soul_oath_active": true,
			"soul_echo_window": 1.0,
			"soul_echo_recovery_mult": 0.5,
			"soul_echo_heat_relief": 0.18,
		},
	})
	fighter._commit_soul_echo_window({"attack_key": 1})
	var same_key: Dictionary = fighter._runtime_apply_soul_echo_to_cooldown(1, 1.0)
	if bool(same_key.get("applied", false)):
		_fail("Soul echo should require a different bound limb/key.")
	var result: Dictionary = fighter._runtime_apply_soul_echo_to_cooldown(2, 1.0)
	if not bool(result.get("applied", false)):
		_fail("Soul echo did not apply to a different key.")
	if absf(float(result.get("cooldown", 0.0)) - 0.5) > 0.01:
		_fail("Soul echo cooldown did not use recovery multiplier: %s" % str(result))
	var spent: Dictionary = fighter._runtime_apply_soul_echo_to_cooldown(3, 1.0)
	if bool(spent.get("applied", false)):
		_fail("Soul echo should be consumed after one use.")
	print("SOUL_ECHO_RUNTIME_PROBE ok")
	quit()
