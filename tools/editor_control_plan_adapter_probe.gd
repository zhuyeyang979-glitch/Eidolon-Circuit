extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _init() -> void:
	var main = MainScene.new()
	var parent := Control.new()
	root.add_child(parent)
	var button := Button.new()
	button.text = "OLD"
	button.tooltip_text = "old tip"
	button.position = Vector2(4.0, 6.0)
	button.size = Vector2(20.0, 10.0)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.z_index = 1
	parent.add_child(button)
	var sibling := Control.new()
	parent.add_child(sibling)
	var button_plan := {
		"visible": false,
		"disabled": true,
		"position": Vector2(40.0, 60.0),
		"size": Vector2(120.0, 32.0),
		"text": "READY",
		"tooltip": "adapter tip",
		"modulate": Color(0.2, 0.7, 0.9, 0.8),
		"mouse_filter": Control.MOUSE_FILTER_IGNORE,
		"z_index": 42,
		"move_to_front": true,
	}
	main._apply_editor_control_plan(button, button_plan)
	_require(not button.visible, "Control plan should apply visibility.")
	_require(button.disabled, "Control plan should apply Button.disabled.")
	_require(button.position == Vector2(40.0, 60.0) and button.size == Vector2(120.0, 32.0), "Control plan should apply geometry.")
	_require(button.text == "READY" and button.tooltip_text == "adapter tip", "Control plan should apply text and tooltip.")
	_require(button.modulate.is_equal_approx(Color(0.2, 0.7, 0.9, 0.8)), "Control plan should apply modulation.")
	_require(button.mouse_filter == Control.MOUSE_FILTER_IGNORE and button.z_index == 42, "Control plan should apply mouse filter and z-index.")
	_require(parent.get_child(parent.get_child_count() - 1) == button, "Control plan should move requested controls to front.")
	var writes_after_first_apply := int(main.editor_property_write_count)
	main._apply_editor_control_plan(button, button_plan)
	_require(int(main.editor_property_write_count) == writes_after_first_apply, "Repeated control plans should not rewrite unchanged properties.")
	_require(int(main.editor_property_noop_count) >= 7, "Repeated control plans should register property no-ops.")
	var slider := HSlider.new()
	slider.min_value = 1.0
	slider.max_value = 5.0
	slider.value = 2.0
	slider.editable = true
	parent.add_child(slider)
	main._apply_editor_control_plan(slider, {"editable": false, "value": 4.0})
	_require(not slider.editable and is_equal_approx(slider.value, 4.0), "Control plan should apply slider editable/value state.")
	var label := Label.new()
	label.text = "KEEP"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	parent.add_child(label)
	main._apply_editor_control_plan(label, {
		"text": "UPDATED",
		"autowrap_mode": TextServer.AUTOWRAP_OFF,
		"clip_text": true,
		"text_overrun_behavior": TextServer.OVERRUN_TRIM_ELLIPSIS,
		"unknown": 99,
	})
	_require(label.text == "UPDATED" and label.visible, "Control plan should ignore absent and unknown properties.")
	_require(label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.clip_text and label.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS, "Control plan should apply Label text layout properties.")
	var writes_after_label_apply := int(main.editor_property_write_count)
	main._apply_editor_control_plan(label, {
		"autowrap_mode": TextServer.AUTOWRAP_OFF,
		"clip_text": true,
		"text_overrun_behavior": TextServer.OVERRUN_TRIM_ELLIPSIS,
	})
	_require(int(main.editor_property_write_count) == writes_after_label_apply, "Repeated Label text layout plans should not rewrite unchanged properties.")
	button.disabled = false
	main._apply_editor_control_plan(button, {"disabled": true, "text": "PRESERVED"}, false)
	_require(not button.disabled and button.text == "PRESERVED", "Control plan should optionally preserve externally managed disabled state.")
	main._apply_editor_control_plan(null, {"visible": false})
	print("EDITOR_CONTROL_PLAN_ADAPTER_PROBE failed=%s writes=%d noops=%d" % [str(failed), int(main.editor_property_write_count), int(main.editor_property_noop_count)])
	main.free()
	quit(1 if failed else 0)
