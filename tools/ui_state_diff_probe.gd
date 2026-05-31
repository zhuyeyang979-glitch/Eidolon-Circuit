extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var button := Button.new()
	button.text = ""
	root.add_child(button)
	main.editor_property_write_count = 0
	main.editor_property_noop_count = 0
	var controls := {"action": button}
	var state := {"action": {"text": "APPLY", "visible": true, "disabled": false, "modulate": Color(0.35, 0.95, 1.0, 1.0)}}
	main._apply_ui_state(controls, state)
	var writes_after_first := int(main.editor_property_write_count)
	main._apply_ui_state(controls, state)
	var repeated_writes := int(main.editor_property_write_count) - writes_after_first
	var repeated_noops := int(main.editor_property_noop_count)
	if writes_after_first <= 0:
		_fail("First UI state apply did not write any changed properties.")
		return
	if repeated_writes != 0:
		_fail("Repeated identical UI state still wrote properties: %d" % repeated_writes)
		return
	if button.text != "APPLY" or button.disabled:
		_fail("UI state did not leave the control in the requested state.")
		return
	print("UI_STATE_DIFF_PROBE ok first_writes=%d noops=%d" % [writes_after_first, repeated_noops])
	quit(0)
