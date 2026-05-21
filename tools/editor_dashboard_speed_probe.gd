extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _base_stats() -> Dictionary:
	return {
		"blank_canvas": false,
		"role": "hero",
		"cost": 0,
		"deploy_cost": 0,
		"software_payload_count": 0,
		"slot_payload_count": 0,
		"module_slots": 0,
		"torso_slots": 0,
		"health": 100,
		"shield_max": 0,
		"mass": 24.0,
		"engine_power": 120.0,
		"required_power": 80.0,
		"cooling": 48.0,
		"idle_heat_load": 20.0,
		"body_move_speed": 3.2,
		"boost_speed": 5.4,
		"thruster_momentum": 76.8,
		"boost_momentum": 129.6,
		"thruster_acceleration": 1.6,
		"boost_duration": 0.32,
		"turn_speed": 1.2,
		"weakest_joint_momentum_capacity": 0,
		"max_joint_output_momentum": 0,
		"worst_joint_momentum": 0,
		"heat_capacity": 100,
		"data_security": 1.0,
		"internal_slot_max_installed_rank": 0,
		"internal_slot_max_empty_rank": 0,
		"slot_payload_volume_rank": 0,
	}


func _has_stat(entries: Array, label_fragment: String, key: String) -> bool:
	for entry in entries:
		if not (entry is Dictionary):
			continue
		var item: Dictionary = entry
		if String(item.get("label", "")).find(label_fragment) >= 0 and String(item.get("key", key)) == key:
			return true
		if String(item.get("label", "")).find(label_fragment) >= 0 and absf(float(item.get("value", -999.0)) - float(_base_stats().get(key, -998.0))) < 0.01:
			return true
	return false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var current := _base_stats()
	var preview := current.duplicate(true)
	preview["mass"] = 48.0
	preview["body_move_speed"] = 1.6
	preview["boost_speed"] = 2.7
	preview["thruster_acceleration"] = 0.8
	var entries: Array = main._editor_stats_entries(current, preview, {"cost": 0, "units": 0}, {"cost": 0, "units": 0}, {})
	if not _has_stat(entries, "机体速度", "body_move_speed"):
		_fail("Dashboard is missing body movement speed.")
	if not _has_stat(entries, "Boost速度", "boost_speed"):
		_fail("Dashboard is missing boost speed.")
	if not _has_stat(entries, "推进加速", "thruster_acceleration"):
		_fail("Dashboard is missing thruster acceleration.")
	if not _has_stat(entries, "Boost持续", "boost_duration"):
		_fail("Dashboard is missing boost duration.")
	if not _has_stat(entries, "推进器总动量", "thruster_momentum"):
		_fail("Dashboard is missing total thruster momentum.")
	if not _has_stat(entries, "Boost总动量", "boost_momentum"):
		_fail("Dashboard is missing total boost momentum.")
	if not _has_stat(entries, "转向角速", "turn_speed"):
		_fail("Dashboard is missing turn angular speed.")
	if not _has_stat(entries, "转向加速", "turn_acceleration"):
		_fail("Dashboard is missing turn angular acceleration.")
	print("EDITOR_DASHBOARD_SPEED_PROBE entries=%d body=%.2f boost=%.2f" % [entries.size(), float(current["body_move_speed"]), float(current["boost_speed"])])
	quit()
