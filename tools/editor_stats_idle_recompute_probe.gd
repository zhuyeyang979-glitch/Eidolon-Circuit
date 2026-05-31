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
	main._update_editor_ui(true)
	var updates_before := int(main.editor_update_ui_count)
	var deferred_before := int(main.editor_deferred_full_refresh_request_count)
	main._refresh_editor_dashboard_after_allocation(true)
	if int(main.editor_deferred_full_refresh_request_count) <= deferred_before:
		_fail("Full allocation refresh did not enter deferred path.")
		return
	if int(main.editor_update_ui_count) != updates_before:
		_fail("Full allocation refresh still performed synchronous _update_editor_ui.")
		return
	if int(main.editor_allocation_light_refresh_count) <= 0:
		_fail("Deferred allocation refresh did not keep lightweight dashboard values live.")
		return
	print("EDITOR_STATS_IDLE_RECOMPUTE_PROBE ok deferred=%d light=%d" % [int(main.editor_deferred_full_refresh_request_count), int(main.editor_allocation_light_refresh_count)])
	quit(0)
