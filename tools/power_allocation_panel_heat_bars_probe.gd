extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var changed := false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	var view = main.engine_momentum_allocation_view
	if view == null:
		_fail("Power allocation view is missing.")
	view.size = Vector2(900.0, 600.0)
	view.allocation_changed.connect(func(_entry_id: String, _ratio: float) -> void:
		changed = true
	)
	view.set_allocation_data({
		"title": "动力预算",
		"subtitle": "散热测试 / 池 120 = 1.00",
		"engine_name": "Probe Engine",
		"torso_name": "Probe Torso",
		"engine_output": 120.0,
		"used_ratio": 0.42,
		"cooling_pool": 30.0,
		"engine_heat_load": 1.4,
		"allocation_heat_used": 1.1,
		"heat_used": 2.5,
		"heat_ratio": 2.5 / 30.0,
		"thermal_margin": 27.5,
		"entries": [
			{"id": "limb:0:1", "kind": "limb", "label": "肢体动力", "line": "行动模块 10-90", "ratio": 0.25, "momentum": 30.0, "min_momentum": 10.0, "max_momentum": 90.0, "duration_label": "行动模块 10-90  时长 0.54s", "heat_coeff": 0.018, "heat_load": 0.54, "heat_ratio": 0.018, "heat_label": "热 0.5 / 散热 2%", "color": Color(0.38, 0.9, 1.0, 1.0)},
			{"id": "booster_drive:0", "kind": "booster_drive", "label": "推进器推进", "line": "普通移动/转向 20-80", "ratio": 0.17, "momentum": 20.0, "min_momentum": 20.0, "max_momentum": 80.0, "boost_peak_ratio": 0.30, "boost_label": "Boost刹车 +16 / 峰值 36", "heat_coeff": 0.016, "heat_load": 0.32, "heat_ratio": 0.011, "heat_label": "热 0.3 / 散热 1%", "color": Color(1.0, 0.52, 0.18, 1.0)},
			{"id": "booster_boost_brake:0", "kind": "booster_boost_brake", "label": "推进器Boost峰值", "line": "峰值动力 0-40", "ratio": 0.13, "momentum": 16.0, "min_momentum": 0.0, "max_momentum": 40.0, "heat_coeff": 0.0, "heat_exempt": true, "heat_load": 0.0, "heat_ratio": 0.0, "heat_label": "峰值提示 / 不占常热", "color": Color(1.0, 0.72, 0.22, 1.0)},
		],
		"segments": [],
		"allocation_groups": [],
	}, "zh")
	if float(view.cooling_pool) <= 0.0 or float(view.heat_used) <= 0.0:
		_fail("Detailed panel should expose total cooling pool and heat used.")
	for i in range(view.entries.size()):
		var entry: Dictionary = Dictionary(view.entries[i])
		if bool(entry.get("heat_exempt", false)):
			if float(entry.get("heat_coeff", 0.0)) != 0.0 or float(entry.get("heat_load", 0.0)) != 0.0:
				_fail("Heat-exempt boost peak hint should not expose constant heat.")
		else:
			if float(entry.get("heat_coeff", 0.0)) <= 0.0:
				_fail("Entry missing heat coefficient.")
			if float(entry.get("heat_load", 0.0)) <= 0.0:
				_fail("Entry missing heat load.")
		if String(entry.get("heat_label", "")) == "":
			_fail("Entry missing heat label.")
		var slider_rect: Rect2 = view._entry_slider_rect(i)
		var heat_rect: Rect2 = view._entry_heat_bar_rect(i)
		if heat_rect.intersects(slider_rect):
			_fail("Heat bar should be visually separate from the drive slider.")
		if heat_rect.position.y <= slider_rect.end.y:
			_fail("Heat bar should be below the drive slider.")
	var heat_click := InputEventMouseButton.new()
	heat_click.button_index = MOUSE_BUTTON_LEFT
	heat_click.pressed = true
	heat_click.position = view._entry_heat_bar_rect(0).get_center()
	view._gui_input(heat_click)
	if changed:
		_fail("Read-only heat bar should not emit allocation changes.")
	print("POWER_ALLOCATION_PANEL_HEAT_BARS_PROBE ok heat=%.2f cooling=%.2f" % [float(view.heat_used), float(view.cooling_pool)])
	quit()
