extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var part := {
		"name": "Probe Thruster",
		"thruster_family": "cruise_blue",
		"allocated_momentum": 50.0,
		"thruster_momentum": 50.0,
		"boost_momentum": 25.0,
		"move_efficiency": 1.0,
		"boost_efficiency": 2.0,
		"boost_duration": 0.3,
		"boost_heat": 6.0,
		"boost_cooldown": 0.5,
		"slot_volume_tier": "S",
	}
	var card_lines: Array = main._catalog_card_data_lines("booster", part)
	var detail_lines: Array = main._hover_card_player_detail_lines("booster", part)
	var text := ("\n".join(card_lines) + "\n" + "\n".join(detail_lines)).to_lower()
	if text.find("boost_power") >= 0 or text.find("normal_thrust") >= 0:
		_fail("Thruster card/hover should not expose legacy boost_power or normal_thrust.")
		return
	if text.find("boost额外") < 0 and text.find("boost extra") < 0 and text.find("b+") < 0:
		_fail("Thruster hover/card should clearly show Boost extra momentum.")
		return
	if text.find("总boost") < 0 and text.find("total boost") < 0:
		_fail("Thruster hover/card should clearly show total Boost momentum.")
		return
	if text.find("热") < 0 and text.find("heat") < 0:
		_fail("Thruster hover/card should show Boost heat.")
		return
	print("THRUSTER_HOVER_BOOST_TERMS_PROBE ok")
	quit()
