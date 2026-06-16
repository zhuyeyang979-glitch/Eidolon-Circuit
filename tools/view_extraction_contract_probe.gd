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
const MOBIUS_STRIP_SURFACE_VIEW_PATH := "res://scripts/views/mobius_strip_surface_view.gd"
const MOBIUS_STARDUST_BAND_VIEW_PATH := "res://scripts/views/mobius_stardust_band_view.gd"
const PART_PREVIEW_TEXTURE_RENDER_CANVAS_PATH := "res://scripts/views/catalog/part_preview_texture_render_canvas.gd"
const PART_PREVIEW_TEXTURE_CACHE_PATH := "res://scripts/views/catalog/part_preview_texture_cache.gd"
const PART_PREVIEW_ICON_VIEW_PATH := "res://scripts/views/catalog/part_preview_icon_view.gd"
const CATALOG_CARD_TEXT_LAYER_PATH := "res://scripts/views/catalog/catalog_card_text_layer.gd"
const CATALOG_CARD_BODY_TEXTURE_RENDER_CANVAS_PATH := "res://scripts/views/catalog/catalog_card_body_texture_render_canvas.gd"
const CATALOG_CARD_BODY_TEXTURE_CACHE_PATH := "res://scripts/views/catalog/catalog_card_body_texture_cache.gd"
const CATALOG_CARD_RETAINED_ITEM_PATH := "res://scripts/views/catalog/catalog_card_retained_item.gd"
const PART_CATALOG_CARD_BUTTON_PATH := "res://scripts/views/catalog/part_catalog_card_button.gd"
const EDITOR_STATS_RAIL_VIEW_PATH := "res://scripts/views/editor/editor_stats_rail_view.gd"
const EDITOR_PART_HOVER_POPUP_VIEW_PATH := "res://scripts/views/editor/editor_part_hover_popup_view.gd"
const SCOUT_UNIT_DETAIL_VIEW_PATH := "res://scripts/views/editor/scout_unit_detail_view.gd"
const UNIT_EDITOR_POWER_DOCK_VIEW_PATH := "res://scripts/views/editor/unit_editor_power_dock_view.gd"
const ENGINE_MOMENTUM_ALLOCATION_PANEL_VIEW_PATH := "res://scripts/views/editor/engine_momentum_allocation_panel_view.gd"
const TORSO_DETAIL_PANEL_VIEW_PATH := "res://scripts/views/editor/torso_detail_panel_view.gd"
const ASSEMBLY_BOARD_VIEW_PATH := "res://scripts/views/editor/assembly_board_view.gd"
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


func _require_source(path: String, expected_class_name: String, required_tokens: Array[String]) -> String:
	if not FileAccess.file_exists(path):
		_fail("Missing extracted view script: %s" % path)
		return ""
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))
	if source.find("class_name %s" % expected_class_name) < 0:
		_fail("Extracted %s should publish the legacy class name." % expected_class_name)
	for token in required_tokens:
		if source.find(token) < 0:
			_fail("Extracted %s is missing behavior token: %s" % [expected_class_name, token])
	return source


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
	_require_source(MOBIUS_STRIP_SURFACE_VIEW_PATH, "MobiusStripSurfaceView", ["set_surface_texture", "set_world", "_draw_world_grid_surface", "linear_elevation_visual_enabled", "stardust_band_snapshot"])
	_require_source(MOBIUS_STARDUST_BAND_VIEW_PATH, "MobiusStardustBandView", ["extends \"res://scripts/views/mobius_strip_surface_view.gd\"", "_draw_stardust_surface_bands", "surface_attached", "source_widths", "display_widths"])
	_require_source(PART_PREVIEW_TEXTURE_RENDER_CANVAS_PATH, "PartPreviewTextureRenderCanvas", ["extends Control", "configure", "AssemblyBoardRenderer.draw_part_preview"])
	_require_source(PART_PREVIEW_TEXTURE_CACHE_PATH, "PartPreviewTextureCache", ["extends RefCounted", "key_for", "request_preview", "process_queue", "SubViewport", "PartPreviewTextureRenderCanvas"])
	_require_source(PART_PREVIEW_ICON_VIEW_PATH, "PartPreviewIconView", ["extends Control", "set_preview", "clear_preview", "PartPreviewTextureCache", "_draw_size_badge"])
	_require_source(CATALOG_CARD_TEXT_LAYER_PATH, "CatalogCardTextLayer", ["extends Control", "configure", "CatalogCardBodyTextureCache", "_card_trim"])
	_require_source(CATALOG_CARD_BODY_TEXTURE_RENDER_CANVAS_PATH, "CatalogCardBodyTextureRenderCanvas", ["extends Control", "configure", "CATALOG_CARD_TITLE_FONT_SIZE", "_card_trim"])
	_require_source(CATALOG_CARD_BODY_TEXTURE_CACHE_PATH, "CatalogCardBodyTextureCache", ["extends RefCounted", "key_for", "request_preview", "prewarm", "CatalogCardBodyTextureRenderCanvas"])
	_require_source(CATALOG_CARD_RETAINED_ITEM_PATH, "CatalogCardRetainedItem", ["extends Control", "defer_texture_requests", "configure", "ensure_textures_requested", "PartPreviewTextureCache", "_draw_body_fallback"])
	_require_source(PART_CATALOG_CARD_BUTTON_PATH, "PartCatalogCardButton", ["extends Button", "signal page_scroll", "set_card", "set_card_with_signature", "CatalogCardRetainedItem", "PartPreviewIconView", "PartDragGhostView"])
	_require_source(EDITOR_STATS_RAIL_VIEW_PATH, "EditorStatsRailView", ["extends Control", "set_stats", "_draw_balance_entry", "_draw_scrollbar", "_format_signed_value"])
	_require_source(EDITOR_PART_HOVER_POPUP_VIEW_PATH, "EditorPartHoverPopupView", ["extends Control", "signal close_requested", "set_part", "clear_card", "PartPreviewIconView", "AssemblyBoardRenderer.draw_part_preview"])
	_require_source(SCOUT_UNIT_DETAIL_VIEW_PATH, "ScoutUnitDetailView", ["extends Control", "signal close_requested", "set_unit", "set_close_button_enabled", "_draw_unit_topology_thumb", "_bar_specs"])
	_require_source(UNIT_EDITOR_POWER_DOCK_VIEW_PATH, "UnitEditorPowerDockView", ["extends Control", "signal open_requested", "set_empty", "set_allocation_data", "_draw_rows", "_entry_slider_fill_ratio"])
	_require_source(ENGINE_MOMENTUM_ALLOCATION_PANEL_VIEW_PATH, "EngineMomentumAllocationPanelView", ["extends Control", "const AssemblyBoardRenderer", "signal allocation_value_submitted", "set_allocation_data", "has_focused_value_edit", "_draw_silhouette", "_segment_visual_polygon_local"])
	_require_source(TORSO_DETAIL_PANEL_VIEW_PATH, "TorsoDetailPanelView", ["extends Control", "signal payload_dropped", "set_detail", "set_binding_state", "_binding_key_rect", "_binding_action_side_rect", "_slot_hit"])
	_require_source(ASSEMBLY_BOARD_VIEW_PATH, "AssemblyBoardView", ["extends Control", "signal part_dropped", "class AssemblyBoardRenderLayer", "class AssemblyBoardRenderComponentItem", "class AssemblyBoardRenderItem", "set_board", "apply_board_diff", "apply_component_node_diff", "flush_deferred_retained_components", "AssemblyBoardRenderer.draw_component", "PartArt.material_color_for"])
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
	if main_source.find("preload(\"res://scripts/views/mobius_strip_surface_view.gd\")") < 0:
		_fail("main.gd should preload the extracted MobiusStripSurfaceView.")
	if main_source.find("preload(\"res://scripts/views/mobius_stardust_band_view.gd\")") < 0:
		_fail("main.gd should preload the extracted MobiusStardustBandView.")
	if main_source.find("preload(\"res://scripts/views/catalog/part_preview_texture_render_canvas.gd\")") < 0:
		_fail("main.gd should preload the extracted PartPreviewTextureRenderCanvas.")
	if main_source.find("preload(\"res://scripts/views/catalog/part_preview_texture_cache.gd\")") < 0:
		_fail("main.gd should preload the extracted PartPreviewTextureCache.")
	if main_source.find("preload(\"res://scripts/views/catalog/part_preview_icon_view.gd\")") < 0:
		_fail("main.gd should preload the extracted PartPreviewIconView.")
	if main_source.find("preload(\"res://scripts/views/catalog/catalog_card_text_layer.gd\")") < 0:
		_fail("main.gd should preload the extracted CatalogCardTextLayer.")
	if main_source.find("preload(\"res://scripts/views/catalog/catalog_card_body_texture_render_canvas.gd\")") < 0:
		_fail("main.gd should preload the extracted CatalogCardBodyTextureRenderCanvas.")
	if main_source.find("preload(\"res://scripts/views/catalog/catalog_card_body_texture_cache.gd\")") < 0:
		_fail("main.gd should preload the extracted CatalogCardBodyTextureCache.")
	if main_source.find("preload(\"res://scripts/views/catalog/catalog_card_retained_item.gd\")") < 0:
		_fail("main.gd should preload the extracted CatalogCardRetainedItem.")
	if main_source.find("preload(\"res://scripts/views/catalog/part_catalog_card_button.gd\")") < 0:
		_fail("main.gd should preload the extracted PartCatalogCardButton.")
	if main_source.find("preload(\"res://scripts/views/editor/editor_stats_rail_view.gd\")") < 0:
		_fail("main.gd should preload the extracted EditorStatsRailView.")
	if main_source.find("preload(\"res://scripts/views/editor/editor_part_hover_popup_view.gd\")") < 0:
		_fail("main.gd should preload the extracted EditorPartHoverPopupView.")
	if main_source.find("preload(\"res://scripts/views/editor/scout_unit_detail_view.gd\")") < 0:
		_fail("main.gd should preload the extracted ScoutUnitDetailView.")
	if main_source.find("preload(\"res://scripts/views/editor/unit_editor_power_dock_view.gd\")") < 0:
		_fail("main.gd should preload the extracted UnitEditorPowerDockView.")
	if main_source.find("preload(\"res://scripts/views/editor/engine_momentum_allocation_panel_view.gd\")") < 0:
		_fail("main.gd should preload the extracted EngineMomentumAllocationPanelView.")
	if main_source.find("preload(\"res://scripts/views/editor/torso_detail_panel_view.gd\")") < 0:
		_fail("main.gd should preload the extracted TorsoDetailPanelView.")
	if main_source.find("preload(\"res://scripts/views/editor/assembly_board_view.gd\")") < 0:
		_fail("main.gd should preload the extracted AssemblyBoardView.")
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
	if main_source.find("\nclass MobiusStripSurfaceView:") >= 0:
		_fail("main.gd should not keep the inline MobiusStripSurfaceView class.")
	if main_source.find("\nclass MobiusStardustBandView:") >= 0:
		_fail("main.gd should not keep the inline MobiusStardustBandView class.")
	if main_source.find("\nclass PartPreviewTextureRenderCanvas:") >= 0:
		_fail("main.gd should not keep the inline PartPreviewTextureRenderCanvas class.")
	if main_source.find("\nclass PartPreviewTextureCache:") >= 0:
		_fail("main.gd should not keep the inline PartPreviewTextureCache class.")
	if main_source.find("\nclass PartPreviewIconView:") >= 0:
		_fail("main.gd should not keep the inline PartPreviewIconView class.")
	if main_source.find("\nclass CatalogCardTextLayer:") >= 0:
		_fail("main.gd should not keep the inline CatalogCardTextLayer class.")
	if main_source.find("\nclass CatalogCardBodyTextureRenderCanvas:") >= 0:
		_fail("main.gd should not keep the inline CatalogCardBodyTextureRenderCanvas class.")
	if main_source.find("\nclass CatalogCardBodyTextureCache:") >= 0:
		_fail("main.gd should not keep the inline CatalogCardBodyTextureCache class.")
	if main_source.find("\nclass CatalogCardRetainedItem:") >= 0:
		_fail("main.gd should not keep the inline CatalogCardRetainedItem class.")
	if main_source.find("\nclass PartCatalogCardButton:") >= 0:
		_fail("main.gd should not keep the inline PartCatalogCardButton class.")
	if main_source.find("\nclass EditorStatsRailView:") >= 0:
		_fail("main.gd should not keep the inline EditorStatsRailView class.")
	if main_source.find("\nclass EditorPartHoverPopupView:") >= 0:
		_fail("main.gd should not keep the inline EditorPartHoverPopupView class.")
	if main_source.find("\nclass ScoutUnitDetailView:") >= 0:
		_fail("main.gd should not keep the inline ScoutUnitDetailView class.")
	if main_source.find("\nclass UnitEditorPowerDockView:") >= 0:
		_fail("main.gd should not keep the inline UnitEditorPowerDockView class.")
	if main_source.find("\nclass EngineMomentumAllocationPanelView:") >= 0:
		_fail("main.gd should not keep the inline EngineMomentumAllocationPanelView class.")
	if main_source.find("\nclass TorsoDetailPanelView:") >= 0:
		_fail("main.gd should not keep the inline TorsoDetailPanelView class.")
	if main_source.find("\nclass AssemblyBoardRenderLayer:") >= 0:
		_fail("main.gd should not keep the inline AssemblyBoardRenderLayer class.")
	if main_source.find("\nclass AssemblyBoardRenderComponentItem:") >= 0:
		_fail("main.gd should not keep the inline AssemblyBoardRenderComponentItem class.")
	if main_source.find("\nclass AssemblyBoardRenderItem:") >= 0:
		_fail("main.gd should not keep the inline AssemblyBoardRenderItem class.")
	if main_source.find("\nclass AssemblyBoardView:") >= 0:
		_fail("main.gd should not keep the inline AssemblyBoardView class.")
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
	var part_preview_cache_script := load(PART_PREVIEW_TEXTURE_CACHE_PATH)
	if part_preview_cache_script == null:
		_fail("PartPreviewTextureCache script should load after source checks.")
		return
	var preview_key_a: String = part_preview_cache_script.key_for("muscle", {"name": "RIFLE", "size_tier": "M", "material_class": "gun"}, false, 0.0, Vector2(96.0, 48.0))
	var preview_key_b: String = part_preview_cache_script.key_for("muscle", {"name": "RIFLE", "size_tier": "M", "material_class": "gun"}, true, 0.8, Vector2(96.0, 48.0))
	if preview_key_a == "" or preview_key_a != preview_key_b:
		_fail("PartPreviewTextureCache.key_for should keep selection and pulse out of the expensive body-art cache key.")
	part_preview_cache_script.clear_all(false)
	if not part_preview_cache_script.textures.is_empty() or not part_preview_cache_script.pending_order.is_empty():
		_fail("PartPreviewTextureCache.clear_all(false) should reset texture and queue state.")
	var part_preview_icon_script := load(PART_PREVIEW_ICON_VIEW_PATH)
	if part_preview_icon_script == null:
		_fail("PartPreviewIconView script should load after source checks.")
		return
	var preview_icon = part_preview_icon_script.new()
	if not (preview_icon is Control):
		_fail("Extracted PartPreviewIconView should instantiate as a Control.")
	preview_icon.size = Vector2(96.0, 48.0)
	preview_icon.set_preview("muscle", {"name": "RIFLE", "size_tier": "M"}, false)
	preview_icon.set_preview("muscle", {"name": "RIFLE", "size_tier": "M"}, true, 0.6)
	if preview_icon.slot_key != "muscle" or String(preview_icon.part.get("name", "")) != "RIFLE" or preview_icon.set_preview_noop_count < 1:
		_fail("PartPreviewIconView.set_preview should preserve identity-signature no-op behavior.")
	if preview_icon.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("PartPreviewIconView should ignore mouse input like the legacy retained preview surface.")
	preview_icon.clear_preview()
	if preview_icon.slot_key != "" or not preview_icon.part.is_empty():
		_fail("PartPreviewIconView.clear_preview should reset preview state.")
	preview_icon.free()
	var catalog_body_cache_script := load(CATALOG_CARD_BODY_TEXTURE_CACHE_PATH)
	if catalog_body_cache_script == null:
		_fail("CatalogCardBodyTextureCache script should load after source checks.")
		return
	var body_key_a: String = catalog_body_cache_script.key_for("muscle", {"stable_key": "rifle", "name": "RIFLE"}, "RIFLE", "DMG 4", "SPD 2", false, Vector2(96.0, 32.0))
	var body_key_b: String = catalog_body_cache_script.key_for("muscle", {"stable_key": "rifle", "name": "RIFLE"}, "RIFLE", "DMG 4", "SPD 2", true, Vector2(96.0, 32.0))
	if body_key_a == "" or body_key_a != body_key_b:
		_fail("CatalogCardBodyTextureCache.key_for should keep selected state out of retained body cache keys.")
	catalog_body_cache_script.clear_all(false)
	if not catalog_body_cache_script.textures.is_empty() or not catalog_body_cache_script.pending_order.is_empty():
		_fail("CatalogCardBodyTextureCache.clear_all(false) should reset texture and queue state.")
	var retained_script := load(CATALOG_CARD_RETAINED_ITEM_PATH)
	if retained_script == null:
		_fail("CatalogCardRetainedItem script should load after source checks.")
		return
	var retained = retained_script.new()
	if not (retained is Control):
		_fail("Extracted CatalogCardRetainedItem should instantiate as a Control.")
	retained.size = Vector2(132.0, 92.0)
	retained.configure("muscle", {"name": "RIFLE", "size_tier": "M"}, "RIFLE", "DMG 4", "SPD 2", true)
	if retained.slot_key != "muscle" or String(retained.part.get("name", "")) != "RIFLE" or retained.preview_cache_key() == "":
		_fail("CatalogCardRetainedItem.configure should preserve retained card state and preview key generation.")
	retained.free()
	var catalog_button_script := load(PART_CATALOG_CARD_BUTTON_PATH)
	if catalog_button_script == null:
		_fail("PartCatalogCardButton script should load after source checks.")
		return
	var catalog_button = catalog_button_script.new()
	if not (catalog_button is Button):
		_fail("Extracted PartCatalogCardButton should instantiate as a Button.")
	catalog_button.size = Vector2(132.0, 92.0)
	catalog_button.set_card("muscle", {"name": "RIFLE", "size_tier": "M"}, true, "en", 2, "RIFLE", "DMG 4", "SPD 2")
	if catalog_button.slot_key != "muscle" or catalog_button.part_index != 2 or catalog_button.retained_item == null:
		_fail("PartCatalogCardButton.set_card should preserve card state and retained item creation.")
	catalog_button.free()
	var stats_rail_script := load(EDITOR_STATS_RAIL_VIEW_PATH)
	if stats_rail_script == null:
		_fail("EditorStatsRailView script should load after source checks.")
		return
	var stats_rail = stats_rail_script.new()
	if not (stats_rail is Control):
		_fail("Extracted EditorStatsRailView should instantiate as a Control.")
	stats_rail.size = Vector2(220.0, 160.0)
	stats_rail.set_stats([
		{"kind": "section", "label": "CORE", "color": Color(0.3, 0.8, 1.0)},
		{"label": "Mass", "value": 12.0, "preview": 14.0, "unit": "", "max_value": 20.0, "pinned": true},
		{"kind": "balance", "label": "Power", "supply": 18.0, "demand": 11.0, "preview_supply": 16.0, "preview_demand": 13.0, "unit": "p"},
	], "EDITOR", "OK", true, "en")
	if stats_rail.entries.size() != 3 or stats_rail.header != "EDITOR" or stats_rail.ui_language != "en" or not stats_rail.preview_active:
		_fail("EditorStatsRailView.set_stats should preserve entries, header, language, and preview state.")
	stats_rail.free()
	var hover_popup_script := load(EDITOR_PART_HOVER_POPUP_VIEW_PATH)
	if hover_popup_script == null:
		_fail("EditorPartHoverPopupView script should load after source checks.")
		return
	var hover_popup = hover_popup_script.new()
	if not (hover_popup is Control):
		_fail("Extracted EditorPartHoverPopupView should instantiate as a Control.")
	hover_popup.size = Vector2(360.0, 520.0)
	hover_popup.set_part("muscle", {"name": "RIFLE", "size_tier": "M", "damage_type": "bullet"}, "RIFLE", "DMG 4", ["#Weapon", "Range 5"], "en", [{"label": "Mass", "value": 8.0}], true, "pin-token")
	if not hover_popup.visible or not hover_popup.pinned or hover_popup.mouse_filter != Control.MOUSE_FILTER_STOP:
		_fail("EditorPartHoverPopupView.set_part should preserve pinned visibility and mouse contract.")
	if hover_popup.preview_icon == null or hover_popup.preview_icon.name != "HoverPartPreviewIcon":
		_fail("EditorPartHoverPopupView should preserve retained preview icon creation.")
	hover_popup.clear_card()
	if hover_popup.visible or hover_popup.pinned or hover_popup.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("EditorPartHoverPopupView.clear_card should hide the popup and reset mouse contract.")
	hover_popup.free()
	var scout_detail_script := load(SCOUT_UNIT_DETAIL_VIEW_PATH)
	if scout_detail_script == null:
		_fail("ScoutUnitDetailView script should load after source checks.")
		return
	var scout_detail = scout_detail_script.new()
	if not (scout_detail is Control):
		_fail("Extracted ScoutUnitDetailView should instantiate as a Control.")
	scout_detail.size = Vector2(360.0, 520.0)
	scout_detail.set_unit(2, {"role": "puppet", "index": 1}, {"name": "Scout Test", "cost": 9, "deploy_cost": 4, "mass": 12.0, "length": 1.4, "ammo_capacity": {"bullet": 3}, "runtime_topology_segments": [{"a": 1}, {"b": 2}]}, "Detail line\nTopology note", "en")
	if scout_detail.player_id != 2 or scout_detail.language != "en" or String(scout_detail.entry.get("role", "")) != "puppet" or String(scout_detail.stats.get("name", "")) != "Scout Test":
		_fail("ScoutUnitDetailView.set_unit should preserve player, entry, stats, and language state.")
	scout_detail.set_close_button_enabled(true, "detail-token")
	if not scout_detail.close_button_enabled or scout_detail.mouse_filter != Control.MOUSE_FILTER_STOP or scout_detail.suppress_token != "detail-token":
		_fail("ScoutUnitDetailView.set_close_button_enabled should preserve close and mouse contracts.")
	scout_detail.clear("Empty message")
	if not scout_detail.entry.is_empty() or not scout_detail.stats.is_empty() or scout_detail.detail_text != "Empty message":
		_fail("ScoutUnitDetailView.clear should reset entry/stats and preserve the empty message.")
	scout_detail.set_close_button_enabled(false, "")
	if scout_detail.close_button_enabled or scout_detail.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("ScoutUnitDetailView.set_close_button_enabled(false) should release mouse capture.")
	scout_detail.free()
	var power_dock_script := load(UNIT_EDITOR_POWER_DOCK_VIEW_PATH)
	if power_dock_script == null:
		_fail("UnitEditorPowerDockView script should load after source checks.")
		return
	var power_dock = power_dock_script.new()
	if not (power_dock is Control):
		_fail("Extracted UnitEditorPowerDockView should instantiate as a Control.")
	power_dock.size = Vector2(420.0, 72.0)
	power_dock.set_empty("Pick torso", "en")
	if not power_dock.visible or power_dock.empty_note != "Pick torso" or power_dock.ui_language != "en" or not power_dock.entries.is_empty():
		_fail("UnitEditorPowerDockView.set_empty should preserve empty state and language.")
	power_dock.set_allocation_data({
		"title": "Drive",
		"subtitle": "Budget",
		"engine_output": 24.0,
		"used_ratio": 0.5,
		"entries": [
			{"id": "limb:1", "label": "Limb", "ratio": 0.25, "momentum": 6.0, "line": "A", "min_momentum": 2.0, "max_momentum": 10.0},
			{"id": "boost:1", "label": "Booster", "ratio": 0.25, "momentum": 6.0, "line": "B", "kind": "booster_drive"},
		],
	}, "zh")
	if power_dock.entries.size() != 2 or power_dock.empty_note != "" or power_dock.engine_output != 24.0 or power_dock.ui_language != "zh":
		_fail("UnitEditorPowerDockView.set_allocation_data should preserve entries, output, and language.")
	if power_dock._entry_index_for_id("limb:1") != 0 or power_dock._max_scroll() <= 0.0:
		_fail("UnitEditorPowerDockView should preserve entry lookup and overflow scroll calculations.")
	power_dock.free()
	var engine_panel_script := load(ENGINE_MOMENTUM_ALLOCATION_PANEL_VIEW_PATH)
	if engine_panel_script == null:
		_fail("EngineMomentumAllocationPanelView script should load after source checks.")
		return
	var engine_panel = engine_panel_script.new()
	if not (engine_panel is Control):
		_fail("Extracted EngineMomentumAllocationPanelView should instantiate as a Control.")
	engine_panel.size = Vector2(520.0, 240.0)
	engine_panel.set_allocation_data({
		"title": "Engine",
		"subtitle": "Allocation",
		"engine_name": "CORE DRIVE",
		"torso_name": "CORE",
		"engine_output": 40.0,
		"used_ratio": 0.55,
		"cooling_pool": 18.0,
		"engine_heat_load": 4.0,
		"allocation_heat_used": 6.0,
		"heat_used": 10.0,
		"heat_ratio": 0.5,
		"thermal_margin": 8.0,
		"display_entries": [
			{"id": "limb:1", "label": "Limb", "kind": "limb", "ratio": 0.25, "momentum": 10.0, "min_momentum": 4.0, "max_momentum": 20.0, "heat_load": 3.0},
			{"id": "boost:1", "label": "Booster", "kind": "booster_drive", "ratio": 0.3, "momentum": 12.0, "heat_load": 2.0},
		],
		"segments": [
			{"node_index": 1, "a_local": Vector2.ZERO, "b_local": Vector2.RIGHT, "radius": 0.04, "part_kind": "limb"},
		],
		"allocation_groups": [
			{"id": "g:1", "label": "Group", "target_nodes": [1]},
		],
	}, "en")
	if not engine_panel.visible or engine_panel.entries.size() != 2 or engine_panel.segments.size() != 1 or engine_panel.allocation_groups.size() != 1:
		_fail("EngineMomentumAllocationPanelView.set_allocation_data should preserve display entries, segments, and groups.")
	if engine_panel.engine_output != 40.0 or engine_panel.cooling_pool != 18.0 or engine_panel.thermal_margin != 8.0 or engine_panel.ui_language != "en":
		_fail("EngineMomentumAllocationPanelView.set_allocation_data should preserve power, heat, and language state.")
	if not engine_panel.entry_value_edits.has("limb:1") or engine_panel.has_focused_value_edit():
		_fail("EngineMomentumAllocationPanelView should preserve range-entry edit creation without stealing focus.")
	engine_panel.free()
	var torso_detail_script := load(TORSO_DETAIL_PANEL_VIEW_PATH)
	if torso_detail_script == null:
		_fail("TorsoDetailPanelView script should load after source checks.")
		return
	var torso_detail = torso_detail_script.new()
	if not (torso_detail is Control):
		_fail("Extracted TorsoDetailPanelView should instantiate as a Control.")
	torso_detail.size = Vector2(360.0, 260.0)
	torso_detail.set_detail("Torso", "Payloads", [
		{"payload_index": 2, "kind": "engine", "name": "Drive", "line": "Power", "slot_size_label": "M", "can_rebind": true},
	], 2, [
		{"payload_index": 3, "kind": "module", "name": "Module", "line": "Action", "slot_size_label": "S"},
	], 2, "plugin", 0, "en")
	if not torso_detail.visible or torso_detail.plugin_entries.size() != 1 or torso_detail.software_entries.size() != 1 or torso_detail.plugin_capacity != 2 or torso_detail.ui_language != "en":
		_fail("TorsoDetailPanelView.set_detail should preserve entries, capacities, selection, and language.")
	torso_detail.set_binding_state(true, "Bind", "Pick target", [
		{"root_index": 1, "label": "Limb", "note": "OK", "valid": true, "nodes": [1, 2]},
	], 0, true, true, "left")
	if not torso_detail.binding_mode or torso_detail.binding_candidates.size() != 1 or not torso_detail.binding_key_ready or torso_detail.binding_action_side != "left":
		_fail("TorsoDetailPanelView.set_binding_state should preserve binding mode state.")
	if torso_detail._binding_key_rect(1).size.x <= 0.0 or torso_detail._binding_action_side_rect("left").size.x <= 0.0:
		_fail("TorsoDetailPanelView should preserve binding key and side rect geometry helpers.")
	torso_detail.free()
	var assembly_board_script := load(ASSEMBLY_BOARD_VIEW_PATH)
	if assembly_board_script == null:
		_fail("AssemblyBoardView script should load after source checks.")
		return
	var assembly_board = assembly_board_script.new()
	if not (assembly_board is Control):
		_fail("Extracted AssemblyBoardView should instantiate as a Control.")
	assembly_board.size = Vector2(620.0, 420.0)
	root.add_child(assembly_board)
	var board_snapshot := {
		"revision_key": "assembly-contract-1",
		"view_zoom": 1.0,
		"view_offset": Vector2.ZERO,
		"selected": 0,
		"selected_nodes": [0],
		"nodes": [
			{"pos": Vector2(0.44, 0.5), "slot": "muscle", "material_class": "torso", "is_torso": true, "label": "CORE", "component_length": 0.34, "component_radius": 0.08},
			{"pos": Vector2(0.63, 0.5), "slot": "limb_muscle", "material_class": "muscle", "label": "ARM", "component_length": 0.22, "component_radius": 0.045},
		],
		"edges": [{"a_node": 0, "b_node": 1, "a_socket": "torso_port:0", "b_socket": "root_joint"}],
		"edge_states": {},
		"socket_markers": [],
	}
	assembly_board.set_board(board_snapshot, "", {}, "", 0.0, "custom", "en", 0.0, "assembly-contract-1")
	if assembly_board.retained_render_layer == null or assembly_board.retained_component_items.size() != 2:
		_fail("AssemblyBoardView.set_board should create the retained render layer and component items.")
	assembly_board.apply_component_node_diff(1, {"pos": Vector2(0.66, 0.5), "slot": "limb_muscle", "material_class": "muscle", "label": "ARM", "component_length": 0.22, "component_radius": 0.045}, "assembly-contract-2", true)
	if assembly_board.retained_deferred_component_indices.is_empty():
		_fail("AssemblyBoardView.apply_component_node_diff should support deferred retained component updates.")
	if assembly_board.flush_deferred_retained_components(1) != 1:
		_fail("AssemblyBoardView.flush_deferred_retained_components should flush the deferred component update.")
	assembly_board.free()
	var mobius_surface_script := load(MOBIUS_STRIP_SURFACE_VIEW_PATH)
	if mobius_surface_script == null:
		_fail("MobiusStripSurfaceView script should load after source checks.")
		return
	var surface = mobius_surface_script.new()
	if not (surface is Control):
		_fail("Extracted MobiusStripSurfaceView should instantiate as a Control.")
	surface.size = Vector2(320.0, 180.0)
	surface.set_world({
		"enabled": true,
		"surface_projection_mode": "world_grid",
		"surface_grid_cell_px": 56.0,
		"surface_lane_guides_enabled": true,
		"linear_elevation_visual_enabled": true,
		"screen_scale": 100.0,
		"screen_rect": Rect2(Vector2.ZERO, Vector2(320.0, 180.0)),
	}, {"twist_phase": 0.0}, Vector2(1.5, 0.0))
	var surface_snapshot: Dictionary = surface.stardust_band_snapshot()
	if String(surface_snapshot.get("surface_render_mode", "")) != "world_grid":
		_fail("MobiusStripSurfaceView.set_world should preserve world-grid render mode.")
	if not bool(surface_snapshot.get("lane_guides_enabled", false)) or not bool(surface_snapshot.get("linear_elevation_visual_enabled", false)):
		_fail("MobiusStripSurfaceView.set_world should preserve lane-guide and linear-elevation state.")
	if surface_snapshot.get("surface_draw_rect", Rect2()) != Rect2(Vector2.ZERO, Vector2(320.0, 180.0)):
		_fail("MobiusStripSurfaceView should preserve the configured draw rect.")
	surface.free()
	var mobius_stardust_script := load(MOBIUS_STARDUST_BAND_VIEW_PATH)
	if mobius_stardust_script == null:
		_fail("MobiusStardustBandView script should load after source checks.")
		return
	var stardust = mobius_stardust_script.new()
	if not (stardust is Control):
		_fail("Extracted MobiusStardustBandView should instantiate as a Control.")
	stardust.size = Vector2(320.0, 180.0)
	stardust.set_world({
		"enabled": true,
		"stardust_band_enabled": true,
		"surface_segments": 48,
		"view_width": 7.2,
		"screen_scale": 100.0,
		"stardust_particle_budget": 8,
	}, {"twist_phase": 0.2}, Vector2.ZERO)
	var stardust_snapshot: Dictionary = stardust.stardust_band_snapshot()
	if int(stardust_snapshot.get("band_count", 0)) != 2 or not bool(stardust_snapshot.get("surface_attached", false)):
		_fail("MobiusStardustBandView.set_world should preserve two surface-attached bands.")
	if PackedFloat32Array(stardust_snapshot.get("source_widths", PackedFloat32Array())).is_empty() or PackedFloat32Array(stardust_snapshot.get("display_widths", PackedFloat32Array())).is_empty():
		_fail("MobiusStardustBandView should preserve source/display width snapshots.")
	stardust.free()
	print("VIEW_EXTRACTION_CONTRACT_PROBE ok views=27")
	quit(0)
