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
	main.flush_editor_dirty(8000)
	if main.editor_power_topbar_view != null:
		_fail("UnitEditorPowerTopbarView should not be instantiated.")
	if main.editor_power_dock_view == null or not main.editor_power_dock_view.visible:
		_fail("UnitEditorPowerAllocationDock should be visible.")
	if main.editor_engine_allocation_button != null and main.editor_engine_allocation_button.visible:
		_fail("Legacy DashboardPowerAllocationButton is visible.")
	if main.editor_engine_allocation_summary_label != null and main.editor_engine_allocation_summary_label.visible:
		_fail("Legacy DashboardPowerAllocationSummary is visible.")
	print("UNIT_EDITOR_NO_POWER_TOPBAR_PROBE ok dock_pos=%s" % str(main.editor_power_dock_view.position))
	quit()
