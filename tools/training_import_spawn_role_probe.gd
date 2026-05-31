extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _live_import_for_role(main, owner: int, role_key: String):
	var units: Dictionary = main.active_units.get(owner, {})
	if role_key == "hero":
		return units.get("hero", null)
	if role_key == "puppet":
		for unit in Array(units.get("puppet", [])):
			if main._is_live_unit(unit):
				return unit
		return null
	if role_key == "barrier":
		return units.get("barrier", null)
	return null


func _latest_unit2_blueprint(main) -> Dictionary:
	var entry: Dictionary = main._latest_saved_unit_named("2")
	if entry.is_empty() or not (entry.get("blueprint", {}) is Dictionary):
		return {}
	var bp: Dictionary = Dictionary(entry.get("blueprint", {})).duplicate(true)
	bp["role"] = String(entry.get("role", "hero"))
	return bp


func _fixture_blueprint_for_role(main, role_key: String) -> Dictionary:
	if role_key in ["hero", "puppet"]:
		var unit2 := _latest_unit2_blueprint(main)
		if not unit2.is_empty():
			unit2["role"] = role_key
			return unit2
	main._legalize_ai_player_roster(1, true)
	var bp: Dictionary = main._blueprint_for(1, role_key, 0).duplicate(true)
	bp["role"] = role_key
	return bp


func _run_case(role_key: String, seat: int) -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit_bp := _fixture_blueprint_for_role(main, role_key)
	if unit_bp.is_empty():
		_fail("No training import fixture for %s." % role_key)
		return
	var note := main._training_blueprint_illegal_note(1, role_key, unit_bp)
	if note != "":
		_fail("%s training import fixture is illegal: %s" % [role_key, note])
		return
	main.training_import_units = [{"role": role_key, "blueprint": unit_bp.duplicate(true)}]
	main.training_import_role_key = role_key
	main.training_import_blueprint = unit_bp.duplicate(true)
	main._start_battle(MainScene.MODE_TRAINING)
	main._select_ai_battle_seat(seat)
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE or main.battle_mode != MainScene.MODE_TRAINING:
		_fail("%s import did not enter training battle for seat %d." % [role_key, seat])
		return
	var owner := 2 if seat == 2 else 1
	var imported = _live_import_for_role(main, owner, role_key)
	if not main._is_live_unit(imported):
		_fail("%s import missing from player %d role slot." % [role_key, owner])
		return
	root.remove_child(main)
	main.queue_free()


func _init() -> void:
	for role_key in ["hero", "puppet", "barrier"]:
		_run_case(role_key, 1)
	_run_case("hero", 2)
	print("TRAINING_IMPORT_SPAWN_ROLE_PROBE ok")
	quit()
