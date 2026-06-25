extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BPService := preload("res://scripts/services/star_soul_bp_service.gd")

var failed := false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._begin_battle(MainScene.MODE_PVP, true, "star_soul_main_coward_behavior_probe")
	var bp_service = BPService.new()
	var catalog: Dictionary = bp_service.catalog_by_id()
	var payload: Dictionary = bp_service.build_spawn_queue([
		{"player": 1, "star_soul_id": "coward_a"},
		{"player": 2, "star_soul_id": "defense_tower_a"},
	], 1, 1, {"pool_ids": catalog.keys(), "announce_seconds": 10.0})
	main.battle_controller.start_star_soul_runtime(payload, catalog, {"replay_seed": 61})
	main._tick_star_soul_runtime(10.0)
	_require(main.active_star_soul_units.size() == 1, "Probe should spawn one coward Star Soul.")
	if main.active_star_soul_units.is_empty():
		quit(1)
		return
	var coward = main.active_star_soul_units[0]
	var nearby_hero = main.active_units[1]["hero"]
	var far_enemy = main.active_units[2]["hero"]
	coward.max_health = 100
	coward.health = 100
	nearby_hero.max_health = 100
	nearby_hero.health = 100
	far_enemy.max_health = 100
	far_enemy.health = 100
	_place_unit(nearby_hero, coward.ring_pos + 0.18, coward.lane)
	_place_unit(far_enemy, coward.ring_pos + 4.0, coward.lane)
	var coward_ring_before := float(coward.ring_pos)
	var coward_hp_before := int(coward.health)
	var nearby_hp_before := int(nearby_hero.health)
	main._tick_star_soul_runtime(0.65)
	_require(int(coward.health) < coward_hp_before, "Coward should lose health when a unit from either side stands inside its area.")
	_require(int(nearby_hero.health) == nearby_hp_before, "Coward health-loss area should not damage the nearby player unit.")
	_require(_ring_delta(coward_ring_before, float(coward.ring_pos), MainScene.RING_LENGTH) < -0.01, "Coward should flee away from the nearest unit.")
	if failed:
		quit(1)
		return
	print("STAR_SOUL_MAIN_COWARD_BEHAVIOR_PROBE ok hp=%d->%d ring=%.2f->%.2f" % [coward_hp_before, int(coward.health), coward_ring_before, float(coward.ring_pos)])
	quit(0)


func _ring_delta(from_ring: float, to_ring: float, ring_length: float) -> float:
	var delta := to_ring - from_ring
	var half := ring_length * 0.5
	if delta > half:
		delta -= ring_length
	elif delta < -half:
		delta += ring_length
	return delta


func _place_unit(unit, ring: float, lane: float) -> void:
	unit.ring_pos = ring
	unit.lane = lane
	if unit.get("mobius_s") != null:
		unit.set("mobius_s", ring)
	if unit.get("mobius_v") != null:
		unit.set("mobius_v", lane)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
