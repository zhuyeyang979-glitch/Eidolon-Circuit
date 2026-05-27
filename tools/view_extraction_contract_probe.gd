extends SceneTree

const VIEW_PATH := "res://scripts/views/backdrop_view.gd"
const SORTIE_THUMB_VIEW_PATH := "res://scripts/views/sortie_thumb_view.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BackdropViewScript := preload("res://scripts/views/backdrop_view.gd")
const SortieThumbViewScript := preload("res://scripts/views/sortie_thumb_view.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(VIEW_PATH):
		_fail("Missing extracted BackdropView script.")
	if not FileAccess.file_exists(SORTIE_THUMB_VIEW_PATH):
		_fail("Missing extracted SortieThumbView script.")
	var view_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(VIEW_PATH))
	if view_source.find("class_name BackdropView") < 0:
		_fail("Extracted BackdropView should publish the legacy class name.")
	for required in ["set_mode", "set_background_texture", "draw_texture_rect", "draw_polyline"]:
		if view_source.find(required) < 0:
			_fail("Extracted BackdropView is missing behavior token: %s" % required)
	var sortie_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SORTIE_THUMB_VIEW_PATH))
	if sortie_source.find("class_name SortieThumbView") < 0:
		_fail("Extracted SortieThumbView should publish the legacy class name.")
	for required in ["set_entry", "trigger_flash", "_role_short", "_draw_icon"]:
		if sortie_source.find(required) < 0:
			_fail("Extracted SortieThumbView is missing behavior token: %s" % required)
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	if main_source.find("preload(\"res://scripts/views/backdrop_view.gd\")") < 0:
		_fail("main.gd should preload the extracted BackdropView.")
	if main_source.find("preload(\"res://scripts/views/sortie_thumb_view.gd\")") < 0:
		_fail("main.gd should preload the extracted SortieThumbView.")
	if main_source.find("\nclass BackdropView:") >= 0:
		_fail("main.gd should not keep the inline BackdropView class.")
	if main_source.find("\nclass SortieThumbView:") >= 0:
		_fail("main.gd should not keep the inline SortieThumbView class.")
	var backdrop = BackdropViewScript.new()
	if not (backdrop is Control):
		_fail("Extracted BackdropView should instantiate as a Control.")
	backdrop.size = Vector2(320.0, 180.0)
	backdrop.set_mode("battle")
	backdrop.set_background_texture(null)
	if backdrop.mode != "battle":
		_fail("BackdropView.set_mode should preserve legacy mode state.")
	backdrop.free()
	var sortie_thumb = SortieThumbViewScript.new()
	if not (sortie_thumb is Control):
		_fail("Extracted SortieThumbView should instantiate as a Control.")
	sortie_thumb.size = Vector2(64.0, 48.0)
	sortie_thumb.set_entry(2, 1, {"role": "puppet"}, {}, "pending", "en")
	if sortie_thumb.player_id != 2 or sortie_thumb.slot_index != 1 or sortie_thumb.status != "pending" or sortie_thumb.language != "en":
		_fail("SortieThumbView.set_entry should preserve legacy state fields.")
	sortie_thumb.trigger_flash()
	if sortie_thumb.flash_until_msec <= Time.get_ticks_msec():
		_fail("SortieThumbView.trigger_flash should set a future flash deadline.")
	sortie_thumb.free()
	print("VIEW_EXTRACTION_CONTRACT_PROBE ok views=2")
	quit(0)
