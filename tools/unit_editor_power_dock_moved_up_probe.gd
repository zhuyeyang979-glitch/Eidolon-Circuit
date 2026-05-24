extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _rect(control: Control) -> Rect2:
	return Rect2(control.position, control.size)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.flush_editor_dirty(8000)
	if main.editor_power_dock_view == null:
		_fail("Power dock missing.")
	if main.editor_stats_rail_view == null:
		_fail("Stats rail missing.")
	var dock_rect := _rect(main.editor_power_dock_view)
	var rail_rect := _rect(main.editor_stats_rail_view)
	if dock_rect.position.y > 32.0:
		_fail("Power dock is not in the former topbar band: %s" % str(dock_rect))
	if rail_rect.intersects(dock_rect):
		_fail("Power dock overlaps left dashboard: dock=%s rail=%s" % [str(dock_rect), str(rail_rect)])
	print("UNIT_EDITOR_POWER_DOCK_MOVED_UP_PROBE ok dock=%s rail=%s" % [str(dock_rect), str(rail_rect)])
	quit()
