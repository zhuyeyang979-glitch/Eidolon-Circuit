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
		"func _barrier_terrain_editor_preview",
		"func _barrier_terrain_editor_preview_origin",
		"terrain_preview",
		"_barrier_terrain_interaction_service().barrier_placement_intent",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing barrier terrain editor preview token: %s" % token)
	if not failures.is_empty():
		_finish()
		return

	var main = MainScene.new()
	root.add_child(main)
	await process_frame
	main.editor_role_index = MainScene.ROLE_ORDER.find("barrier")
	main._show_editor()
	main._update_editor_ui(true)

	var snapshot: Dictionary = main._battle_terrain_runtime_snapshot()
	var cover := _feature_by_id(Array(snapshot.get("features", [])), "mobius_mid_cover_north")
	if not _expect(not cover.is_empty(), "Default terrain snapshot should expose north cover."):
		_finish()
		return
	var cover_center: Vector2 = Dictionary(cover.get("collider", {})).get("center", Vector2.ZERO)
	var panel_index := main._component_index_by_exact_name("barrier", "muscle", "VAULT DIVIDEND BULKHEAD")
	if panel_index < 0:
		_fail("Missing barrier panel fixture for terrain editor preview.")
		_finish()
		return

	var unit_bp: Dictionary = main._editor_current_blueprint()
	var tile_policy := {
		"attach_kinds": ["wall"],
		"anchor_support": "barrier_panel",
		"inherit_orientation": true,
	}
	unit_bp["barrier_tiles"] = [{
		"pos": Vector2(0.5, 0.5),
		"muscle": panel_index,
		"terrain_policy": tile_policy.duplicate(true),
	}]
	unit_bp["blank_canvas"] = false
	var before_blueprint := str(unit_bp)
	var preview: Dictionary = main._barrier_terrain_editor_preview(unit_bp, {"preview_origin": cover_center})
	if not _expect(str(unit_bp) == before_blueprint, "Editor terrain preview should not mutate the barrier blueprint."):
		_finish()
		return
	_assert_preview_attach(preview, "direct helper")

	main._refresh_editor_visual_views({}, false)
	var board_snapshot: Dictionary = main.assembly_board_view.board_snapshot
	if not _expect(board_snapshot.has("terrain_preview"), "Barrier board snapshot should consume terrain preview data."):
		_finish()
		return
	_assert_preview_attach(Dictionary(board_snapshot.get("terrain_preview", {})), "board snapshot")
	var tile_snapshot: Dictionary = Dictionary(board_snapshot.get("tile_0", {}))
	if not _expect(tile_snapshot.has("terrain_preview"), "Barrier tile snapshot should include its terrain preview."):
		_finish()
		return
	var tile_preview: Dictionary = Dictionary(tile_snapshot.get("terrain_preview", {}))
	if not _expect(String(Dictionary(tile_preview.get("placement", {})).get("feature_id", "")) == "mobius_mid_cover_north", "Tile snapshot should identify terrain feature: %s" % str(tile_preview)):
		_finish()
		return

	_finish()


func _assert_preview_attach(preview: Dictionary, label: String) -> void:
	if not _expect(String(preview.get("arena_id", "")) == "mobius_default_arena", "%s should preserve arena id: %s" % [label, str(preview)]):
		return
	var tiles: Array = Array(preview.get("tiles", []))
	if not _expect(tiles.size() == 1, "%s should preview one barrier tile: %s" % [label, str(preview)]):
		return
	var tile_preview: Dictionary = Dictionary(tiles[0])
	var placement: Dictionary = Dictionary(tile_preview.get("placement", {}))
	if not _expect(bool(placement.get("allowed", false)), "%s placement should be allowed: %s" % [label, str(placement)]):
		return
	if not _expect(String(placement.get("outcome", "")) == "attach", "%s placement should attach: %s" % [label, str(placement)]):
		return
	if not _expect(String(placement.get("feature_id", "")) == "mobius_mid_cover_north", "%s placement should identify north cover: %s" % [label, str(placement)]):
		return
	var intents: Array = Array(tile_preview.get("deployment_intents", []))
	if not _expect(intents.size() == 2, "%s should preview attach + orientation deployment intents: %s" % [label, str(intents)]):
		return
	if not _expect(String(Dictionary(intents[0]).get("action", "")) == "attach_to_terrain", "%s first deployment intent should attach: %s" % [label, str(intents)]):
		return
	if not _expect(String(Dictionary(intents[1]).get("action", "")) == "inherit_terrain_orientation", "%s second deployment intent should inherit orientation: %s" % [label, str(intents)]):
		return


func _feature_by_id(features: Array, feature_id: String) -> Dictionary:
	for raw_feature in features:
		if raw_feature is Dictionary and String(Dictionary(raw_feature).get("feature_id", "")) == feature_id:
			return Dictionary(raw_feature)
	return {}


func _finish() -> void:
	if not failures.is_empty():
		print("BARRIER_TERRAIN_EDITOR_PREVIEW_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("BARRIER_TERRAIN_EDITOR_PREVIEW_PROBE ok")
	quit(0)
