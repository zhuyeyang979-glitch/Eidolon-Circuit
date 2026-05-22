extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_panel_mode = "parts"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	main.editor_property_write_count = 0
	main.editor_property_noop_count = 0
	main._update_editor_ui(true)
	var writes_after_first := int(main.editor_property_write_count)
	var noops_after_first := int(main.editor_property_noop_count)
	main._update_editor_ui(true)
	var repeated_writes := int(main.editor_property_write_count) - writes_after_first
	var repeated_noops := int(main.editor_property_noop_count) - noops_after_first
	if repeated_writes > 32:
		_fail("Repeated identical TeamEdit update wrote too many guarded properties: %d" % repeated_writes)
		return
	if repeated_noops <= repeated_writes:
		_fail("Repeated identical TeamEdit update did not mostly no-op guarded properties: write=%d noop=%d" % [repeated_writes, repeated_noops])
		return
	print("EDITOR_PROPERTY_WRITE_BUDGET_PROBE ok first=%d repeat_write=%d repeat_noop=%d" % [writes_after_first, repeated_writes, repeated_noops])
	quit(0)
