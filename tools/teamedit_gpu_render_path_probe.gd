extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _function_block(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + 1)
	var indented_next := source.find("\n\tfunc ", start + 1)
	if indented_next >= 0 and (next < 0 or indented_next < next):
		next = indented_next
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var fighter_source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	if main_source.is_empty() or fighter_source.is_empty():
		_fail("Unable to read main.gd or fighter.gd.")
	if not main_source.contains("class PartPreviewIconView"):
		_fail("Retained preview surface missing.")
	if not main_source.contains("class AssemblyBoardRenderLayer") or not main_source.contains("retained_component_items"):
		_fail("AssemblyBoard retained render layer missing.")
	var board_draw := _function_block(main_source.substr(main_source.find("class AssemblyBoardView")), "func _draw() -> void:")
	if board_draw.contains("_draw_custom_board()"):
		_fail("Custom TeamEdit board still uses monolithic _draw_custom_board in normal _draw path.")
	if not main_source.contains("collision_broadphase_skip_count") or not main_source.contains("collision_polygon_precise_check_count"):
		_fail("Collision broadphase instrumentation missing.")
	var geometry_signature := _function_block(fighter_source, "func _runtime_geometry_signature")
	if geometry_signature.is_empty():
		_fail("_runtime_geometry_signature missing.")
	if geometry_signature.contains("Engine.get_process_frames"):
		_fail("Runtime geometry cache key still invalidates every frame.")
	if not fighter_source.contains("runtime_geometry_cache_segments_by_key") or not fighter_source.contains("runtime_geometry_cache_colliders"):
		_fail("Fighter runtime geometry caches missing.")
	var visual_refresh := _function_block(fighter_source, "func _refresh_part_visuals")
	if visual_refresh.is_empty() or not visual_refresh.contains("_runtime_visual_redraw_signature"):
		_fail("Runtime visuals are not guarded by a redraw signature.")
	print("TEAMEDIT_GPU_RENDER_PATH_PROBE ok")
	quit(0)
