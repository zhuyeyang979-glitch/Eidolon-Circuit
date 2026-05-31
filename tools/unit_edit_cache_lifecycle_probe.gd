extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	for i in range(80):
		main.editor_catalog_raw_cache["raw_%d" % i] = []
		main.editor_catalog_entries_cache["entries_%d" % i] = []
		main.editor_catalog_sort_keys_cache["sort_%d" % i] = []
		main.editor_catalog_page_model_cache["page_%d" % i] = []
	for i in range(220):
		main.editor_catalog_card_model_cache["card_%d" % i] = {}
		main.editor_load_entry_stats_cache["load_%d" % i] = {}
	for i in range(12):
		main.runtime_catalog_cache["runtime_%d" % i] = []
		main.editor_catalog_card_signature_cache[i] = "sig_%d" % i
		main.editor_torso_detail_template_cache["torso_%d" % i] = {}
		main.teamedit_placement_template_cache["drop_%d" % i] = {}
		main.teamedit_placement_template_index_cache["drop_index_%d" % i] = "drop_%d" % i
	main.editor_current_stats_cache_key = "stats"
	main.editor_current_stats_cache = {"cost": 1}
	main.editor_board_snapshot_cache = {"nodes": []}
	main.editor_board_snapshot_cache_key = "board"
	main.editor_board_base_snapshot_cache = {"nodes": []}
	main.editor_board_base_snapshot_cache_key = "board_base"
	MainScene.PartPreviewTextureCache.textures["preview"] = null
	MainScene.PartPreviewTextureCache.lru_order.append("preview")
	MainScene.PartPreviewTextureCache.pending_requests["pending"] = {}
	MainScene.PartPreviewTextureCache.pending_order.append("pending")
	MainScene.PartPreviewTextureCache.active_request = {"key": "active"}
	MainScene.PartPreviewTextureCache.last_captured_keys.append("preview")
	MainScene.CatalogCardBodyTextureCache.textures["catalog"] = null
	MainScene.CatalogCardBodyTextureCache.lru_order.append("catalog")
	MainScene.CatalogCardBodyTextureCache.pending_requests["pending"] = {}
	MainScene.CatalogCardBodyTextureCache.pending_order.append("pending")
	MainScene.CatalogCardBodyTextureCache.active_request = {"key": "active"}
	MainScene.CatalogCardBodyTextureCache.last_captured_keys.append("catalog")
	main.editor_pending_module_binding = {"payload_index": 1}
	main.editor_bound_module_tryout = {"timer": 1.0}
	main.editor_dragging_node_index = 2
	main.editor_pose_dragging = true
	main.game_state = main.STATE_EDITOR
	main._exit_page(main.STATE_EDITOR, main.STATE_MENU, "probe")
	var snapshot: Dictionary = main._ui_lifecycle_snapshot()
	if not main.editor_pending_module_binding.is_empty() or not main.editor_bound_module_tryout.is_empty():
		_fail("Unit edit binding/tryout state survived cleanup.")
	if main.editor_dragging_node_index != -1 or main.editor_pose_dragging:
		_fail("Unit edit drag state survived cleanup.")
	if int(snapshot.get("editor_catalog_cache", -1)) != 0 or int(snapshot.get("editor_load_stats_cache", -1)) != 0 or int(snapshot.get("runtime_catalog_cache", -1)) != 0:
		_fail("Unit edit page caches survived cleanup: %s" % str(snapshot))
	if not main.editor_catalog_sort_keys_cache.is_empty() or not main.editor_catalog_card_signature_cache.is_empty():
		_fail("Unit edit catalog side caches survived cleanup.")
	if not main.editor_torso_detail_template_cache.is_empty() or not main.teamedit_placement_template_cache.is_empty() or not main.teamedit_placement_template_index_cache.is_empty():
		_fail("Unit edit template caches survived cleanup.")
	if not main.editor_current_stats_cache.is_empty() or main.editor_current_stats_cache_key != "":
		_fail("Unit edit current stats cache survived cleanup.")
	if not main.editor_board_snapshot_cache.is_empty() or not main.editor_board_base_snapshot_cache.is_empty():
		_fail("Unit edit board snapshot cache survived cleanup.")
	if int(snapshot.get("preview_texture_cache", -1)) != 0 or int(snapshot.get("preview_texture_pending", -1)) != 0:
		_fail("Part preview texture cache survived cleanup: %s" % str(snapshot))
	if int(snapshot.get("catalog_body_cache", -1)) != 0 or int(snapshot.get("catalog_body_pending", -1)) != 0:
		_fail("Catalog body texture cache survived cleanup: %s" % str(snapshot))
	if bool(snapshot.get("preview_renderer_alive", true)) or bool(snapshot.get("catalog_renderer_alive", true)):
		_fail("Preview renderer survived unit edit exit: %s" % str(snapshot))
	print("UNIT_EDIT_CACHE_LIFECYCLE_PROBE ok catalog=%d load=%d preview=%d body=%d" % [
		int(snapshot.get("editor_catalog_cache", 0)),
		int(snapshot.get("editor_load_stats_cache", 0)),
		int(snapshot.get("preview_texture_cache", 0)),
		int(snapshot.get("catalog_body_cache", 0)),
	])
	quit(0)
