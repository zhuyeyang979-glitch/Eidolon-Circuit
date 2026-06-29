extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const BattleTerrainServiceScript := preload("res://scripts/services/battle_terrain_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _expect_close(actual: float, expected: float, message: String, epsilon: float = 0.001) -> bool:
	return _expect(absf(actual - expected) <= epsilon, "%s expected %.4f got %.4f" % [message, expected, actual])


func _surface_snapshot() -> Dictionary:
	var terrain_service = BattleTerrainServiceScript.new()
	return terrain_service.arena_snapshot({
		"arena_id": "terrain_surface_runtime_probe",
		"version": 1,
		"features": [
			{
				"id": "slick-floor",
				"name": "SLICK COOLANT FLOOR",
				"kind": "floor",
				"collider": {"shape": "circle", "center": Vector2(4.0, -0.25), "radius": 0.58},
				"orientation": Vector2(1.0, 0.0),
				"surface_tags": ["floor", "slick", "coolant"],
				"effect_channels": ["surface"],
				"metadata": {
					"speed_mult": 0.5,
					"response_rate": 10.0,
					"cooling_rate": 12.0,
					"push": 0.4,
				},
			},
		],
	})


func _spawn_hero(main, owner: int, name: String, ring: float, lane: float):
	var stats := {
		"name": name,
		"health": 100,
		"max_health": 100,
		"mass": 12.0,
		"radius": 0.18,
		"heat_capacity": 100.0,
		"speed": 4.0,
	}
	var hero = main._create_unit(owner, "hero", stats, name, ring, lane)
	main._assign_unit_role(hero, "hero")
	return hero


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"_apply_terrain_surfaces",
		"_terrain_surface_candidates_for_runtime",
		"terrain_surface_feature_id",
		"terrain_surface_speed_mult",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing terrain surface runtime token: %s" % token)
			return
	var terrain_source := FileAccess.get_file_as_string("res://scripts/services/battle_terrain_service.gd")
	if not terrain_source.contains("func surface_candidates"):
		_fail("BattleTerrainService missing surface_candidates.")
		return

	var service = BattleTerrainServiceScript.new()
	var snapshot := _surface_snapshot()
	var service_candidates: Array = service.surface_candidates(snapshot)
	if not _expect(service_candidates.size() == 1, "Service should expose one floor surface candidate: %s" % str(service_candidates)):
		return
	var service_candidate: Dictionary = Dictionary(service_candidates[0])
	if not _expect(String(service_candidate.get("feature_id", "")) == "slick-floor", "Service surface candidate should keep feature id: %s" % str(service_candidate)):
		return
	if not _expect_close(Vector2(service_candidate.get("orientation", Vector2.ZERO)).x, 1.0, "Service surface candidate should keep normalized orientation"):
		return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.battle_terrain_runtime_snapshot = snapshot

	var runtime_candidates: Array = main._terrain_surface_candidates_for_runtime()
	if not _expect(runtime_candidates.size() == 1, "Runtime should expose one terrain surface candidate: %s" % str(runtime_candidates)):
		return

	var hero = _spawn_hero(main, 1, "P1 Surface Hero", 4.0, -0.25)
	hero.velocity = Vector2(4.0, 0.0)
	hero.heat = 40.0
	var heat_before := float(hero.heat)
	main._apply_terrain_surfaces(1.0)
	if not _expect(String(hero.get_meta("terrain_surface_feature_id", "")) == "slick-floor", "Hero should record terrain surface feature id: %s" % String(hero.get_meta("terrain_surface_feature_id", ""))):
		return
	if not _expect(String(hero.get_meta("terrain_surface_kind", "")) == "floor", "Hero should record terrain surface kind: %s" % String(hero.get_meta("terrain_surface_kind", ""))):
		return
	if not _expect_close(float(hero.get_meta("terrain_surface_speed_mult", 0.0)), 0.5, "Hero should record terrain surface speed mult"):
		return
	if not _expect_close(float(hero.velocity.x), 2.4, "Surface should slow then push hero velocity"):
		return
	if not _expect_close(float(hero.heat), 28.0, "Surface should cool hero heat"):
		return
	if not _expect(float(hero.heat) < heat_before, "Surface should reduce heat: before=%.2f after=%.2f" % [heat_before, float(hero.heat)]):
		return
	main._apply_terrain_surfaces(1.0)
	if not _expect_close(float(hero.velocity.x), 2.4, "Repeated surface speed should not keep multiplying hero velocity"):
		return
	if not _expect_close(float(hero.heat), 16.0, "Repeated surface should continue cooling without destabilizing speed"):
		return
	var hero_velocity_after := float(hero.velocity.x)
	var hero_heat_after := float(hero.heat)
	hero.ring_pos = 0.0
	hero.lane = 3.0

	var safe = _spawn_hero(main, 2, "P2 Surface Safe Hero", 8.0, -0.25)
	safe.velocity = Vector2(4.0, 0.0)
	safe.heat = 40.0
	main._apply_terrain_surfaces(1.0)
	if not _expect(String(safe.get_meta("terrain_surface_feature_id", "")) == "", "Safe hero should not record surface metadata"):
		return
	if not _expect_close(float(safe.velocity.x), 4.0, "Safe hero velocity should stay unchanged"):
		return
	if not _expect_close(float(safe.heat), 40.0, "Safe hero heat should stay unchanged"):
		return

	print("TERRAIN_SURFACE_RUNTIME_PROBE ok velocity=%.2f heat=%.2f" % [
		hero_velocity_after,
		hero_heat_after,
	])
	quit(0)
