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
		"mass": 12,
		"speed": 1.0,
		"turn_speed": 1.0,
		"weakest_joint_momentum_capacity": 0,
		"max_joint_output_momentum": 0,
		"worst_joint_momentum": 0,
		"heat_capacity": 100,
		"data_security": 1.0,
		"internal_slot_max_installed_rank": 0,
		"internal_slot_max_empty_rank": 0,
		"slot_payload_volume_rank": 0,
	}


func _find_balance(entries: Array, label_fragment: String) -> Dictionary:
	for entry in entries:
		if entry is Dictionary and String(Dictionary(entry).get("kind", "")) == "balance" and String(Dictionary(entry).get("label", "")).find(label_fragment) >= 0:
			return Dictionary(entry)
	return {}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var current := _base_stats()
	current["engine_power"] = 120.0
	current["required_power"] = 80.0
	current["cooling"] = 56.0
	current["idle_heat_load"] = 34.0
	var preview := current.duplicate(true)
	preview["engine_power"] = 70.0
	preview["required_power"] = 96.0
	preview["cooling"] = 24.0
	preview["idle_heat_load"] = 44.0
	var entries: Array = main._editor_stats_entries(current, preview, {"cost": 0, "units": 0}, {"cost": 0, "units": 0}, {"power": false, "thermal": false})
	var power := _find_balance(entries, "动力")
	if power.is_empty():
		_fail("Power balance entry missing.")
	if bool(power.get("illegal", true)):
		_fail("Power balance should be legal when supply exceeds demand.")
	if absf(float(power.get("supply", 0.0)) - 120.0) > 0.01 or absf(float(power.get("demand", 0.0)) - 80.0) > 0.01:
		_fail("Power balance did not expose supply/demand values.")
	if absf(float(power.get("preview_supply", 0.0)) - 70.0) > 0.01 or absf(float(power.get("preview_demand", 0.0)) - 96.0) > 0.01:
		_fail("Power balance did not expose preview supply/demand.")
	var thermal := _find_balance(entries, "热")
	if thermal.is_empty():
		_fail("Thermal balance entry missing.")
	if bool(thermal.get("illegal", true)):
		_fail("Thermal balance should be legal when cooling exceeds idle heat.")
	current["engine_power"] = 40.0
	current["required_power"] = 88.0
	current["cooling"] = 18.0
	current["idle_heat_load"] = 32.0
	entries = main._editor_stats_entries(current, current, {"cost": 0, "units": 0}, {"cost": 0, "units": 0}, {"power": true, "thermal": true})
	power = _find_balance(entries, "动力")
	thermal = _find_balance(entries, "热")
	if not bool(power.get("illegal", false)):
		_fail("Power shortage should red-mark the balance entry.")
	if not bool(thermal.get("illegal", false)):
		_fail("Thermal shortage should red-mark the balance entry.")
	print("EDITOR_BALANCE_STAT_PROBE power_margin=%.0f thermal_margin=%.0f" % [float(power.get("supply", 0.0)) - float(power.get("demand", 0.0)), float(thermal.get("supply", 0.0)) - float(thermal.get("demand", 0.0))])
	quit()
