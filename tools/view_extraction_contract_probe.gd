extends SceneTree

const VIEW_PATH := "res://scripts/views/backdrop_view.gd"
const SORTIE_THUMB_VIEW_PATH := "res://scripts/views/sortie_thumb_view.gd"
const COCKPIT_HUD_VIEW_PATH := "res://scripts/views/cockpit_hud_view.gd"
const BATTLE_GAUGE_VIEW_PATH := "res://scripts/views/battle_instrument_gauge_view.gd"
const BATTLE_MINIMAP_VIEW_PATH := "res://scripts/views/battle_minimap_view.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BackdropViewScript := preload("res://scripts/views/backdrop_view.gd")
const SortieThumbViewScript := preload("res://scripts/views/sortie_thumb_view.gd")
const CockpitHudViewScript := preload("res://scripts/views/cockpit_hud_view.gd")
const BattleInstrumentGaugeViewScript := preload("res://scripts/views/battle_instrument_gauge_view.gd")
const BattleMinimapViewScript := preload("res://scripts/views/battle_minimap_view.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(VIEW_PATH):
		_fail("Missing extracted BackdropView script.")
	if not FileAccess.file_exists(SORTIE_THUMB_VIEW_PATH):
		_fail("Missing extracted SortieThumbView script.")
	if not FileAccess.file_exists(COCKPIT_HUD_VIEW_PATH):
		_fail("Missing extracted CockpitHudView script.")
	if not FileAccess.file_exists(BATTLE_GAUGE_VIEW_PATH):
		_fail("Missing extracted BattleInstrumentGaugeView script.")
	if not FileAccess.file_exists(BATTLE_MINIMAP_VIEW_PATH):
		_fail("Missing extracted BattleMinimapView script.")
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
	var cockpit_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(COCKPIT_HUD_VIEW_PATH))
	if cockpit_source.find("class_name CockpitHudView") < 0 or cockpit_source.find("_draw_corner") < 0:
		_fail("Extracted CockpitHudView should preserve its overlay drawing contract.")
	var gauge_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(BATTLE_GAUGE_VIEW_PATH))
	if gauge_source.find("class_name BattleInstrumentGaugeView") < 0:
		_fail("Extracted BattleInstrumentGaugeView should publish the legacy class name.")
	for required in ["set_values", "_dominant_ammo_info", "_draw_ammo_segments", "_draw_ammo_icon"]:
		if gauge_source.find(required) < 0:
			_fail("Extracted BattleInstrumentGaugeView is missing behavior token: %s" % required)
	var minimap_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(BATTLE_MINIMAP_VIEW_PATH))
	if minimap_source.find("class_name BattleMinimapView") < 0:
		_fail("Extracted BattleMinimapView should publish the legacy class name.")
	for required in ["set_world", "_draw_camera_window", "_draw_unit_marker", "_map_point"]:
		if minimap_source.find(required) < 0:
			_fail("Extracted BattleMinimapView is missing behavior token: %s" % required)
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	if main_source.find("preload(\"res://scripts/views/backdrop_view.gd\")") < 0:
		_fail("main.gd should preload the extracted BackdropView.")
	if main_source.find("preload(\"res://scripts/views/sortie_thumb_view.gd\")") < 0:
		_fail("main.gd should preload the extracted SortieThumbView.")
	if main_source.find("preload(\"res://scripts/views/cockpit_hud_view.gd\")") < 0:
		_fail("main.gd should preload the extracted CockpitHudView.")
	if main_source.find("preload(\"res://scripts/views/battle_instrument_gauge_view.gd\")") < 0:
		_fail("main.gd should preload the extracted BattleInstrumentGaugeView.")
	if main_source.find("preload(\"res://scripts/views/battle_minimap_view.gd\")") < 0:
		_fail("main.gd should preload the extracted BattleMinimapView.")
	if main_source.find("\nclass BackdropView:") >= 0:
		_fail("main.gd should not keep the inline BackdropView class.")
	if main_source.find("\nclass SortieThumbView:") >= 0:
		_fail("main.gd should not keep the inline SortieThumbView class.")
	if main_source.find("\nclass CockpitHudView:") >= 0:
		_fail("main.gd should not keep the inline CockpitHudView class.")
	if main_source.find("\nclass BattleInstrumentGaugeView:") >= 0:
		_fail("main.gd should not keep the inline BattleInstrumentGaugeView class.")
	if main_source.find("\nclass BattleMinimapView:") >= 0:
		_fail("main.gd should not keep the inline BattleMinimapView class.")
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
	var cockpit = CockpitHudViewScript.new()
	if not (cockpit is Control):
		_fail("Extracted CockpitHudView should instantiate as a Control.")
	cockpit.free()
	var gauge = BattleInstrumentGaugeViewScript.new()
	if not (gauge is Control):
		_fail("Extracted BattleInstrumentGaugeView should instantiate as a Control.")
	gauge.set_values(3.5, 7.0, {"bullet": {"current": 4, "capacity": 6}}, "en")
	if gauge.speed != 3.5 or gauge.speed_max != 7.0 or gauge.ui_lang != "en":
		_fail("BattleInstrumentGaugeView.set_values should preserve legacy state fields.")
	var ammo_info: Dictionary = gauge._dominant_ammo_info()
	if String(ammo_info.get("kind", "")) != "bullet" or int(ammo_info.get("capacity", 0)) != 6:
		_fail("BattleInstrumentGaugeView should retain its dominant ammo calculation.")
	gauge.free()
	var minimap = BattleMinimapViewScript.new()
	if not (minimap is Control):
		_fail("Extracted BattleMinimapView should instantiate as a Control.")
	minimap.set_world([{"owner": 1, "role": "hero", "ring": 4.0, "lane": -1.0}], 3.0, -0.5)
	if minimap.unit_points.size() != 1 or minimap.camera_ring != 3.0 or minimap.camera_lane != -0.5:
		_fail("BattleMinimapView.set_world should preserve legacy display state.")
	minimap.free()
	print("VIEW_EXTRACTION_CONTRACT_PROBE ok views=5")
	quit(0)
