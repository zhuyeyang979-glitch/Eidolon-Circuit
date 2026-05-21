extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "GaugeProbe",
		"stats": {
			"health": 100,
			"mass": 20.0,
			"body_move_speed": 4.0,
			"boost_speed": 8.0,
			"boost_momentum": 160.0,
			"ammo_capacity": {"bullet": 12, "chemical": 3, "laser": 0, "explosive": 0, "web": 0},
		},
	})
	unit.deploy(0.0, 0.0)
	main._initialize_unit_runtime_resources(unit)
	unit.velocity = Vector2.RIGHT * 3.0
	main.game_state = MainScene.STATE_BATTLE
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = 1
	main.active_units = {
		1: {"hero": unit, "puppet": [], "barrier": null},
		2: {"hero": null, "puppet": [], "barrier": null},
	}
	main._update_battle_instrument_gauge()
	if main.battle_instrument_gauge == null or not main.battle_instrument_gauge.visible:
		_fail("Battle instrument gauge should be visible for a controlled hero.")
		return
	if absf(main.battle_instrument_gauge.speed - 3.0) > 0.001:
		_fail("Gauge speed did not follow controlled unit velocity.")
		return
	if main.battle_instrument_gauge.has_method("_dominant_ammo_info"):
		var ammo_info: Dictionary = main.battle_instrument_gauge._dominant_ammo_info()
		if String(ammo_info.get("kind", "")) != "bullet" or int(ammo_info.get("current", 0)) != 12:
			_fail("Gauge should select the dominant ammo kind and current count.")
			return
	if main.battle_instrument_gauge.get("momentum") != null:
		_fail("Gauge should no longer expose momentum display state.")
		return
	main.ai_battle_seat = 3
	main._update_battle_instrument_gauge()
	if main.battle_instrument_gauge.visible:
		_fail("Gauge should hide for P3 spectator.")
		return
	print("BATTLE_INSTRUMENT_GAUGE_PROBE ok")
	quit()
