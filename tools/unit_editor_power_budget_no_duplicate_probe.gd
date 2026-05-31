extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _control_rect(control: Control) -> Rect2:
	return Rect2(control.position, control.size)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.flush_editor_dirty(8000)
	if main.editor_power_topbar_view != null:
		_fail("UnitEditorPowerTopbar should not be instantiated; the dock is the visible power-budget entry.")
	if main.editor_engine_allocation_button != null and main.editor_engine_allocation_button.visible:
		_fail("Legacy DashboardPowerAllocationButton is still visible.")
	if main.editor_engine_allocation_summary_label != null and main.editor_engine_allocation_summary_label.visible:
		_fail("Legacy DashboardPowerAllocationSummary is still visible.")
	if main.editor_stats_rail_view == null:
		_fail("Left dashboard is missing.")
	if main.editor_power_dock_view == null:
		_fail("Power allocation dock is missing.")
	if not main.editor_power_dock_view.visible:
		_fail("Power allocation dock should be visible.")
	var rail_rect := _control_rect(main.editor_stats_rail_view)
	var dock_rect := _control_rect(main.editor_power_dock_view)
	if rail_rect.intersects(dock_rect):
		_fail("Power allocation dock overlaps the left dashboard: rail=%s dock=%s" % [str(rail_rect), str(dock_rect)])
	if dock_rect.position.y > 32.0:
		_fail("Power allocation dock was not moved into the former topbar area: %s" % str(dock_rect))
	print("UNIT_EDITOR_POWER_BUDGET_NO_DUPLICATE_PROBE ok topbar_hidden=true dock=%s rail=%s" % [
		str(dock_rect),
		str(rail_rect),
	])
	quit()
