extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BPService := preload("res://scripts/services/star_soul_bp_service.gd")

var failed := false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._begin_battle(MainScene.MODE_PVP, true, "star_soul_main_behavior_probe")
	var bp_service = BPService.new()
	var catalog: Dictionary = bp_service.catalog_by_id()
	var payload: Dictionary = bp_service.build_spawn_queue([
		{"player": 1, "star_soul_id": "punishment_tower_c"},
		{"player": 2, "star_soul_id": "defense_tower_a"},
	], 1, 1, {"pool_ids": catalog.keys(), "announce_seconds": 10.0})
	main.battle_controller.start_star_soul_runtime(payload, catalog, {"replay_seed": 31})
	main._tick_star_soul_runtime(10.0)
	_require(main.active_star_soul_units.size() == 1, "Probe should spawn one active Star Soul.")
	if main.active_star_soul_units.is_empty():
		quit(1)
		return
	var tower = main.active_star_soul_units[0]
	var enemy_hero = main.active_units[2]["hero"]
	enemy_hero.max_health = 100
	enemy_hero.health = 100
	enemy_hero.ring_pos = tower.ring_pos
	enemy_hero.lane = tower.lane
	var before := int(enemy_hero.health)
	main._tick_star_soul_runtime(0.65)
	_require(int(enemy_hero.health) < before, "Punishment tower should damage an enemy hero standing inside its area.")
	_require(float(enemy_hero.get_meta("star_soul_debuff_timer", 0.0)) > 0.0, "Punishment tower should mark the affected enemy with a debuff timer.")
	if failed:
		quit(1)
		return
	print("STAR_SOUL_MAIN_BEHAVIOR_PROBE ok hp=%d->%d" % [before, int(enemy_hero.health)])
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
