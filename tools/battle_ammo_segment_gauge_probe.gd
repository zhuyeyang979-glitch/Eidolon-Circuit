extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var gauge = MainScene.BattleInstrumentGaugeView.new()
	root.add_child(gauge)
	gauge.size = Vector2(260.0, 92.0)
	gauge.set_values(4.0, 12.0, {
		"bullet": {"current": 5, "capacity": 10},
		"chemical": {"current": 1, "capacity": 3},
	}, "zh")
	if absf(gauge.speed - 4.0) > 0.001:
		_fail("Gauge speed was not stored.")
		return
	if gauge.get("momentum") != null:
		_fail("Ammo gauge should not keep momentum state.")
		return
	var ammo_info: Dictionary = gauge._dominant_ammo_info()
	if String(ammo_info.get("kind", "")) != "bullet":
		_fail("Gauge should choose the ammo kind with the largest capacity for its icon.")
		return
	if int(ammo_info.get("current", 0)) != 5 or int(ammo_info.get("capacity", 0)) != 10:
		_fail("Gauge dominant ammo counts are wrong.")
		return
	print("BATTLE_AMMO_SEGMENT_GAUGE_PROBE ok")
	quit()
