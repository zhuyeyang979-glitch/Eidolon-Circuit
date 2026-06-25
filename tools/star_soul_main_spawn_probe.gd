extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BPService := preload("res://scripts/services/star_soul_bp_service.gd")

var failed := false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._begin_battle(MainScene.MODE_PVP, true, "star_soul_main_spawn_probe")

	var bp_service = BPService.new()
	var catalog: Dictionary = bp_service.catalog_by_id()
	var payload: Dictionary = bp_service.build_spawn_queue([
		{"player": 1, "star_soul_id": "defense_tower_c"},
		{"player": 2, "star_soul_id": "punishment_tower_a"},
	], 1, 1, {"pool_ids": catalog.keys(), "announce_seconds": 10.0})
	_require(bool(payload.get("valid", false)), "Probe BP payload should be valid.")
	main.battle_controller.start_star_soul_runtime(payload, catalog, {"replay_seed": 17})
	main._tick_star_soul_runtime(10.0)

	_require(main.active_star_soul_units.size() == 1, "Ticking countdown should spawn exactly one Star Soul.")
	if main.active_star_soul_units.is_empty():
		quit(1)
		return
	var star_soul = main.active_star_soul_units[0]
	_require(star_soul != null and is_instance_valid(star_soul), "Spawned Star Soul instance should be valid.")
	_require(String(star_soul.role) == "star_soul", "Spawned unit role should be star_soul.")
	_require(bool(star_soul.get_meta("star_soul", false)), "Spawned Star Soul should carry star_soul metadata.")
	_require(String(star_soul.get_meta("star_soul_id", "")) == "defense_tower_c", "Spawned Star Soul should match first queue entry.")
	_require(main.all_units.has(star_soul), "Spawned Star Soul should be part of all_units.")
	_require(is_equal_approx(float(star_soul.ring_pos), 0.0), "P1 own-spawn Star Soul should spawn at ring 0.")

	var active_entry: Dictionary = Dictionary(main.battle_controller.star_soul_runtime_snapshot().get("active_entry", {}))
	_require(String(active_entry.get("star_soul_id", "")) == "defense_tower_c", "Controller should mark spawned Star Soul active.")
	_require(String(active_entry.get("runtime_id", "")) == String(star_soul.get_meta("star_soul_runtime_id", "")), "Runtime id should match spawned entity metadata.")
	_require(main._enemy_units(2).has(star_soul), "P2 enemy target list should include the active P1 Star Soul.")
	var awareness: Dictionary = main._battle_awareness_active_unit_data()
	_require(_snapshot_has_unit(Array(awareness.get("snapshots", [])), int(star_soul.get_instance_id())), "Awareness snapshots should include active Star Soul.")
	var hud_snapshot: Dictionary = main._battle_hud_text_snapshot()
	_require(String(Dictionary(hud_snapshot.get("star_soul_runtime", {})).get("phase", "")) == "active", "HUD snapshot should expose active Star Soul runtime.")

	main._handle_unit_killed(star_soul, 2)
	_require(main.active_star_soul_units.is_empty(), "Killed Star Soul should leave active_star_soul_units.")
	_require(not main.all_units.has(star_soul), "Killed Star Soul should be detached from all_units.")
	_require(int(main.victory_points.get(2, 0)) == 3, "Destroying P1 defense_tower_c should award P2 three VP.")
	var next_state: Dictionary = main.battle_controller.star_soul_runtime_snapshot()
	_require(String(next_state.get("phase", "")) == "announcing", "Runtime should announce the next Star Soul after a kill.")
	_require(String(Dictionary(next_state.get("pending_entry", {})).get("star_soul_id", "")) == "punishment_tower_a", "Next pending Star Soul should be P2's pick.")

	if failed:
		quit(1)
		return
	print("STAR_SOUL_MAIN_SPAWN_PROBE ok vp=%s next=%s" % [str(main.victory_points), str(Dictionary(next_state.get("pending_entry", {})).get("star_soul_id", ""))])
	quit(0)


func _snapshot_has_unit(snapshots: Array, id: int) -> bool:
	for raw_snapshot in snapshots:
		if raw_snapshot is Dictionary and int(Dictionary(raw_snapshot).get("id", -1)) == id:
			return true
	return false


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
