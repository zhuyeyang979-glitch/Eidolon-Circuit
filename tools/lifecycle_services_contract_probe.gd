extends SceneTree

const LoadingLifecycleService := preload("res://scripts/services/loading_lifecycle_service.gd")
const UILifecycleService := preload("res://scripts/services/ui_lifecycle_service.gd")
const LoadingTask := preload("res://scripts/services/loading_task.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var cache := {"a": 1, "b": 2, "c": 3}
	var removed := UILifecycleService.trim_dictionary_cache(cache, 1)
	if removed != 2 or cache.size() != 1:
		_fail("UILifecycleService did not trim dictionary cache.")
		return
	var root_node := Control.new()
	var child_node := Control.new()
	root_node.add_child(child_node)
	if UILifecycleService.node_descendant_count(root_node) != 1 or UILifecycleService.visible_control_count(root_node) != 2:
		_fail("UILifecycleService node/control counting contract failed.")
		return
	root_node.queue_free()
	var visibility_plan := UILifecycleService.editor_panel_visibility_plan("parts", "team", true, false, true, "terminal_weapon", "ammo", 2)
	if String(visibility_plan.get("load_mode", "")) != "unit":
		_fail("UILifecycleService should normalize legacy team load mode.")
		return
	if not bool(visibility_plan.get("parts_visible", false)) or bool(visibility_plan.get("load_visible", false)):
		_fail("UILifecycleService panel visibility mode contract failed.")
		return
	if not bool(visibility_plan.get("custom_board_enabled", false)) or not bool(visibility_plan.get("ammo_slider_visible", false)):
		_fail("UILifecycleService editor board/slider visibility contract failed.")
		return
	if not bool(visibility_plan.get("unit_page_actions_enabled", false)):
		_fail("UILifecycleService should enable unit paging for multi-unit rosters.")
		return
	if not Array(visibility_plan.get("canvas_action_keys", [])).has("restore_suggested_connection"):
		_fail("UILifecycleService should preserve canvas action key ordering payload.")
		return
	var barrier_visibility_plan := UILifecycleService.editor_panel_visibility_plan("load", "unit", true, true, true, "all", "all", 1)
	if bool(barrier_visibility_plan.get("custom_board_enabled", true)):
		_fail("UILifecycleService should disable custom topology board on screen barriers.")
		return
	if not bool(barrier_visibility_plan.get("template_visible", false)) or bool(barrier_visibility_plan.get("unit_page_actions_enabled", true)):
		_fail("UILifecycleService load panel visibility contract failed.")
		return

	var task := LoadingTask.create("idle", "Idle", 1.0, Callable(), LoadingTask.PHASE_IDLE, false, true)
	var prepared := LoadingLifecycleService.prepare_task(task, "editor", 4)
	if prepared.target_page != "editor" or prepared.generation_id != 4:
		_fail("LoadingLifecycleService did not stamp target/generation.")
		return
	var queued := LoadingLifecycleService.queue_deferred_idle_tasks([], [prepared, prepared.to_dictionary()], "editor", 4, "editor")
	if Array(queued.get("tasks", [])).size() != 1 or int(queued.get("deduped", 0)) != 1:
		_fail("LoadingLifecycleService did not dedupe deferred idle tasks.")
		return
	var pruned := LoadingLifecycleService.prune_idle_tasks(Array(queued.get("tasks", [])), "menu", 5, "editor")
	if not Array(pruned.get("tasks", [])).is_empty() or int(pruned.get("cancelled", 0)) != 1:
		_fail("LoadingLifecycleService did not cancel stale target tasks.")
		return

	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/main.gd"))
	for token in [
		"LoadingLifecycleService.queue_deferred_idle_tasks",
		"LoadingLifecycleService.prune_idle_tasks",
		"UILifecycleService.layer_snapshot",
		"UILifecycleService.trim_dictionary_cache",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate lifecycle glue to service token: %s" % token)
			return
	print("LIFECYCLE_SERVICES_CONTRACT_PROBE ok")
	quit(0)
