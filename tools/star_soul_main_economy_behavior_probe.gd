extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BPService := preload("res://scripts/services/star_soul_bp_service.gd")

var failed := false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var bp_service = BPService.new()
	var catalog: Dictionary = bp_service.catalog_by_id()
	_check_owner_economy_rate(main, bp_service, catalog, "lord_a", "star_soul_economy_rate_mult", 1.2, "Lord")
	_check_owner_economy_rate(main, bp_service, catalog, "tyrant_a", "star_soul_owner_economy_rate_mult", 0.8, "Tyrant")
	if failed:
		quit(1)
		return
	print("STAR_SOUL_MAIN_ECONOMY_BEHAVIOR_PROBE ok")
	quit(0)


func _check_owner_economy_rate(main, bp_service, catalog: Dictionary, star_soul_id: String, stat_key: String, expected_mult: float, label: String) -> void:
	_spawn_star_soul(main, bp_service, catalog, star_soul_id, "star_soul_main_economy_behavior_probe_%s" % star_soul_id)
	_require(main.active_star_soul_units.size() == 1, "%s probe should spawn one active Star Soul." % label)
	if main.active_star_soul_units.is_empty():
		return
	var star_soul = main.active_star_soul_units[0]
	_require(is_equal_approx(float(star_soul.stats.get(stat_key, 1.0)), expected_mult), "%s should carry its owner economy rate stat." % label)
	main.runtime_resource[1] = 0.0
	main.runtime_resource[2] = 0.0
	main._tick_battle_simulation(1.0)
	var expected_owner_gain := MainScene.RESOURCE_GAIN_PER_SECOND * expected_mult
	var expected_other_gain := MainScene.RESOURCE_GAIN_PER_SECOND
	_require(_nearly_equal(float(main.runtime_resource[1]), expected_owner_gain), "%s should multiply owner resource gain to %.2f, got %.2f." % [label, expected_owner_gain, float(main.runtime_resource[1])])
	_require(_nearly_equal(float(main.runtime_resource[2]), expected_other_gain), "%s should not change opponent resource gain, got %.2f." % [label, float(main.runtime_resource[2])])


func _spawn_star_soul(main, bp_service, catalog: Dictionary, star_soul_id: String, reason: String) -> void:
	main._begin_battle(MainScene.MODE_PVP, true, reason)
	var payload: Dictionary = bp_service.build_spawn_queue([
		{"player": 1, "star_soul_id": star_soul_id},
		{"player": 2, "star_soul_id": "defense_tower_a"},
	], 1, 1, {"pool_ids": catalog.keys(), "announce_seconds": 10.0})
	_require(bool(payload.get("valid", false)), "Economy probe BP payload should be valid for %s." % star_soul_id)
	main.battle_controller.start_star_soul_runtime(payload, catalog, {"replay_seed": 59})
	main._tick_star_soul_runtime(10.0)


func _nearly_equal(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= 0.01


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
