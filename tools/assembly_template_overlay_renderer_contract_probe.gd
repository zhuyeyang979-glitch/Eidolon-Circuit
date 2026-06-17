extends SceneTree

const RENDERER_PATH := "res://scripts/views/editor/assembly_template_overlay_renderer.gd"

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))


func _init() -> void:
	if load(RENDERER_PATH) == null:
		_fail("Missing AssemblyTemplateOverlayRenderer script.")
		quit(1)
		return
	var board_source := _source("res://scripts/views/editor/assembly_board_view.gd")
	var renderer_source := _source(RENDERER_PATH)
	_assert(renderer_source.find("class_name AssemblyTemplateOverlayRenderer") >= 0, "Renderer should expose a stable class_name.")
	_assert(renderer_source.find("func draw_overlay") >= 0, "Renderer should own the public overlay drawing entrypoint.")
	_assert(renderer_source.find("func _draw_schema") >= 0, "Renderer should own assembly template schema drawing.")
	_assert(renderer_source.find("func _draw_slot") >= 0, "Renderer should own assembly template slot drawing.")
	_assert(renderer_source.find("func _draw_warnings") >= 0, "Renderer should own assembly template warning drawing.")
	_assert(board_source.find("AssemblyTemplateOverlayRenderer") >= 0, "AssemblyBoardView should preload the overlay renderer.")
	_assert(board_source.find("assembly_template_overlay_renderer.draw_overlay") >= 0, "AssemblyBoardView should delegate overlay drawing.")
	for forbidden in [
		"func _assembly_template_status_color",
		"func _assembly_template_trim",
		"func _draw_assembly_template_schema",
		"func _draw_assembly_template_slot",
	]:
		_assert(board_source.find(forbidden) < 0, "AssemblyBoardView should not keep renderer helper %s." % forbidden)
	if failed:
		quit(1)
		return
	print("ASSEMBLY_TEMPLATE_OVERLAY_RENDERER_CONTRACT_PROBE ok")
	quit(0)
