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
	main.editor_pending_module_binding = {"payload_index": 1}
	main.editor_bound_module_tryout = {"timer": 1.0}
	main.editor_dragging_node_index = 2
	main.editor_pose_dragging = true
	main._cleanup_unit_edit_page_runtime()
	var snapshot: Dictionary = main._ui_lifecycle_snapshot()
	if not main.editor_pending_module_binding.is_empty() or not main.editor_bound_module_tryout.is_empty():
		_fail("Unit edit binding/tryout state survived cleanup.")
	if main.editor_dragging_node_index != -1 or main.editor_pose_dragging:
		_fail("Unit edit drag state survived cleanup.")
	if main.editor_catalog_raw_cache.size() > 48 or main.editor_catalog_entries_cache.size() > 48 or main.editor_catalog_page_model_cache.size() > 48:
		_fail("Unit edit catalog caches exceeded lifecycle cap: %s" % str(snapshot))
	if main.editor_catalog_card_model_cache.size() > 192 or main.editor_load_entry_stats_cache.size() > 120:
		_fail("Unit edit card/load caches exceeded lifecycle cap: %s" % str(snapshot))
	print("UNIT_EDIT_CACHE_LIFECYCLE_PROBE ok catalog=%d load=%d" % [
		int(snapshot.get("editor_catalog_cache", 0)),
		int(snapshot.get("editor_load_stats_cache", 0)),
	])
	quit(0)
