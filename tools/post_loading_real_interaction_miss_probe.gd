extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _drain_loading(main, max_ticks: int = 220) -> void:
	for _i in range(max_ticks):
		if String(main.game_state) != MainScene.STATE_LOADING:
			return
		main.tick_loading_tasks(0.016, main.loading_task_budget_usec)
		main._tick_post_loading_idle_tasks(0.016)
	_fail("Loading did not complete before the first-interaction probe.")


func _find_torso_index(main) -> int:
	for i in range(MainScene.COMMON_CATALOG["muscle"].size()):
		var part: Dictionary = MainScene.COMMON_CATALOG["muscle"][i]
		if main._component_is_torso(part):
			return i
	return -1


func _first_new_miss(main, from_index: int) -> Array:
	var result: Array = []
	for i in range(from_index, main.post_loading_miss_log.size()):
		var entry = main.post_loading_miss_log[i]
		if entry is Dictionary and String(Dictionary(entry).get("detail", "")).begins_with("delta:"):
			result.append(entry)
	return result


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = true
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	var torso_index := _find_torso_index(main)
	if torso_index < 0:
		_fail("No torso part found for first-interaction miss probe.")
		return
	var page_size := maxi(1, main.editor_catalog_buttons.size())
	main.editor_catalog_page = int(torso_index / page_size)
	main._show_editor()
	_drain_loading(main)
	if String(main.game_state) != MainScene.STATE_EDITOR:
		_fail("Loading did not enter TeamEdit.")
		return
	var log_start: int = main.post_loading_miss_log.size()
	var miss_start := int(main.post_loading_miss_count)
	main._drop_catalog_part_on_board("muscle", torso_index, Vector2(520.0, 304.0))
	var torso_node: int = main.editor_topology_node_index
	main._record_post_loading_interaction("probe:first_drop_torso")
	if torso_node < 0:
		_fail("Could not place torso during first-interaction probe.")
		return
	main._open_editor_torso_detail(torso_node)
	main._record_post_loading_interaction("probe:first_open_torso_detail")
	var new_misses := _first_new_miss(main, log_start)
	if not new_misses.is_empty():
		_fail("First real TeamEdit interactions still recorded post-loading misses: %s" % str(new_misses))
		return
	print("POST_LOADING_REAL_INTERACTION_MISS_PROBE misses=%d delta=%d log=%s" % [
		new_misses.size(),
		int(main.post_loading_miss_count) - miss_start,
		str(new_misses),
	])
	quit(0)
