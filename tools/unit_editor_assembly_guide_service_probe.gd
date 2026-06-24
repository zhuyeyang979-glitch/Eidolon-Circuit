extends SceneTree

const SERVICE_PATH := "res://scripts/services/unit_editor_assembly_guide_service.gd"

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _titles(steps: Array, zh: bool) -> Array:
	var result: Array = []
	for raw_step in steps:
		if raw_step is Dictionary:
			var step: Dictionary = raw_step
			result.append(String(step.get("zh_title" if zh else "en_title", "")))
	return result


func _assert_no_legacy_copy(steps: Array) -> void:
	for raw_step in steps:
		if not (raw_step is Dictionary):
			continue
		var step: Dictionary = raw_step
		for field in ["zh_title", "zh_instruction", "en_title", "en_instruction"]:
			var text := String(step.get(field, ""))
			for forbidden in ["躯干", "肢体", "装备", "TORSO", "LIMB", "EQUIPMENT", "BOOSTER"]:
				if text.find(forbidden) >= 0:
					_fail("Assembly guide field %s contains legacy category copy %s: %s" % [field, forbidden, text])


func _assert_catalog_state(state: Dictionary, group_key: String, filter_key: String, slot_index: int) -> void:
	if not bool(state.get("valid", false)):
		_fail("Catalog state should be valid for %s/%s: %s" % [group_key, filter_key, str(state)])
	if String(state.get("part_group_mode", "")) != group_key:
		_fail("Catalog state group mismatch: expected %s got %s." % [group_key, String(state.get("part_group_mode", ""))])
	if String(state.get("part_filter_mode", "")) != filter_key:
		_fail("Catalog state filter mismatch: expected %s got %s." % [filter_key, String(state.get("part_filter_mode", ""))])
	if int(state.get("slot_index", -1)) != slot_index:
		_fail("Catalog state slot index mismatch: expected %d got %d." % [slot_index, int(state.get("slot_index", -1))])


func _init() -> void:
	var script := load(SERVICE_PATH)
	if script == null:
		_fail("Missing UnitEditorAssemblyGuideService script.")
		quit(1)
		return
	var service = script.new()
	var build_slots := ["special", "limb_muscle", "muscle", "booster", "engine", "cooling", "module"]
	var hero_steps: Array = service.steps_for_role("hero")
	_assert_no_legacy_copy(hero_steps)
	if hero_steps.size() != 9:
		_fail("Hero guide should expose nine recommended assembly steps, got %d." % hero_steps.size())
	var expected_zh := ["核心", "连接件", "武器", "连接", "引擎", "热力/散热", "推进器", "英魂", "行动模块"]
	if _titles(hero_steps, true) != expected_zh:
		_fail("Hero guide should use the beginner-friendly order: %s." % str(_titles(hero_steps, true)))
	var expected_en := ["CORE", "CONNECTOR", "WEAPON", "CONNECT", "ENGINE", "HEAT/RADIATOR", "THRUSTER", "SOUL", "ACTION"]
	if _titles(hero_steps, false) != expected_en:
		_fail("Hero guide English labels should be compact and ordered: %s." % str(_titles(hero_steps, false)))
	var connection_model: Dictionary = service.step_model("hero", 3, true)
	if String(connection_model.get("key", "")) != "connection":
		_fail("Step 4 should be the connection step, got %s." % str(connection_model))
	if String(connection_model.get("instruction", "")).find("自动连接") < 0:
		_fail("Connection step should explicitly point players to Auto Connect.")
	for key in ["function_text", "limit_text", "next_action_text", "tutorial_text"]:
		if String(connection_model.get(key, "")).strip_edges() == "":
			_fail("Connection step should expose tutorial field %s." % key)
	if String(connection_model.get("tutorial_text", "")).find("作用") < 0 or String(connection_model.get("tutorial_text", "")).find("限制") < 0 or String(connection_model.get("tutorial_text", "")).find("下一步") < 0:
		_fail("Tutorial text should explain function, limits, and next action: %s." % String(connection_model.get("tutorial_text", "")))
	_assert_catalog_state(service.catalog_state_for_step("hero", 0, build_slots), "torso", "connector_torso", 2)
	_assert_catalog_state(service.catalog_state_for_step("hero", 1, build_slots), "limb", "connector_limb", 1)
	_assert_catalog_state(service.catalog_state_for_step("hero", 2, build_slots), "terminal_weapon", "weapon_all", 2)
	var connection_state: Dictionary = service.catalog_state_for_step("hero", 3, build_slots)
	if not bool(connection_state.get("valid", false)) or String(connection_state.get("action_key", "")) != "auto_connect" or int(connection_state.get("slot_index", 0)) != -1:
		_fail("Connection step should expose an Auto Connect action state, got %s." % str(connection_state))
	_assert_catalog_state(service.catalog_state_for_step("hero", 4, build_slots), "software_muscle", "engine", 4)
	_assert_catalog_state(service.catalog_state_for_step("hero", 5, build_slots), "software_muscle", "cooling", 5)
	_assert_catalog_state(service.catalog_state_for_step("hero", 6, build_slots), "software_muscle", "booster", 3)
	_assert_catalog_state(service.catalog_state_for_step("hero", 7, build_slots), "software", "soul", 0)
	_assert_catalog_state(service.catalog_state_for_step("hero", 8, build_slots), "software", "module", 6)
	_assert_catalog_state(service.catalog_state_for_step("puppet", 7, build_slots), "software", "code", 0)
	_assert_catalog_state(service.catalog_state_for_step("barrier", 1, build_slots), "software", "ether", 0)
	var barrier_steps: Array = service.steps_for_role("barrier")
	_assert_no_legacy_copy(barrier_steps)
	if _titles(barrier_steps, true).is_empty() or String(_titles(barrier_steps, true)[0]) != "功能模块":
		_fail("Barrier guide should start with 功能模块.")
	var cooling_index: int = int(service.step_index_for_catalog_state("hero", "software_muscle", "cooling", 0))
	if cooling_index != 5:
		_fail("Manual cooling filter selection should sync guide to step 6, got %d." % cooling_index)
	var gun_index: int = int(service.step_index_for_catalog_state("hero", "terminal_weapon", "gun_rifle", 0))
	if gun_index != 2:
		_fail("Manual gun subtype selection should sync guide to weapon step, got %d." % gun_index)
	var ranged_module_index: int = int(service.step_index_for_catalog_state("hero", "software", "module_ranged", 0))
	if ranged_module_index != 8:
		_fail("Manual module subtype selection should sync guide to action-module step, got %d." % ranged_module_index)
	var preserved_index: int = int(service.step_index_for_catalog_state("hero", "software_muscle", "ammo", 3))
	if preserved_index != 3:
		_fail("Unsupported custom filter should preserve current guide index, got %d." % preserved_index)
	var first_model: Dictionary = service.step_model("hero", 0, true)
	if String(first_model.get("custom_order_note", "")).find("自由") < 0:
		_fail("Step model should explicitly preserve custom assembly order in Chinese copy.")
	if String(first_model.get("tutorial_text", "")).find("核心") < 0 or String(first_model.get("limit_text", "")).find("接口") < 0:
		_fail("Core tutorial should explain core ports and limits: %s." % String(first_model.get("tutorial_text", "")))
	var last_model: Dictionary = service.step_model("hero", 8, false)
	if String(last_model.get("tutorial_text", "")).find("Function") < 0 or String(last_model.get("tutorial_text", "")).find("Limit") < 0 or String(last_model.get("tutorial_text", "")).find("Next") < 0:
		_fail("English tutorial text should expose Function/Limit/Next sections: %s." % String(last_model.get("tutorial_text", "")))
	if bool(last_model.get("can_next", true)):
		_fail("Last recommended step should not enable next.")
	if not bool(first_model.get("can_next", false)):
		_fail("First recommended step should enable next.")
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_ASSEMBLY_GUIDE_SERVICE_PROBE ok")
	quit(0)
