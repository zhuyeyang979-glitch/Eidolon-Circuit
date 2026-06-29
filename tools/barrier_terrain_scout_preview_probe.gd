extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"func _barrier_terrain_scout_preview_lines",
		"_barrier_terrain_editor_preview(unit_bp",
		"TERRAIN PREVIEW",
		"地形预览",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing scout terrain preview token: %s" % token)
	if not failures.is_empty():
		_finish()
		return

	var main = MainScene.new()
	root.add_child(main)
	await process_frame
	main.ai_battle_seat = 1
	main._show_scout(MainScene.MODE_AI, true)

	var panel_index := main._component_index_by_exact_name("barrier", "muscle", "VAULT DIVIDEND BULKHEAD")
	if panel_index < 0:
		_fail("Missing barrier panel fixture for scout terrain preview.")
		_finish()
		return
	var terrain_policy := {
		"attach_kinds": ["wall"],
		"anchor_support": "barrier_panel",
		"inherit_orientation": true,
	}
	var target_bp: Dictionary = main._blank_barrier_blueprint("Scout Terrain Barrier")
	target_bp["muscle"] = panel_index
	target_bp["blank_canvas"] = false
	target_bp["barrier_tiles"] = [
		{
			"tile_id": "scout-preview-tile",
			"pos": Vector2(0.5, 0.5),
			"muscle": panel_index,
			"terrain_policy": terrain_policy.duplicate(true),
		},
	]
	var p2_roster := {"hero": [], "puppet": [], "barrier": [target_bp.duplicate(true)]}
	main.blueprints[2] = p2_roster
	main.scout_sortie_player_id = 1
	main.scout_selected_player_id = 2
	main.scout_selected_entry = {"role": "barrier", "index": 0}
	var before_blueprint := str(main.blueprints[2]["barrier"][0])
	var before_snapshot := str(main._battle_terrain_runtime_snapshot())

	main._update_scout_ui()

	if not _expect(main.scout_detail_view != null, "Scout detail view should exist after opening scout UI."):
		_finish()
		return
	var detail_text := String(main.scout_detail_view.detail_text)
	if not _expect(String(main.scout_detail_view.entry.get("role", "")) == "barrier", "Scout detail should keep the selected barrier entry: %s" % str(main.scout_detail_view.entry)):
		_finish()
		return
	if not _expect(detail_text.contains("TERRAIN PREVIEW") or detail_text.contains("地形预览"), "Scout detail should surface terrain preview text: %s" % detail_text):
		_finish()
		return
	if not _expect(detail_text.contains("mobius_default_arena"), "Scout terrain preview should identify the arena: %s" % detail_text):
		_finish()
		return
	if not _expect(detail_text.contains("attach") and detail_text.contains("mobius_mid_cover_north"), "Scout terrain preview should identify the attached terrain feature: %s" % detail_text):
		_finish()
		return
	if not _expect(detail_text.contains("attach_to_terrain") and detail_text.contains("inherit_terrain_orientation"), "Scout terrain preview should list deployment intents: %s" % detail_text):
		_finish()
		return
	if not _expect(str(main.blueprints[2]["barrier"][0]) == before_blueprint, "Scout terrain preview should not mutate the roster blueprint."):
		_finish()
		return
	if not _expect(str(main._battle_terrain_runtime_snapshot()) == before_snapshot, "Scout terrain preview should not mutate the arena terrain snapshot."):
		_finish()
		return

	main.queue_free()
	_finish()


func _finish() -> void:
	if not failures.is_empty():
		print("BARRIER_TERRAIN_SCOUT_PREVIEW_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BARRIER_TERRAIN_SCOUT_PREVIEW_PROBE ok")
	quit(0)
