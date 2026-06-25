extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BPService := preload("res://scripts/services/star_soul_bp_service.gd")

var failed := false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._begin_battle(MainScene.MODE_PVP, true, "star_soul_main_chaser_behavior_probe")
	var bp_service = BPService.new()
	var catalog: Dictionary = bp_service.catalog_by_id()
	var payload: Dictionary = bp_service.build_spawn_queue([
		{"player": 1, "star_soul_id": "wandering_giant_a"},
		{"player": 2, "star_soul_id": "defense_tower_a"},
	], 1, 1, {"pool_ids": catalog.keys(), "announce_seconds": 10.0})
	main.battle_controller.start_star_soul_runtime(payload, catalog, {"replay_seed": 47})
	main._tick_star_soul_runtime(10.0)
	_require(main.active_star_soul_units.size() == 1, "Probe should spawn one wandering giant.")
	if main.active_star_soul_units.is_empty():
		quit(1)
		return
	var giant = main.active_star_soul_units[0]
	var p1_hero = main.active_units[1]["hero"]
	var p2_hero = main.active_units[2]["hero"]
	for hero in [p1_hero, p2_hero]:
		hero.max_health = 100
		hero.health = 100
		hero.lane = giant.lane
	p1_hero.ring_pos = giant.ring_pos + 0.18
	p2_hero.ring_pos = giant.ring_pos + 0.42
	var p1_before := int(p1_hero.health)
	var p2_before := int(p2_hero.health)
	main._tick_star_soul_runtime(0.65)
	_require(int(p1_hero.health) < p1_before, "Wandering giant should damage the closest unit regardless of side.")
	_require(int(p2_hero.health) == p2_before, "Wandering giant should only damage its nearest melee target on one swing.")
	_require(float(p1_hero.get_meta("star_soul_damage_timer", 0.0)) > 0.0, "Chaser hit should mark target with Star Soul damage timing.")
	if failed:
		quit(1)
		return
	print("STAR_SOUL_MAIN_CHASER_BEHAVIOR_PROBE ok p1=%d->%d p2=%d->%d" % [p1_before, int(p1_hero.health), p2_before, int(p2_hero.health)])
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
