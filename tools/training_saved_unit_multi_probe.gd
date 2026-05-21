extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._legalize_ai_player_roster(1, true)
	var hero_bp: Dictionary = main._blueprint_for(1, "hero", 0).duplicate(true)
	hero_bp["unit_name"] = "Multi Training Hero"
	var puppet_bp: Dictionary = main._blueprint_for(1, "puppet", 0).duplicate(true)
	puppet_bp["unit_name"] = "Multi Training Puppet"
	var entries := [
		{"unit_library": true, "role": "hero", "path": "probe://hero", "unit_name": "Multi Training Hero", "blueprint": hero_bp},
		{"unit_library": true, "role": "puppet", "path": "probe://puppet", "unit_name": "Multi Training Puppet", "blueprint": puppet_bp},
	]
	main._import_saved_unit_entries_to_training(entries)
	main._select_ai_battle_seat(1)
	main._try_begin_battle_from_scout()
	if main.game_state != MainScene.STATE_BATTLE or main.battle_mode != MainScene.MODE_TRAINING:
		_fail("Saved unit multi-training should enter Training battle.")
	if Array(main.blueprints[1].get("hero", [])).size() != 1 or Array(main.blueprints[1].get("puppet", [])).size() != 1:
		_fail("Multi-training should import all selected units into P1 rosters.")
	if Array(main.sortie_loadouts[1]).size() < 2:
		_fail("Multi-training should keep all selected units in P1 sortie loadout.")
	if main.initial_role[1] != "hero":
		_fail("First available hero should be the controllable training starter.")
	print("TRAINING_SAVED_UNIT_MULTI_PROBE ok loadout=%d" % Array(main.sortie_loadouts[1]).size())
	quit()
