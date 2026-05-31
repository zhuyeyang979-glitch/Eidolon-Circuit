extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _filter_index(main, key: String) -> int:
	var options: Array = main._part_filter_options_for_group("software")
	for i in range(options.size()):
		if options[i] is Dictionary and String(Dictionary(options[i]).get("key", "")) == key:
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_panel_mode = "parts"
	main._select_editor_part_group("software")
	main._select_editor_part_filter(_filter_index(main, "module"))
	var baseline_visual := int(main.editor_visual_refresh_count)
	var baseline_stats := int(main.editor_compute_unit_stats_count)
	var baseline_gpu := int(main.gpu_geometry_query_submit_count)
	var baseline_revision := String(main.editor_catalog_buttons_revision_key)
	var ranged_index := _filter_index(main, "module_ranged")
	if ranged_index < 0:
		_fail("Missing ranged module filter.")
		return
	main._select_editor_part_filter(ranged_index)
	var ranged_revision := String(main.editor_catalog_buttons_revision_key)
	if ranged_revision == baseline_revision:
		_fail("Module category switch did not refresh catalog revision.")
		return
	if int(main.gpu_geometry_query_submit_count) != baseline_gpu:
		_fail("Module category switch submitted GPU geometry query.")
		return
	if int(main.editor_visual_refresh_count) != baseline_visual:
		_fail("Module category switch refreshed board visual path.")
		return
	if int(main.editor_compute_unit_stats_count) - baseline_stats > 1:
		_fail("Module category switch recomputed stats too many times: %d" % (int(main.editor_compute_unit_stats_count) - baseline_stats))
		return
	print("MODULE_CATEGORY_CACHE_PROBE ok revision_changed=%s stats_delta=%d" % [str(ranged_revision != baseline_revision), int(main.editor_compute_unit_stats_count) - baseline_stats])
	quit(0)
