extends SceneTree

const MainScene := preload("res://scripts/main.gd")


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
	view.set_allocation_data({
		"title": "动力预算",
		"subtitle": "排版测试 / 池 100 = 1.00",
		"engine_name": "Probe Engine",
		"torso_name": "Probe Torso",
		"engine_output": 100.0,
		"used_ratio": 0.52,
		"cooling_pool": 32.0,
		"engine_heat_load": 1.2,
		"allocation_heat_used": 1.0,
		"heat_used": 2.2,
		"heat_ratio": 0.07,
		"thermal_margin": 29.8,
		"entries": [
			{"id": "limb:0:1", "kind": "limb", "label": "长名称肢体动力输入测试", "line": "行动模块 10-80", "ratio": 0.22, "momentum": 22.0, "min_momentum": 10.0, "max_momentum": 80.0, "duration_label": "行动模块 10-80  时长 0.42s", "heat_coeff": 0.018, "heat_load": 0.4, "heat_ratio": 0.0125, "heat_label": "热 0.4 / 散热 1%", "color": Color(0.38, 0.9, 1.0, 1.0)},
			{"id": "booster_drive:0", "kind": "booster_drive", "label": "推进器推进分配测试", "line": "普通移动/转向 30-90", "ratio": 0.30, "momentum": 30.0, "min_momentum": 30.0, "max_momentum": 90.0, "boost_peak_ratio": 0.46, "boost_label": "Boost刹车 +16 / 峰值 46", "heat_coeff": 0.016, "heat_load": 0.5, "heat_ratio": 0.015, "heat_label": "热 0.5 / 散热 2%", "color": Color(1.0, 0.52, 0.18, 1.0)},
		],
		"segments": [],
		"allocation_groups": [],
	}, "zh")
	var side: Rect2 = view._side_rect()
	if side.size.x < 250.0:
		_fail("Detailed power panel side list should be wide enough for value inputs and labels.")
	var row0: Rect2 = view._entry_row_rect(0)
	var row1: Rect2 = view._entry_row_rect(1)
	if row0.size.y < 70.0 or row1.position.y - row0.position.y < 80.0:
		_fail("Detailed power panel rows should have relaxed height and spacing.")
	var edit_rect: Rect2 = view._entry_value_edit_rect(0)
	var slider_rect: Rect2 = view._entry_slider_rect(0)
	var heat_rect: Rect2 = view._entry_heat_bar_rect(0)
	if edit_rect.intersects(slider_rect):
		_fail("Numeric input should not overlap the limb slider.")
	if heat_rect.intersects(slider_rect):
		_fail("Heat bar should not overlap the drive slider.")
	if heat_rect.intersects(edit_rect):
		_fail("Heat bar should not overlap the numeric input.")
	if heat_rect.position.y <= slider_rect.end.y:
		_fail("Heat bar should sit below the drive slider.")
	if slider_rect.size.x < 120.0:
		_fail("Limb slider should remain usable after reserving numeric input space.")
	if row0.size.y < 104.0 or row1.position.y - row0.position.y < 112.0:
		_fail("Rows should have enough vertical room for drive, heat, value, and duration text.")
	print("POWER_ALLOCATION_PANEL_TYPOGRAPHY_PROBE ok side=%.1f row=%.1f stride=%.1f" % [side.size.x, row0.size.y, row1.position.y - row0.position.y])
	quit()
