extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _function_block(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		next = source.length()
	return source.substr(start, next - start)


func _init() -> void:
	var required_files := [
		"res://scripts/services/action_profile_registry.gd",
		"res://scripts/services/drive_system_service.gd",
		"res://scripts/services/unit_blueprint_validator.gd",
		"res://scripts/services/data_rule_service.gd",
		"res://scripts/services/loading_lifecycle_service.gd",
		"res://scripts/services/ui_lifecycle_service.gd",
		"res://scripts/services/unit_stats_service.gd",
		"res://scripts/services/unit_editor_assembly_template_service.gd",
		"res://scripts/services/unit_editor_engine_allocation_service.gd",
	]
	for path in required_files:
		if not FileAccess.file_exists(path):
			_fail("Missing extraction service %s." % path)
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/main.gd"))
	for symbol in ["ActionProfileRegistry", "DriveSystemService", "UnitBlueprintValidator", "DataRuleService", "LoadingLifecycleService", "UILifecycleService", "UnitStatsService", "UnitEditorAssemblyTemplateService", "UnitEditorEngineAllocationService", "action_profile_registry", "drive_system_service", "unit_blueprint_validator", "data_rule_service", "unit_stats_service", "unit_editor_assembly_template_service", "unit_editor_engine_allocation_service"]:
		if source.find(symbol) < 0:
			_fail("main.gd does not reference %s." % symbol)
	for delegated in ["LoadingLifecycleService.prepare_task", "LoadingLifecycleService.queue_deferred_idle_tasks", "UILifecycleService.layer_snapshot", "UILifecycleService.trim_dictionary_cache", "UILifecycleService.editor_action_build_specs", "UILifecycleService.editor_shell_chrome_build_specs", "UILifecycleService.editor_part_library_build_specs", "UILifecycleService.editor_ammo_size_build_specs", "UILifecycleService.editor_role_load_build_specs", "UILifecycleService.editor_info_surface_build_specs", "UILifecycleService.editor_roster_overview_build_specs", "UILifecycleService.editor_color_controls_build_specs", "UILifecycleService.editor_catalog_card_build_specs", "UILifecycleService.editor_template_drawer_build_specs", "UILifecycleService.editor_shop_surface_build_specs", "UILifecycleService.editor_sort_menu_build_specs", "UILifecycleService.editor_body_part_button_build_specs", "UILifecycleService.editor_module_binding_button_build_specs", "UILifecycleService.editor_sort_action_button_build_specs", "UILifecycleService.editor_save_unit_dialog_build_specs", "UILifecycleService.editor_orientation_popup_build_specs", "UILifecycleService.editor_dashboard_controls_build_specs", "UILifecycleService.editor_canvas_zoom_chrome_build_specs", "UILifecycleService.editor_auxiliary_chrome_build_specs", "UILifecycleService.editor_overlay_view_build_specs", "UILifecycleService.editor_panel_visibility_plan", "UILifecycleService.editor_panel_role_chrome_presentation", "UILifecycleService.editor_action_presentations", "UILifecycleService.editor_assembly_guide_presentation", "UILifecycleService.editor_board_zoom_presentation", "UILifecycleService.editor_orientation_popup_presentation", "UILifecycleService.editor_template_drawer_presentation", "UILifecycleService.editor_body_board_button_presentation", "UILifecycleService.editor_body_shop_slot_button_presentation", "UILifecycleService.editor_slot_button_presentation", "UILifecycleService.editor_part_group_button_presentation", "UILifecycleService.editor_part_filter_button_presentation", "UILifecycleService.editor_ammo_size_control_presentation", "UILifecycleService.editor_sort_controls_presentation", "UILifecycleService.editor_info_panel_presentation", "UILifecycleService.editor_shop_feedback_presentation", "UILifecycleService.editor_color_controls_presentation", "UILifecycleService.editor_section_chrome_presentation", "UILifecycleService.editor_catalog_shop_surface_presentation", "_unit_stats_service().copy_part_logic_stats", "_unit_stats_service().copy_part_combat_stats", "_unit_stats_service().copy_part_payload_stats", "_unit_stats_service().part_payload_context(", "_unit_stats_service().torso_payload_context(", "_unit_stats_service().normalize_size_tier_label(", "_unit_stats_service().size_tier_rank(", "_unit_stats_service().size_tier_from_footprint(", "_unit_stats_service().part_size_tier_label(", "_unit_stats_service().component_is_torso(", "_unit_stats_service().component_is_brain_torso(", "_unit_stats_service().torso_size_rank_for_slots(", "_unit_stats_service().torso_baseline_slot_capacity(", "_unit_stats_service().torso_plugin_capacity_for_part(", "_unit_stats_service().torso_software_capacity_for_part(", "_unit_stats_service().economy_median_mass_for_rank(", "_unit_stats_service().thruster_drive_demand_for_part(", "_unit_stats_service().thruster_move_efficiency_for_part(", "_unit_stats_service().thruster_boost_efficiency_for_part(", "_unit_stats_service().booster_normal_momentum_for_part(", "_unit_stats_service().booster_boost_momentum_for_part(", "_unit_stats_service().thruster_boost_total_momentum_for_part(", "_unit_stats_service().payload_slot_key_for_kind(", "_unit_stats_service().payload_catalog_selection(", "_unit_stats_service().volume_tier_rank(", "_unit_stats_service().volume_rank_from_value(", "_unit_stats_service().payload_slot_volume_rank(", "_unit_stats_service().part_slot_volume_rank(", "_unit_stats_service().internal_slot_accepts_payload(", "_unit_stats_service().torso_internal_slot_size_ranks(", "_unit_stats_service().best_internal_slot_for_payload(", "_unit_stats_service().cooling_tags_for_part(", "_unit_stats_service().movement_profile_priority(", "_unit_stats_service().apply_torso_payload_direct_stats", "_unit_stats_service().record_torso_payload_summary_entry", "_unit_stats_service().torso_payload_processing_plan", "_unit_stats_service().apply_torso_payload_plan", "_unit_stats_service().apply_ether_payload_stats", "_unit_stats_service().apply_soul_heat_capacity_stats", "_unit_stats_service().apply_soul_bonus_stats", "_unit_stats_service().apply_internal_payload_merge_plan", "_unit_stats_service().apply_internal_engine_payload_stats", "_unit_stats_service().apply_internal_cooling_payload_stats", "_unit_stats_service().apply_internal_thruster_drive_stats", "_unit_stats_service().apply_torso_payload_summary", "_unit_stats_service().apply_base_motion_envelope", "_unit_stats_service().apply_role_deploy_profile", "_unit_stats_service().apply_manufacturer_discount"]:
		if source.find(delegated) < 0:
			_fail("main.gd should delegate extracted glue through %s." % delegated)
			return
	if source.find("UILifecycleService.editor_edit_side_button_presentation") < 0:
		_fail("main.gd should delegate editor edit-side button presentation planning.")
		return
	if source.find("UILifecycleService.editor_module_binding_tryout_button_presentation") < 0 or source.find("UILifecycleService.editor_module_binding_side_idle_presentation") < 0:
		_fail("main.gd should delegate editor module binding tryout button presentation planning.")
		return
	if source.find("UILifecycleService.editor_module_binding_overlay_side_presentation") < 0 or source.find("UILifecycleService.editor_module_binding_overlay_key_presentation") < 0:
		_fail("main.gd should delegate editor module binding overlay button presentation planning.")
		return
	if source.find("UILifecycleService.editor_roster_overview_presentation") < 0:
		_fail("main.gd should delegate editor roster overview presentation planning.")
		return
	if source.find("UILifecycleService.editor_load_card_buttons_presentation") < 0:
		_fail("main.gd should delegate editor load card button presentation planning.")
		return
	if source.find("UILifecycleService.editor_save_unit_feedback_presentation") < 0:
		_fail("main.gd should delegate editor save-unit feedback presentation planning.")
		return
	if source.find("UILifecycleService.editor_unit_hover_view_presentation") < 0:
		_fail("main.gd should delegate editor unit hover view presentation planning.")
		return
	if source.find("UILifecycleService.editor_part_hover_popup_presentation") < 0:
		_fail("main.gd should delegate editor part hover popup presentation planning.")
		return
	if source.find("UILifecycleService.editor_drag_ghost_view_presentation") < 0:
		_fail("main.gd should delegate editor drag ghost view presentation planning.")
		return
	if source.find("UILifecycleService.editor_stats_rail_view_presentation") < 0:
		_fail("main.gd should delegate editor stats rail view presentation planning.")
		return
	if source.find("UILifecycleService.editor_perf_overlay_presentation") < 0:
		_fail("main.gd should delegate editor perf overlay presentation planning.")
		return
	if source.find("UILifecycleService.editor_save_unit_name_panel_presentation") < 0:
		_fail("main.gd should delegate editor save-unit name panel presentation planning.")
		return
	if source.find("UILifecycleService.editor_orientation_action_buttons_presentation") < 0:
		_fail("main.gd should delegate editor orientation action button presentation planning.")
		return
	if source.find("UILifecycleService.editor_board_hint_presentation") < 0:
		_fail("main.gd should delegate editor board hint presentation planning.")
		return
	if source.find("UILifecycleService.editor_body_shop_slot_text_presentation") < 0:
		_fail("main.gd should delegate editor body shop-slot text presentation planning.")
		return
	if source.find("UILifecycleService.editor_board_ui_revision_key") < 0:
		_fail("main.gd should delegate editor board UI revision key planning.")
		return
	if source.find("UILifecycleService.editor_catalog_domain_revision_key") < 0:
		_fail("main.gd should delegate editor catalog domain revision key planning.")
		return
	if source.find("func _add_editor_action_button_from_spec(") < 0:
		_fail("main.gd should centralize editor action button creation.")
		return
	if source.find("func _apply_editor_button_build_spec(") < 0:
		_fail("main.gd should centralize editor button build spec property application.")
		return
	var build_editor_ui_block := _function_block(source, "func _build_editor_ui(")
	if build_editor_ui_block.is_empty():
		_fail("main.gd should keep _build_editor_ui available.")
		return
	if build_editor_ui_block.count("_add_editor_action_button_from_spec(") < 7:
		_fail("_build_editor_ui should reuse the editor action button creation helper.")
		return
	if build_editor_ui_block.count("_apply_editor_button_build_spec(") < 11:
		_fail("_build_editor_ui should reuse the editor button build spec property helper.")
		return
	for stale_action_build_fragment in [
		"var guide_button := Button.new()",
		"var quick_button := Button.new()",
		"var canvas_button := Button.new()",
		"var zoom_button := Button.new()",
		"var template_menu_button := Button.new()",
		"var page_button := Button.new()",
	]:
		if build_editor_ui_block.find(stale_action_build_fragment) >= 0:
			_fail("_build_editor_ui should create editor action buttons through the helper instead of inline loops: %s" % stale_action_build_fragment)
			return
	for stale_button_build_fragment in [
		"panel_button.position = panel_spec.get(\"position\"",
		"role_button.position = role_button_build_spec.get(\"position\"",
		"group_button.position = group_spec.get(\"position\"",
		"slot_button.position = slot_spec.get(\"position\"",
		"filter_button.position = filter_spec.get(\"position\"",
		"load_card_button.position = load_card_build_spec.get(\"position\"",
		"role_button.position = save_unit_role_button_build_spec.get(\"position\"",
		"button.position = save_unit_action_button_build_spec.get(\"position\"",
		"roster_prev_button.position = roster_prev_build_spec.get(\"position\"",
		"roster_next_button.position = roster_next_build_spec.get(\"position\"",
		"roster_button.position = roster_slot_build_spec.get(\"position\"",
	]:
		if build_editor_ui_block.find(stale_button_build_fragment) >= 0:
			_fail("_build_editor_ui should apply role/load/part-library button specs through the helper: %s" % stale_button_build_fragment)
			return
	var orientation_buttons_block := _function_block(source, "func _refresh_editor_orientation_buttons(")
	if orientation_buttons_block.is_empty():
		_fail("main.gd should keep _refresh_editor_orientation_buttons available.")
		return
	if orientation_buttons_block.count("UILifecycleService.editor_orientation_action_buttons_presentation(") != 1:
		_fail("_refresh_editor_orientation_buttons should request one orientation action button presentation plan.")
		return
	for stale_orientation_fragment in [
		"_set_canvas_item_visible_if_changed(action_button, show_orientation_action)",
		"_set_button_disabled_if_changed(action_button, not show_orientation_action)",
		"var x_pos := 776.0",
		"_set_control_text_if_changed(action_button, \"左挂刃\"",
		"_set_control_text_if_changed(action_button, \"翻侧刃\"",
		"_set_canvas_item_modulate_if_changed(action_button",
		"action_button.move_to_front()",
	]:
		if orientation_buttons_block.find(stale_orientation_fragment) >= 0:
			_fail("_refresh_editor_orientation_buttons should apply service plans instead of inline mutation: %s" % stale_orientation_fragment)
			return
	var board_ui_block := _function_block(source, "func _update_editor_board_ui(")
	if board_ui_block.is_empty():
		_fail("main.gd should keep _update_editor_board_ui available.")
		return
	if board_ui_block.count("UILifecycleService.editor_board_hint_presentation(") < 3:
		_fail("_update_editor_board_ui should request board hint presentation plans for board states.")
		return
	for stale_board_hint_fragment in [
		"_set_control_text_if_changed(editor_board_hint_label",
		"var rule_short := \"规则正常\"",
		"Ether screen blueprint %d/%d",
		"自由画布就绪：拖入构件",
		"机体画布未启用",
	]:
		if board_ui_block.find(stale_board_hint_fragment) >= 0:
			_fail("_update_editor_board_ui should apply service board-hint plans instead of inline text mutation: %s" % stale_board_hint_fragment)
			return
	if board_ui_block.find("var board_ui_revision_key := \"%s|%s|%s|%d|%d|%d|%d|%s|%s|%s|%d|%d|%s|%s|%s|%d|%s|%d|%d|%s|%s\"") >= 0:
		_fail("_update_editor_board_ui should delegate board UI revision key assembly.")
		return
	if board_ui_block.find("catalog_domain_key = \"%s|%s|%s|%s|%s|%d|%d|%d|%s|%s\"") >= 0 or board_ui_block.find("catalog_domain_key = \"hidden|%s\"") >= 0:
		_fail("_update_editor_board_ui should delegate catalog domain revision key assembly.")
		return
	if source.contains("\"size_tier_rank\": float(_size_tier_rank(_part_size_tier_label(part, slot_key)))"):
		_fail("main.gd should not derive part size-tier rank inside slot-volume adapters.")
	if source.contains("\"booster_boost_momentum\":"):
		_fail("main.gd should not derive booster momentum inside slot-volume adapters.")
	if source.contains("_component_index_by_exact_name(role_key, saved_slot, saved_name)"):
		_fail("main.gd should delegate saved payload catalog-name matching.")
	if source.contains("return 8 if group_kind == \"plugin\" else 7"):
		_fail("main.gd should delegate torso baseline capacity formula.")
	if source.contains("return clampi(cap + 1, 1, 12)"):
		_fail("main.gd should delegate torso capacity clamping formula.")
	if source.contains("stats[\"engine_momentum_output\"] = float(stats.get(\"engine_momentum_output\", 0.0)) + engine_output"):
		_fail("main.gd should delegate internal engine payload stat merging.")
	if source.contains("stats[\"manual_cooling\"] = float(stats.get(\"manual_cooling\", 48.0)) + float(part.get(\"manual_cooling_bonus\", 0.0))"):
		_fail("main.gd should delegate internal cooling payload stat merging.")
	if source.contains("stats[\"thruster_boost_peak_demand\"] = float(stats.get(\"thruster_boost_peak_demand\", 0.0)) + boost_peak"):
		_fail("main.gd should delegate internal thruster payload stat merging.")
	if source.contains("if action_kind == \"board_primary\":") or source.contains("elif action_kind == \"unit\" and action_visible:"):
		_fail("main.gd should delegate editor action presentation branching.")
	if source.contains("var visible_unit_action_index := 0") or source.contains("UILifecycleService.editor_action_state("):
		_fail("main.gd should delegate editor action state batching and unit-action ordering.")
		return
	if source.contains("var panel_specs := [") or source.contains("var board_primary_actions := [") or source.contains("var canvas_tools := [") or source.contains("var zoom_button_specs := ["):
		_fail("main.gd should delegate editor action build specs.")
	if source.contains("quick_button.name = \"BoardPrimary%s\" % String(board_primary_spec.get(\"key\", \"\"))"):
		_fail("main.gd should delegate board-primary action button identity specs.")
		return
	if source.contains("sort_prev_button.text = \"<\"") or source.contains("template_menu_button.text = \"导入模板\""):
		_fail("main.gd should delegate sort/template action build specs.")
	if source.contains("var panel_texts_zh := {\"load\": \"单位库\", \"parts\": \"零件库\"}") or source.contains("Vector2(936.0 + float(ROLE_ORDER.find(String(role_key_button))) * 92.0") or source.contains("(\"身份:%s\" if _ui_is_zh() else \"ROLE:%s\") % _role_short(String(role_key_button))"):
		_fail("main.gd should delegate editor panel/role chrome presentation planning.")
	if source.contains("var group_key: String = EDITOR_PART_GROUP_ORDER[i]") or source.contains("slot_button.position = Vector2(936.0 + float(i % 2) * 136.0") or source.contains("filter_button.position = Vector2(936.0 + float(i % 4) * 68.0"):
		_fail("main.gd should delegate part-library button build specs.")
	if source.contains("_make_label(root, \"AmmoSizeTitle\", \"\", Vector2(936.0, 258.0)") or source.contains("editor_ammo_size_slider.position = Vector2(1010.0, 257.0)") or source.contains("var tick_label := _make_label(root, \"AmmoSizeTick%d\" % i, \"\", Vector2(1002.0 + float(i) * 44.0"):
		_fail("main.gd should delegate ammo-size control build specs.")
	if source.contains("role_button.name = \"Role%s\" % role_key") or source.contains("role_button.position = Vector2(936.0 + float(i) * 92.0, 156.0)") or source.contains("load_card_button.position = Vector2(936.0, 220.0 + float(i) * 34.0)"):
		_fail("main.gd should delegate editor role/load build specs.")
		return
	if source.contains("_make_label(root, \"UnitLabel\", \"\", Vector2(936.0, 198.0)") or source.contains("editor_battle_preview_view.position = Vector2(936.0, 278.0)") or source.contains("component_art_view.position = Vector2(936.0, 406.0)") or source.contains("editor_structure_reference_view.position = Vector2(936.0, 146.0)"):
		_fail("main.gd should delegate editor info surface build specs.")
	if source.contains("_make_label(root, \"RosterOverviewTitle\", \"队伍总览\", Vector2(236.0, 46.0)") or source.contains("roster_prev_button.name = \"EditorRosterPrev\"") or source.contains("roster_button.position = Vector2(350.0 + float(i) * 86.0, 44.0)") or source.contains("roster_thumb.position = roster_button.position + Vector2(3.0, 3.0)"):
		_fail("main.gd should delegate editor roster overview build specs.")
	if source.contains("editor_color_panel = _add_ui_rect(root, \"EditorColorPalettePanel\", Vector2(932.0, 146.0)") or source.contains("_make_label(root, \"EditorColorLabel\", \"队伍颜色\", Vector2(944.0, 158.0)") or source.contains("color_button.position = Vector2(944.0 + float(i % 2) * 128.0") or source.contains("editor_primary_color_picker.position = Vector2(944.0, 370.0)") or source.contains("editor_accent_color_picker.position = Vector2(1072.0, 370.0)"):
		_fail("main.gd should delegate editor color control build specs.")
	if source.contains("for i in range(8):\n\t\tvar catalog_button := PartCatalogCardButton.new()") or source.contains("catalog_button.position = Vector2(936.0 + float(i % 2) * 136.0") or source.contains("catalog_button.size = Vector2(130.0, 72.0)"):
		_fail("main.gd should delegate editor catalog card build specs.")
	if source.contains("editor_template_panel = _add_ui_rect(root, \"TemplateSubmenuPanel\", Vector2(932.0, 180.0)") or source.contains("editor_section_labels[\"template\"] = _make_label(root, \"TemplateTitle\", \"预组单位库\", Vector2(936.0, 374.0)") or source.contains("frame_button.position = Vector2(940.0 + float(i % 2) * 134.0") or source.contains("barrier_template_button.position = Vector2(940.0 + float(i % 2) * 134.0"):
		_fail("main.gd should delegate editor template drawer build specs.")
	if source.contains("_make_label(root, \"ShopTitle\", \"零件面板\", Vector2(936.0, 146.0)") or source.contains("_make_label(root, \"ShopHint\", \"流程：选择类型 -> 拖卡片进画布 -> 磁吸贴合\", Vector2(936.0, 170.0)") or source.contains("editor_shop_card_backdrop.position = Vector2(936.0, 252.0)") or source.contains("shop_button.position = Vector2(936.0, 252.0 + float(i) * 84.0)"):
		_fail("main.gd should delegate editor shop surface build specs.")
	if source.contains("editor_sort_panel = _add_ui_rect(root, \"EditorSortSubmenu\", Vector2(932.0, 318.0)") or source.contains("sort_option_button.name = \"SortOption%d\" % i") or source.contains("sort_option_button.position = Vector2(940.0 + float(i % 3) * 88.0") or source.contains("_make_label(root, \"CatalogTitle\", \"零件卡片\", Vector2(936.0, 330.0)") or source.contains("_make_label(root, \"CatalogPage\", \"\", Vector2(1110.0, 330.0)"):
		_fail("main.gd should delegate editor sort menu build specs.")
	if source.contains("var body_positions := {") or source.contains("button.position = body_positions[part_key]") or source.contains("button.size = Vector2(132.0, 44.0)"):
		_fail("main.gd should delegate editor body part button build specs.")
	if source.contains("bind_button.name = \"ModuleBindKey%d\" % key_index") or source.contains("bind_button.position = Vector2(286.0 + float(key_index - 1) * 56.0, 618.0)") or source.contains("side_button.name = \"ModuleBindSide%s\" % side_key.capitalize()") or source.contains("side_button.position = Vector2(936.0, 618.0)"):
		_fail("main.gd should delegate editor module binding button build specs.")
	if source.contains("_editor_build_spec_for_key(sort_action_specs, \"sort_prev\")") or source.contains("sort_prev_button.pressed.connect(_cycle_editor_catalog_sort.bind(-1))") or source.contains("sort_key_button.pressed.connect(_toggle_editor_sort_menu)") or source.contains("sort_dir_button.pressed.connect(_toggle_editor_catalog_sort_direction)"):
		_fail("main.gd should delegate editor sort action button build specs.")
	if source.contains("editor_save_unit_name_panel.position = Vector2(390.0, 188.0)") or source.contains("_make_label(editor_save_unit_name_panel, \"SaveUnitNameLabel\", \"保存为单位\", Vector2(18.0, 14.0)") or source.contains("role_button.position = Vector2(18.0 + float(i) * 148.0, 114.0)") or source.contains("var save_name_buttons := ["):
		_fail("main.gd should delegate editor save-unit dialog build specs.")
	if source.contains("editor_orientation_popup_panel.name = \"ScytheSideMountChoicePopup\"") or source.contains("editor_orientation_popup_panel.size = Vector2(256.0, 86.0)") or source.contains("_make_label(editor_orientation_popup_panel, \"ScytheSideMountChoiceLabel\", \"\", Vector2(10.0, 6.0)") or source.contains("editor_orientation_popup_right_button.position = Vector2(102.0, 42.0)") or source.contains("editor_orientation_popup_cancel_button.size = Vector2(52.0, 28.0)"):
		_fail("main.gd should delegate editor orientation popup build specs.")
	if source.contains("editor_power_dock_view.name = \"UnitEditorPowerAllocationDock\"") or source.contains("editor_power_dock_view.position = Vector2(190.0, 24.0)") or source.contains("_make_label(root, \"BoardHint\", \"\", Vector2(296.0, 72.0)") or source.contains("editor_engine_allocation_button.position = Vector2(52.0, 108.0)") or source.contains("editor_torso_detail_button.position = Vector2(228.0, 108.0)") or source.contains("_make_label(root, \"DashboardPowerAllocationSummary\", \"\", Vector2(140.0, 109.0)"):
		_fail("main.gd should delegate editor dashboard controls build specs.")
	if source.contains("_make_label(root, \"CanvasToolsTitle\", \"\", Vector2.ZERO") or source.contains("_make_label(root, \"CanvasTopologyText\", \"\", Vector2.ZERO") or source.contains("_make_label(root, \"BoardZoomTitle\", \"\", Vector2.ZERO") or source.contains("editor_board_zoom_label = _make_label(root, \"BoardZoomValue\", \"100%\", Vector2(72.0, 656.0)"):
		_fail("main.gd should delegate editor canvas/zoom chrome build specs.")
	if source.contains("_make_label(root, \"AssemblyGuideLabel\", \"\", Vector2(936.0, 118.0)") or source.contains("_make_label(root, \"LegalityStatus\", \"\", Vector2(18.0, 616.0)") or source.contains("editor_assembly_tutorial_panel = _add_ui_rect(root, \"AssemblyTutorialPanel\", Vector2(194.0, 102.0)") or source.contains("_make_label(root, \"AssemblyTutorialLabel\", \"\", Vector2(320.0, 108.0)") or source.contains("_make_label(root, \"TeamEditPerfOverlay\", \"\", Vector2(42.0, 86.0)") or source.contains("_make_label(root, \"SaveUnitFeedback\", \"\", Vector2(270.0, 654.0)"):
		_fail("main.gd should delegate editor auxiliary chrome build specs.")
	if source.contains("editor_stats_rail_view.name = \"EditorStatsRail\"") or source.contains("editor_stats_rail_view.position = Vector2(18.0, 104.0)") or source.contains("editor_hover_popup_view.position = Vector2(410.0, 124.0)") or source.contains("editor_unit_hover_view.name = \"EditorUnitHoverPreview\"") or source.contains("editor_torso_detail_view.position = Vector2(18.0, 338.0)") or source.contains("engine_momentum_allocation_view.name = \"EngineMomentumAllocationPanel\"") or source.contains("editor_drag_ghost_view.name = \"EditorPartDragGhost\""):
		_fail("main.gd should delegate editor overlay view build specs.")
		return
	if source.contains("_make_label(root, \"EditorTitle\", \"\", Vector2.ZERO") or source.contains("_make_label(root, \"EditorHelp\", \"\", Vector2.ZERO") or source.contains("editor_back_button.name = \"EditorBackButton\"") or source.contains("editor_back_button.text = \"选项\""):
		_fail("main.gd should delegate editor shell chrome build specs.")
		return
	if source.find("func _apply_editor_control_plan(") < 0:
		_fail("main.gd should provide a shared editor Control plan adapter.")
		return
	if source.contains("_set_control_text_if_changed(editor_assembly_guide_label") or source.contains("_set_control_text_if_changed(apply_button, \"前往\"") or source.contains("var connection_gate_active := String(model.get(\"key\", \"\")) == \"connection\" and not _editor_connection_evaluation_passed()"):
		_fail("main.gd should delegate editor assembly-guide presentation planning.")
		return
	if source.contains("editor_board_zoom_label.text = \"%d%%\"") or source.contains("zoom_out.text = \"-\"") or source.contains("zoom_in.disabled = editor_board_zoom") or source.contains("zoom_reset.text = \"重置\""):
		_fail("main.gd should delegate editor board-zoom presentation planning.")
		return
	if source.contains("_set_control_text_if_changed(editor_orientation_popup_label") or source.contains("var popup_size := Vector2(256.0, 86.0)") or source.contains("editor_orientation_popup_panel.move_to_front()"):
		_fail("main.gd should delegate editor orientation popup presentation planning.")
		return
	if source.contains("frame_button.visible = editor_panel_mode == \"load\"") or source.contains("template_toggle_button.text = (\"关闭模板\"") or source.contains("_set_control_position_if_changed(template_label, Vector2(936.0, 374.0)") or source.contains("_set_control_position_if_changed(template_button, Vector2(940.0 + float(visible_index % 2) * 134.0"):
		_fail("main.gd should delegate editor template drawer presentation planning.")
		return
	if source.contains("var marker := \"> \" if part_key == editor_selected_body_part and body_board_enabled else \"\"") or source.contains("var alarm := \"! \" if illegal_parts.has(part_key) else \"\"") or source.contains("_set_control_text_if_changed(button, \"%s%s%s\" % [marker, alarm, _body_part_label(part_key, unit_bp)])"):
		_fail("main.gd should delegate editor body-board button presentation planning.")
		return
	if source.contains("_set_button_disabled_if_changed(button, not body_board_enabled)") or source.contains("_set_control_text_if_changed(button, \"%s 零件库：仅机甲\"") or source.contains("_set_control_text_if_changed(button, _shop_slot_button_text(") or source.contains("_set_canvas_item_modulate_if_changed(button, Color(1.0, 0.86, 0.28, 1.0))"):
		_fail("main.gd should delegate editor body shop-slot button presentation planning.")
		return
	var board_ui_shop_block := _function_block(source, "func _update_editor_board_ui(")
	if board_ui_shop_block.find("_shop_slot_button_text(") >= 0 or board_ui_shop_block.find("%s 零件库：仅机甲") >= 0 or board_ui_shop_block.find("软件 x%d / 无体积") >= 0 or board_ui_shop_block.find("长 %.2f / 接口 %d") >= 0:
		_fail("_update_editor_board_ui should delegate body shop-slot text assembly.")
		return
	if source.contains("func _shop_slot_button_text("):
		_fail("main.gd should not keep the old body shop-slot text helper.")
		return
	if source.contains("_set_control_text_if_changed(side_button, \"编辑 P%d\"") or source.contains("_set_canvas_item_modulate_if_changed(side_button, Color(0.35, 0.95, 1.0, 1.0) if player_id == 1"):
		_fail("main.gd should delegate editor edit-side button presentation planning.")
		return
	if source.contains("_set_control_position_if_changed(button, Vector2(286.0 + float(key_index - 1) * 56.0, 618.0))") or source.contains("var label_prefix := \"试\" if bound_ready and not pending") or source.contains("_set_control_tooltip_if_changed(button, tip)") or source.contains("_set_canvas_item_modulate_if_changed(button, Color(0.42, 1.0, 0.76, 0.96) if bound_ready and not pending") or source.contains("button.z_index = MODULE_BINDING_TRYOUT_Z_INDEX") or source.contains("_set_canvas_item_visible_if_changed(side_button, false)"):
		_fail("main.gd should delegate editor module binding tryout button presentation planning.")
		return
	if source.contains("_set_canvas_item_visible_if_changed(side_button, should_show_side)") or source.contains("side_button.z_index = MODULE_BINDING_OVERLAY_Z_INDEX") or source.contains("_set_control_tooltip_if_changed(side_button, (\"选择%s后再绑定攻击键\"") or source.contains("_set_canvas_item_modulate_if_changed(side_button, Color(1.0, 0.86, 0.22, 1.0) if selected") or source.contains("_set_control_position_if_changed(key_button, key_rect.position)") or source.contains("key_button.z_index = MODULE_BINDING_OVERLAY_Z_INDEX") or source.contains("_set_control_text_if_changed(key_button, \"%d %s\"") or source.contains("_set_canvas_item_visible_if_changed(key_button, false)"):
		_fail("main.gd should delegate editor module binding overlay button presentation planning.")
		return
	if source.contains("var title := \"\"") or source.contains("_set_control_text_if_changed(label, title)") or source.contains("_set_control_text_if_changed(page_label, \"%d/%d\"") or source.contains("_set_canvas_item_visible_if_changed(editor_roster_prev_button, true)") or source.contains("_set_canvas_item_visible_if_changed(button, visible_entry)") or source.contains("_set_control_text_if_changed(button, (\"%02d + %s\"") or source.contains("_set_canvas_item_modulate_if_changed(button, Color(1.0, 0.86, 0.28, 1.0) if selected"):
		_fail("main.gd should delegate editor roster overview presentation planning.")
		return
	if source.contains("_set_control_text_if_changed(prev_button, \"<\")") or source.contains("_set_control_text_if_changed(next_button, \">\")") or source.contains("_set_control_position_if_changed(editor_catalog_page_label, Vector2(966.0, 654.0))") or source.contains("_set_control_size_if_changed(editor_catalog_page_label, Vector2(210.0, 22.0))") or source.contains("_set_control_position_if_changed(button, Vector2(936.0, 224.0 + float(i) * 34.0))") or source.contains("_set_control_position_if_changed(button, Vector2(936.0, 250.0 + float(i) * 34.0))") or source.contains("_set_control_text_if_changed(button, \"%s%02d %s%s  %s  ¥%d\"") or source.contains("_set_canvas_item_modulate_if_changed(button, Color(0.74, 1.0, 0.48, 1.0) if bool(entry.get(\"builtin_hero_preset\", false))"):
		_fail("main.gd should delegate editor load card button presentation planning.")
		return
	if source.contains("_set_control_position_if_changed(editor_save_unit_feedback_label, Vector2(270.0, 654.0))") or source.contains("_set_control_size_if_changed(editor_save_unit_feedback_label, Vector2(622.0, 26.0))") or source.contains("editor_save_unit_feedback_label.autowrap_mode = TextServer.AUTOWRAP_OFF") or source.contains("editor_save_unit_feedback_label.clip_text = true") or source.contains("editor_save_unit_feedback_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS"):
		_fail("main.gd should delegate editor save-unit feedback presentation planning.")
		return
	if source.contains("editor_unit_hover_view.position = Vector2(410.0, 118.0)") or source.contains("editor_unit_hover_view.size = Vector2(466.0, 500.0)") or source.contains("editor_unit_hover_view.visible = true") or source.contains("editor_unit_hover_view.move_to_front()"):
		_fail("main.gd should delegate editor unit hover view presentation planning.")
		return
	if source.contains("editor_hover_popup_view.z_index = 260") or source.contains("editor_hover_popup_view.size = Vector2(506.0, 560.0)") or source.contains("editor_hover_popup_view.size = Vector2(466.0, 500.0)") or source.contains("editor_hover_popup_view.position = _editor_hover_pinned_position") or source.contains("editor_hover_popup_view.position = Vector2(editor_torso_detail_view.position.x") or source.contains("editor_hover_popup_view.move_to_front()"):
		_fail("main.gd should delegate editor part hover popup presentation planning.")
		return
	if source.contains("editor_drag_ghost_view.visible = true") or source.contains("editor_drag_ghost_view.visible = false") or source.contains("editor_drag_ghost_view.mouse_filter = Control.MOUSE_FILTER_IGNORE") or source.contains("editor_drag_ghost_view.modulate = Color(1.0, 1.0, 1.0, 0.55)") or source.contains("editor_drag_ghost_view.z_index = 250") or source.contains("editor_drag_ghost_view.z_index = int(drag_ghost_view_build_spec.get(\"z_index\", 250))") or source.contains("editor_drag_ghost_view.position = mouse_position - editor_drag_ghost_view.size * 0.5") or source.contains("editor_drag_ghost_view.move_to_front()"):
		_fail("main.gd should delegate editor drag ghost view presentation planning.")
		return
	if source.contains("editor_stats_rail_view.position = stats_rail_view_build_spec.get") or source.contains("editor_stats_rail_view.size = stats_rail_view_build_spec.get") or source.contains("editor_stats_rail_view.mouse_filter = Control.MOUSE_FILTER_STOP") or source.contains("editor_stats_rail_view.visible = true"):
		_fail("main.gd should delegate editor stats rail view presentation planning.")
		return
	if source.contains("editor_perf_overlay_label.z_index = int(perf_overlay_build_spec.get") or source.contains("editor_perf_overlay_label.visible =") or source.contains("editor_perf_overlay_label.text =") or source.contains("editor_perf_overlay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART"):
		_fail("main.gd should delegate editor perf overlay presentation planning.")
		return
	if source.contains("editor_save_unit_name_panel.position = save_unit_panel_build_spec.get") or source.contains("editor_save_unit_name_panel.size = save_unit_panel_build_spec.get") or source.contains("editor_save_unit_name_panel.z_index = int(save_unit_panel_build_spec.get") or source.contains("editor_save_unit_name_panel.visible = true") or source.contains("editor_save_unit_name_panel.visible = false") or source.contains("editor_save_unit_name_panel.move_to_front()"):
		_fail("main.gd should delegate editor save-unit name panel presentation planning.")
		return
	for direct_control_mutation in ["_set_canvas_item_visible_if_changed(role_button, bool(role_button_plan", "_set_control_position_if_changed(group_button, group_plan", "_set_canvas_item_visible_if_changed(button, slot_visible)", "_set_button_disabled_if_changed(button, not slot_visible)", "_set_canvas_item_visible_if_changed(filter_button, bool(filter_plan", "_set_control_position_if_changed(filter_button, filter_plan", "_set_control_text_if_changed(sort_key_button, String(sort_plan.get(\"sort_key_text\", \"\")))", "_set_control_text_if_changed(sort_dir_button, String(sort_plan.get(\"sort_dir_text\", \"\")))", "_set_canvas_item_visible_if_changed(editor_sort_panel, bool(sort_panel_plan", "_set_canvas_item_visible_if_changed(sort_option_button, show_sort_option)", "_set_control_position_if_changed(sort_option_button, sort_option_plan", "sort_dir_front.move_to_front()", "_set_canvas_item_visible_if_changed(editor_unit_label, bool(info_unit_plan", "_set_control_position_if_changed(editor_unit_label, info_unit_plan", "_set_canvas_item_visible_if_changed(editor_summary_label, bool(info_summary_plan", "_set_canvas_item_visible_if_changed(editor_catalog_page_label, bool(Dictionary(info_plan.get(\"catalog_page\", {})).get(\"visible\", false)))", "_set_canvas_item_visible_if_changed(catalog_title, bool(Dictionary(info_plan.get(\"catalog_title\", {})).get(\"visible\", false)))", "_set_canvas_item_visible_if_changed(action_button, action_visible)", "_set_canvas_item_visible_if_changed(editor_stats_label, bool(info_stats_plan", "_set_control_text_if_changed(color_button, String(color_button_plan"]:
		if source.contains(direct_control_mutation):
			_fail("main.gd should apply extracted editor plans through _apply_editor_control_plan instead of %s." % direct_control_mutation)
			return
	if source.contains("var filter_columns := 5 if editor_part_group_mode == \"terminal_weapon\" else 3"):
		_fail("main.gd should delegate part-filter button layout planning.")
	if source.contains("var group_index := EDITOR_PART_GROUP_ORDER.find(String(group_key))"):
		_fail("main.gd should delegate part-group button layout planning.")
	if source.contains("editor_ammo_size_slider.editable = ammo_slider_visible") or source.contains("安装弹药时选择弹仓尺寸；弹数、价格、质量和槽位体积同步增加。"):
		_fail("main.gd should delegate ammo-size control presentation planning.")
	if source.contains("var visible_sort_index := 0") or source.contains("var sort_rows := int(ceilf(float(maxi(1, available_sort_keys.size())) / 3.0))") or source.contains("Vector2(940.0 + float(visible_sort_index % 3) * 88.0"):
		_fail("main.gd should delegate sort control presentation planning.")
	if source.contains("_set_control_position_if_changed(editor_unit_label, Vector2(936.0, 186.0))") or source.contains("_set_canvas_item_visible_if_changed(component_art_view, stats_visible)") or source.contains("editor_structure_reference_view.visible = editor_structure_reference_view.visible and stats_visible") or source.contains("_set_canvas_item_visible_if_changed(editor_catalog_page_label, (parts_visible and not editor_sort_menu_open) or load_visible)"):
		_fail("main.gd should delegate editor info panel presentation planning.")
	if source.contains("流程：1 选构件类型  2 拖卡片进画布  3 磁吸贴合；引擎/散热/行动模块点击安装。") or source.contains("No pending physical part; drag or choose a muscle component and this line lights up.") or source.contains("_set_canvas_item_modulate_if_changed(editor_shop_pending_label, Color(1.0, 0.78, 0.30, 1.0))"):
		_fail("main.gd should delegate editor shop feedback presentation planning.")
	if source.contains("\"P%d 队伍颜色：%s\" % [_editor_player(), _team_color_name(_editor_player())]") or source.contains("var selected := i == _team_color_index(_editor_player())") or source.contains("editor_primary_color_picker.text = \"主色\" if _ui_is_zh() else \"PRIMARY\""):
		_fail("main.gd should delegate editor color control presentation planning.")
	if source.contains("editor_primary_color_picker.color = _team_primary_color(_editor_player())") or source.contains("editor_accent_color_picker.color = _team_accent_color(_editor_player())"):
		_fail("main.gd should consume picker color sync values from UILifecycleService editor color plans.")
	if source.contains("label.text = \"零件卡片\" if _ui_is_zh() else \"PART CARDS\"") or source.contains("label.text = \"零件库：悬停显示完整卡片\" if _ui_is_zh() else \"PARTS: HOVER FOR FULL CARD\"") or source.contains("template_toggle.text = \"模板抽屉\" if _ui_is_zh() else \"TEMPLATE DRAWER\""):
		_fail("main.gd should delegate editor section chrome presentation planning.")
	if source.contains("button.visible = button.visible and parts_visible") or source.contains("shop_button.visible = shop_visible and body_board_enabled") or source.contains("editor_shop_card_backdrop.visible = shop_visible") or source.contains("not (parts_visible or shop_visible)"):
		_fail("main.gd should delegate editor catalog/shop surface presentation planning.")
	print("MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=%d" % required_files.size())
	quit()
