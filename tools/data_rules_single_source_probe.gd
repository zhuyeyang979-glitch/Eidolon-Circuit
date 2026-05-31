extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const DataRuleService := preload("res://scripts/services/data_rule_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var rules := DataRuleService.new()
	if absf(rules.engine_output(10.0) - 10.0 * DataRuleService.ENGINE_MOMENTUM_OUTPUT_SCALE) > 0.001:
		_fail("Engine output is not governed by DataRuleService.")
		return
	if absf(rules.allocation_max(12.0) - 12.0 * DataRuleService.THRUSTER_ALLOCATION_MAX_MULT) > 0.001:
		_fail("Thruster allocation range is not governed by DataRuleService.")
		return
	if absf(rules.cooling_pool_capacity(10.0, false) - 10.0 * DataRuleService.COOLING_POOL_SCALE) > 0.001:
		_fail("Cooling pool scale is not governed by DataRuleService.")
		return
	var canonical_engine := rules.canonical_catalog_part({"kind": "engine", "hp": 12, "engine_momentum_output": 4.0}, "engine")
	if canonical_engine.has("hp"):
		_fail("Equipment canonical model still keeps HP.")
		return
	var canonical_module := rules.canonical_catalog_part({"module_action_profile": "test", "normal_damage": 99}, "module")
	if canonical_module.has("normal_damage"):
		_fail("Action module canonical model still keeps damage.")
		return
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main.data_rule_service == null:
		_fail("Main does not initialize DataRuleService.")
		return
	if absf(main._engine_momentum_output_for_part({"engine_momentum_output": 10.0}) - rules.engine_output(10.0)) > 0.001:
		_fail("Main engine wrapper bypasses DataRuleService.")
		return
	print("DATA_RULES_SINGLE_SOURCE_PROBE ok engine_scale=%.1f cooling_scale=%.1f" % [DataRuleService.ENGINE_MOMENTUM_OUTPUT_SCALE, DataRuleService.COOLING_POOL_SCALE])
	quit()
