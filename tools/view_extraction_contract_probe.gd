extends SceneTree

const VIEW_PATH := "res://scripts/views/backdrop_view.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BackdropViewScript := preload("res://scripts/views/backdrop_view.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(VIEW_PATH):
		_fail("Missing extracted BackdropView script.")
	var view_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(VIEW_PATH))
	if view_source.find("class_name BackdropView") < 0:
		_fail("Extracted BackdropView should publish the legacy class name.")
	for required in ["set_mode", "set_background_texture", "draw_texture_rect", "draw_polyline"]:
		if view_source.find(required) < 0:
			_fail("Extracted BackdropView is missing behavior token: %s" % required)
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	if main_source.find("preload(\"res://scripts/views/backdrop_view.gd\")") < 0:
		_fail("main.gd should preload the extracted BackdropView.")
	if main_source.find("\nclass BackdropView:") >= 0:
		_fail("main.gd should not keep the inline BackdropView class.")
	var backdrop = BackdropViewScript.new()
	if not (backdrop is Control):
		_fail("Extracted BackdropView should instantiate as a Control.")
	backdrop.size = Vector2(320.0, 180.0)
	backdrop.set_mode("battle")
	backdrop.set_background_texture(null)
	if backdrop.mode != "battle":
		_fail("BackdropView.set_mode should preserve legacy mode state.")
	backdrop.free()
	print("VIEW_EXTRACTION_CONTRACT_PROBE ok path=%s" % VIEW_PATH)
	quit(0)
