extends SceneTree

const VIEW_PATH := "res://scripts/views/backdrop_view.gd"
const SORTIE_THUMB_VIEW_PATH := "res://scripts/views/sortie_thumb_view.gd"
const COCKPIT_HUD_VIEW_PATH := "res://scripts/views/cockpit_hud_view.gd"
const BATTLE_GAUGE_VIEW_PATH := "res://scripts/views/battle_instrument_gauge_view.gd"
const BATTLE_MINIMAP_VIEW_PATH := "res://scripts/views/battle_minimap_view.gd"
const BATTLE_ACTION_DIAGNOSTICS_VIEW_PATH := "res://scripts/views/battle_action_diagnostics_view.gd"
const BATTLE_PART_PREVIEW_VIEW_PATH := "res://scripts/views/battle_part_preview_view.gd"
const TRAINING_ENTRY_INTRO_VIEW_PATH := "res://scripts/views/training_entry_intro_view.gd"
const PART_DRAG_GHOST_VIEW_PATH := "res://scripts/views/part_drag_ghost_view.gd"
const COMPONENT_ART_VIEW_PATH := "res://scripts/views/component_art_view.gd"
const MAIN_PATH := "res://scripts/main.gd"
const BackdropViewScript := preload("res://scripts/views/backdrop_view.gd")
const SortieThumbViewScript := preload("res://scripts/views/sortie_thumb_view.gd")
const CockpitHudViewScript := preload("res://scripts/views/cockpit_hud_view.gd")
const BattleInstrumentGaugeViewScript := preload("res://scripts/views/battle_instrument_gauge_view.gd")
const BattleMinimapViewScript := preload("res://scripts/views/battle_minimap_view.gd")
const BattleActionDiagnosticsViewScript := preload("res://scripts/views/battle_action_diagnostics_view.gd")
const BattlePartPreviewViewScript := preload("res://scripts/views/battle_part_preview_view.gd")
const TrainingEntryIntroViewScript := preload("res://scripts/views/training_entry_intro_view.gd")
const PartDragGhostViewScript := preload("res://scripts/views/part_drag_ghost_view.gd")
const ComponentArtViewScript := preload("res://scripts/views/component_art_view.gd")


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
	if not FileAccess.file_exists(BATTLE_ACTION_DIAGNOSTICS_VIEW_PATH):
		_fail("Missing extracted BattleActionDiagnosticsView script.")
	if not FileAccess.file_exists(BATTLE_PART_PREVIEW_VIEW_PATH):
		_fail("Missing extracted BattlePartPreviewView script.")
	if not FileAccess.file_exists(TRAINING_ENTRY_INTRO_VIEW_PATH):
		_fail("Missing extracted TrainingEntryIntroView script.")
	if not FileAccess.file_exists(PART_DRAG_GHOST_VIEW_PATH):
		_fail("Missing extracted PartDragGhostView script.")
	if not FileAccess.file_exists(COMPONENT_ART_VIEW_PATH):
		_fail("Missing extracted ComponentArtView script.")
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
	var battle_action_diagnostics_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(BATTLE_ACTION_DIAGNOSTICS_VIEW_PATH))
	if battle_action_diagnostics_source.find("class_name BattleActionDiagnosticsView") < 0:
		_fail("Extracted BattleActionDiagnosticsView should publish the legacy class name.")
	for required in ["set_model", "clear_model", "func text", "_counts_line"]:
		if battle_action_diagnostics_source.find(required) < 0:
			_fail("Extracted BattleActionDiagnosticsView is missing behavior token: %s" % required)
	var battle_part_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(BATTLE_PART_PREVIEW_VIEW_PATH))
	if battle_part_source.find("class_name BattlePartPreviewView") < 0:
		_fail("Extracted BattlePartPreviewView should publish the legacy class name.")
	for required in ["set_component", "_draw_torso", "_draw_gun", "PartArt.material_color_for"]:
		if battle_part_source.find(required) < 0:
			_fail("Extracted BattlePartPreviewView is missing behavior token: %s" % required)
	var training_intro_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(TRAINING_ENTRY_INTRO_VIEW_PATH))
	if training_intro_source.find("class_name TrainingEntryIntroView") < 0:
		_fail("Extracted TrainingEntryIntroView should publish the legacy class name.")
	for required in ["set_entries", "clear_intro", "_draw_unit_thumbnail", "AssemblyBoardRenderer.draw_runtime_segment"]:
		if training_intro_source.find(required) < 0:
			_fail("Extracted TrainingEntryIntroView is missing behavior token: %s" % required)
	var ghost_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(PART_DRAG_GHOST_VIEW_PATH))
	if ghost_source.find("class_name PartDragGhostView") < 0:
		_fail("Extracted PartDragGhostView should publish the legacy class name.")
	for required in ["set_card", "set_art_sheets", "AssemblyBoardRenderer.draw_part_preview", "_draw_size_badge"]:
		if ghost_source.find(required) < 0:
			_fail("Extracted PartDragGhostView is missing behavior token: %s" % required)
	var component_art_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(COMPONENT_ART_VIEW_PATH))
	if component_art_source.find("class_name ComponentArtView") < 0:
		_fail("Extracted ComponentArtView should publish the legacy class name.")
	for required in ["set_component", "_draw_component", "_part_is_blade_weapon", "PartArt.torso_hull_local_points"]:
		if component_art_source.find(required) < 0:
			_fail("Extracted ComponentArtView is missing behavior token: %s" % required)
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
	if main_source.find("preload(\"res://scripts/views/battle_action_diagnostics_view.gd\")") < 0:
		_fail("main.gd should preload the extracted BattleActionDiagnosticsView.")
	if main_source.find("preload(\"res://scripts/views/battle_part_preview_view.gd\")") < 0:
		_fail("main.gd should preload the extracted BattlePartPreviewView.")
	if main_source.find("preload(\"res://scripts/views/training_entry_intro_view.gd\")") < 0:
		_fail("main.gd should preload the extracted TrainingEntryIntroView.")
	if main_source.find("preload(\"res://scripts/views/part_drag_ghost_view.gd\")") < 0:
		_fail("main.gd should preload the extracted PartDragGhostView.")
	if main_source.find("preload(\"res://scripts/views/component_art_view.gd\")") < 0:
		_fail("main.gd should preload the extracted ComponentArtView.")
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
	if main_source.find("\nclass BattleActionDiagnosticsView:") >= 0:
		_fail("main.gd should not keep the inline BattleActionDiagnosticsView class.")
	if main_source.find("\nclass BattlePartPreviewView:") >= 0:
		_fail("main.gd should not keep the inline BattlePartPreviewView class.")
	if main_source.find("\nclass TrainingEntryIntroView:") >= 0:
		_fail("main.gd should not keep the inline TrainingEntryIntroView class.")
	if main_source.find("\nclass PartDragGhostView:") >= 0:
		_fail("main.gd should not keep the inline PartDragGhostView class.")
	if main_source.find("\nclass ComponentArtView:") >= 0:
		_fail("main.gd should not keep the inline ComponentArtView class.")
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
	var battle_action_diagnostics = BattleActionDiagnosticsViewScript.new()
	if not (battle_action_diagnostics is Control):
		_fail("Extracted BattleActionDiagnosticsView should instantiate as a Control.")
	battle_action_diagnostics.set_model({"unit_count": 1, "active_action_count": 1, "unit_rows": [{"owner": 1, "role": "hero", "name": "Diag", "active_count": 1, "actions": [{"profile": "two_link_forward_snap", "phase_label": "startup"}]}]})
	if not battle_action_diagnostics.text().contains("two_link_forward_snap"):
		_fail("BattleActionDiagnosticsView.text should expose action profile rows.")
	battle_action_diagnostics.clear_model()
	if battle_action_diagnostics.text() != "":
		_fail("BattleActionDiagnosticsView.clear_model should clear text output.")
	battle_action_diagnostics.free()
	var battle_part = BattlePartPreviewViewScript.new()
	if not (battle_part is Control):
		_fail("Extracted BattlePartPreviewView should instantiate as a Control.")
	battle_part.set_component("muscle", {"name": "RIFLE", "projectile": true, "material_class": "gun"}, "en")
	if battle_part.slot_key != "muscle" or battle_part.language != "en" or String(battle_part.part.get("name", "")) != "RIFLE":
		_fail("BattlePartPreviewView.set_component should preserve legacy state fields.")
	battle_part.free()
	var training_intro = TrainingEntryIntroViewScript.new()
	if not (training_intro is Control):
		_fail("Extracted TrainingEntryIntroView should instantiate as a Control.")
	training_intro.set_entries([{"player_id": 1, "name": "TEST"}], "en", 0.3)
	if training_intro.entries.size() != 1 or training_intro.language != "en" or not training_intro.visible:
		_fail("TrainingEntryIntroView.set_entries should preserve legacy display state.")
	training_intro.clear_intro()
	if training_intro.visible or not training_intro.entries.is_empty():
		_fail("TrainingEntryIntroView.clear_intro should hide and clear entries.")
	training_intro.free()
	var ghost = PartDragGhostViewScript.new()
	if not (ghost is Control):
		_fail("Extracted PartDragGhostView should instantiate as a Control.")
	ghost.set_card("muscle", {"name": "XL HAMMER", "size_tier": "XL", "damage_type": "blunt"}, false, "en", 3, "XL HAMMER", "", "")
	if ghost.slot_key != "muscle" or ghost.part_index != 3 or ghost.size.x <= 112.0 or ghost.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("PartDragGhostView.set_card should preserve legacy ghost sizing and mouse contract.")
	ghost.free()
	var component_art = ComponentArtViewScript.new()
	if not (component_art is Control):
		_fail("Extracted ComponentArtView should instantiate as a Control.")
	component_art.set_component("joint", {"name": "HINGE", "length": 0.2}, 0.4)
	if component_art.slot_key != "joint" or String(component_art.part.get("name", "")) != "HINGE" or component_art.snap_amount != 0.4:
		_fail("ComponentArtView.set_component should preserve legacy display state.")
	component_art.free()
	print("VIEW_EXTRACTION_CONTRACT_PROBE ok views=10")
	quit(0)
