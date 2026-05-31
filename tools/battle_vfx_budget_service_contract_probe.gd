extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleVfxBudgetService := preload("res://scripts/services/battle_vfx_budget_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/battle_vfx_budget_service.gd")
	if source.is_empty():
		_fail("Unable to read BattleVfxBudgetService.")
		return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "active_units", "all_units", "_spawn_", "BattleContactVfxPool"]:
		if source.contains(forbidden):
			_fail("BattleVfxBudgetService contains forbidden token: %s" % forbidden)
			return
	var service := BattleVfxBudgetService.new()
	if service.consume_code("projectile_trace", 0, 0, 0, 2, 1, 2) != BattleVfxBudgetService.RESULT_ACCEPTED_PROJECTILE_TRACE:
		_fail("consume_code did not classify projectile trace acceptance.")
		return
	if service.consume_code("projectile_trace", 1, 1, 0, 2, 1, 2) != BattleVfxBudgetService.RESULT_DROP_KIND_LIMIT:
		_fail("consume_code did not classify projectile trace kind cap.")
		return
	var quality := {"battle_vfx_budget": 4, "projectile_trace_budget": 2, "hit_effect_budget": 3}
	var state := service.reset_frame_state({"drop_count": 5})
	if int(state.get("drop_count", 0)) != 5 or int(state.get("spawn_count", -1)) != 0:
		_fail("reset_frame_state should reset frame counts while preserving drops: %s" % str(state))
		return
	var accepted_projectiles := 0
	for _i in range(3):
		var intent: Dictionary = service.consume_intent("projectile_trace", state, quality)
		state = Dictionary(intent.get("state", {}))
		if bool(intent.get("accepted", false)):
			accepted_projectiles += 1
	if accepted_projectiles != 2 or int(state.get("drop_count", 0)) != 6:
		_fail("Projectile trace kind cap mismatch accepted=%d state=%s" % [accepted_projectiles, str(state)])
		return
	var hit_intent: Dictionary = service.consume_intent("hit_effect", state, quality)
	state = Dictionary(hit_intent.get("state", {}))
	if not bool(hit_intent.get("accepted", false)):
		_fail("Hit effect should still be accepted after projectile cap: %s" % str(hit_intent))
		return
	var unknown_intent: Dictionary = service.consume_intent("custom_vfx", state, quality)
	state = Dictionary(unknown_intent.get("state", {}))
	if not bool(unknown_intent.get("accepted", false)):
		_fail("Unknown VFX kind should consume only the global budget: %s" % str(unknown_intent))
		return
	var capped_intent: Dictionary = service.consume_intent("custom_vfx", state, quality)
	if bool(capped_intent.get("accepted", false)) or String(capped_intent.get("reason", "")) != "total_limit":
		_fail("Global budget cap did not reject overflow: %s" % str(capped_intent))
		return
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"scripts/services/battle_vfx_budget_service.gd",
		"BattleVfxBudgetService.new",
		"battle_vfx_budget_service.reset_frame_state",
		"battle_vfx_budget_service.consume_code",
		"_battle_vfx_quality_values",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing BattleVfxBudgetService boundary token: %s" % token)
			return
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._apply_performance_profile("compat_60", false)
	main._reset_battle_vfx_frame_budget()
	var accepted := 0
	for _i in range(200):
		if main._consume_battle_vfx_budget("projectile_trace"):
			accepted += 1
	var limit := int(main._runtime_quality_value("projectile_trace_budget", 0))
	if accepted != limit:
		_fail("main.gd wrapper accepted %d projectile traces, expected %d." % [accepted, limit])
		return
	if int(main.battle_vfx_budget_drop_count) <= 0:
		_fail("main.gd wrapper did not preserve drop accounting.")
		return
	print("BATTLE_VFX_BUDGET_SERVICE_CONTRACT_PROBE ok")
	quit(0)
