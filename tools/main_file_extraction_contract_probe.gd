extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


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
	for delegated in ["LoadingLifecycleService.prepare_task", "LoadingLifecycleService.queue_deferred_idle_tasks", "UILifecycleService.layer_snapshot", "UILifecycleService.trim_dictionary_cache", "UILifecycleService.editor_action_build_specs", "UILifecycleService.editor_panel_visibility_plan", "UILifecycleService.editor_action_state", "UILifecycleService.editor_action_presentation", "UILifecycleService.editor_part_group_button_presentation", "UILifecycleService.editor_part_filter_button_presentation", "UILifecycleService.editor_ammo_size_control_presentation", "UILifecycleService.editor_sort_controls_presentation", "UILifecycleService.editor_info_panel_presentation", "UILifecycleService.editor_shop_feedback_presentation", "UILifecycleService.editor_color_controls_presentation", "UILifecycleService.editor_section_chrome_presentation", "_unit_stats_service().copy_part_logic_stats", "_unit_stats_service().copy_part_combat_stats", "_unit_stats_service().copy_part_payload_stats", "_unit_stats_service().part_payload_context(", "_unit_stats_service().torso_payload_context(", "_unit_stats_service().normalize_size_tier_label(", "_unit_stats_service().size_tier_rank(", "_unit_stats_service().size_tier_from_footprint(", "_unit_stats_service().part_size_tier_label(", "_unit_stats_service().component_is_torso(", "_unit_stats_service().component_is_brain_torso(", "_unit_stats_service().torso_size_rank_for_slots(", "_unit_stats_service().torso_baseline_slot_capacity(", "_unit_stats_service().torso_plugin_capacity_for_part(", "_unit_stats_service().torso_software_capacity_for_part(", "_unit_stats_service().economy_median_mass_for_rank(", "_unit_stats_service().thruster_drive_demand_for_part(", "_unit_stats_service().thruster_move_efficiency_for_part(", "_unit_stats_service().thruster_boost_efficiency_for_part(", "_unit_stats_service().booster_normal_momentum_for_part(", "_unit_stats_service().booster_boost_momentum_for_part(", "_unit_stats_service().thruster_boost_total_momentum_for_part(", "_unit_stats_service().payload_slot_key_for_kind(", "_unit_stats_service().payload_catalog_selection(", "_unit_stats_service().volume_tier_rank(", "_unit_stats_service().volume_rank_from_value(", "_unit_stats_service().payload_slot_volume_rank(", "_unit_stats_service().part_slot_volume_rank(", "_unit_stats_service().internal_slot_accepts_payload(", "_unit_stats_service().torso_internal_slot_size_ranks(", "_unit_stats_service().best_internal_slot_for_payload(", "_unit_stats_service().cooling_tags_for_part(", "_unit_stats_service().movement_profile_priority(", "_unit_stats_service().apply_torso_payload_direct_stats", "_unit_stats_service().record_torso_payload_summary_entry", "_unit_stats_service().torso_payload_processing_plan", "_unit_stats_service().apply_torso_payload_plan", "_unit_stats_service().apply_ether_payload_stats", "_unit_stats_service().apply_soul_heat_capacity_stats", "_unit_stats_service().apply_soul_bonus_stats", "_unit_stats_service().apply_internal_payload_merge_plan", "_unit_stats_service().apply_internal_engine_payload_stats", "_unit_stats_service().apply_internal_cooling_payload_stats", "_unit_stats_service().apply_internal_thruster_drive_stats", "_unit_stats_service().apply_torso_payload_summary", "_unit_stats_service().apply_base_motion_envelope", "_unit_stats_service().apply_role_deploy_profile", "_unit_stats_service().apply_manufacturer_discount"]:
		if source.find(delegated) < 0:
			_fail("main.gd should delegate extracted glue through %s." % delegated)
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
	if source.contains("var panel_specs := [") or source.contains("var board_primary_actions := [") or source.contains("var canvas_tools := [") or source.contains("var zoom_button_specs := ["):
		_fail("main.gd should delegate editor action build specs.")
	if source.contains("sort_prev_button.text = \"<\"") or source.contains("template_menu_button.text = \"导入模板\""):
		_fail("main.gd should delegate sort/template action build specs.")
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
	if source.contains("label.text = \"零件卡片\" if _ui_is_zh() else \"PART CARDS\"") or source.contains("label.text = \"零件库：悬停显示完整卡片\" if _ui_is_zh() else \"PARTS: HOVER FOR FULL CARD\"") or source.contains("template_toggle.text = \"模板抽屉\" if _ui_is_zh() else \"TEMPLATE DRAWER\""):
		_fail("main.gd should delegate editor section chrome presentation planning.")
	print("MAIN_FILE_EXTRACTION_CONTRACT_PROBE ok services=%d" % required_files.size())
	quit()
