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
	var blank_bp: Dictionary = main._editor_current_blueprint()
	var blank_stats: Dictionary = main._editor_current_stats()
	var summary_before: Dictionary = main._team_summary(1)
	var blank_nodes := Array(Dictionary(blank_bp.get("custom_topology", {})).get("nodes", [])).size()
	if String(main.editor_canvas_mode) != "blank":
		_fail("TeamEdit did not open in blank working-canvas mode.")
	if blank_nodes != 0 or int(blank_stats.get("cost", -1)) != 0:
		_fail("Default blank canvas is not empty or not zero-cost.")
	if main.editor_roster_slot_buttons.size() < 5:
		_fail("Roster overview page buttons were not created.")
	main._hover_editor_roster_overview_slot(0)
	if main.editor_unit_hover_view == null or not main.editor_unit_hover_view.visible:
		_fail("Roster overview hover did not show empty-slot detail preview.")
	main._select_editor_roster_overview_slot(0)
	if String(main.editor_canvas_mode) != "blank":
		_fail("Clicking an empty roster overview slot should keep the blank working canvas active.")
	var roster_stats: Dictionary = main._editor_current_stats()
	if int(roster_stats.get("cost", -1)) != 0:
		_fail("Empty roster slot selection did not preserve zero-cost canvas.")
	main._start_blank_topology()
	var summary_after: Dictionary = main._team_summary(1)
	if int(summary_after.get("cost", -1)) != int(summary_before.get("cost", -2)):
		_fail("Starting a blank work canvas mutated the saved ten-unit roster cost.")
	print("EDITOR_ROSTER_OVERVIEW_PROBE blank_cost=%d team_cost=%d roster_cost=%d buttons=%d" % [
		int(blank_stats.get("cost", -1)),
		int(summary_before.get("cost", -1)),
		int(roster_stats.get("cost", -1)),
		main.editor_roster_slot_buttons.size(),
	])
	quit()
