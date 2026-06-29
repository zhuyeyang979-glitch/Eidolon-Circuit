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


func _hazard_snapshot() -> Dictionary:
	var terrain_service = BattleTerrainServiceScript.new()
	return terrain_service.arena_snapshot({
		"arena_id": "terrain_hazard_runtime_probe",
		"version": 1,
		"features": [
			{
				"id": "heat-hazard-floor",
				"name": "HEAT HAZARD FLOOR",
				"kind": "hazard",
				"collider": {"shape": "circle", "center": Vector2(3.0, 0.25), "radius": 0.52},
				"surface_tags": ["hazard", "heat"],
				"effect_channels": ["hazard"],
				"metadata": {
					"heat_rate": 18.0,
					"damage_per_tick": 5,
					"damage_interval": 0.05,
					"damage_type": "chemical",
				},
			},
		],
	})


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for token in [
		"_apply_terrain_hazards",
		"_terrain_hazard_candidates_for_runtime",
		"terrain_hazard_feature_id",
		"terrain_hazard_damage_last",
	]:
		if not main_source.contains(token):
			_fail("main.gd missing terrain hazard runtime token: %s" % token)
			return
	var terrain_source := FileAccess.get_file_as_string("res://scripts/services/battle_terrain_service.gd")
	if not terrain_source.contains("func hazard_candidates"):
		_fail("BattleTerrainService missing hazard_candidates.")
		return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._clear_all_units()
	main.battle_terrain_runtime_snapshot = _hazard_snapshot()

	var hazard_candidates: Array = main._terrain_hazard_candidates_for_runtime()
	if not _expect(hazard_candidates.size() == 1, "Runtime should expose one terrain hazard candidate: %s" % str(hazard_candidates)):
		return

	var stats := {
		"name": "Hazard Test Hero",
		"health": 100,
		"max_health": 100,
		"mass": 10.0,
		"radius": 0.18,
		"heat_capacity": 100.0,
		"speed": 0.8,
	}
	var hero = main._create_unit(1, "hero", stats, "P1 Hazard Hero", 3.0, 0.25)
	main._assign_unit_role(hero, "hero")
	var health_before := int(hero.health)
	var heat_before := float(hero.heat)
	main._apply_terrain_hazards(1.0)
	if not _expect(String(hero.get_meta("terrain_hazard_feature_id", "")) == "heat-hazard-floor", "Hero should record terrain hazard feature id: %s" % String(hero.get_meta("terrain_hazard_feature_id", ""))):
		return
	if not _expect(String(hero.get_meta("terrain_hazard_kind", "")) == "hazard", "Hero should record terrain hazard kind: %s" % String(hero.get_meta("terrain_hazard_kind", ""))):
		return
	if not _expect(float(hero.get_meta("terrain_hazard_heat_rate", 0.0)) == 18.0, "Hero should record terrain hazard heat rate: %s" % str(hero.get_meta("terrain_hazard_heat_rate", 0.0))):
		return
	if not _expect(float(hero.heat) > heat_before, "Terrain hazard should add heat: before=%.2f after=%.2f" % [heat_before, float(hero.heat)]):
		return
	if not _expect(int(hero.health) < health_before, "Terrain hazard should deal damage: before=%d after=%d" % [health_before, int(hero.health)]):
		return
	if not _expect(int(hero.get_meta("terrain_hazard_damage_last", 0)) > 0, "Hero should record latest terrain hazard damage"):
		return

	var safe = main._create_unit(2, "hero", stats, "P2 Safe Hero", 8.0, 0.25)
	main._assign_unit_role(safe, "hero")
	var safe_health_before := int(safe.health)
	var safe_heat_before := float(safe.heat)
	main._apply_terrain_hazards(1.0)
	if not _expect(String(safe.get_meta("terrain_hazard_feature_id", "")) == "", "Safe hero should not record hazard metadata"):
		return
	if not _expect(int(safe.health) == safe_health_before and float(safe.heat) == safe_heat_before, "Safe hero should not take terrain hazard effects"):
		return

	print("TERRAIN_HAZARD_RUNTIME_PROBE ok heat=%.2f damage=%d" % [
		float(hero.heat),
		int(hero.get_meta("terrain_hazard_damage_last", 0)),
	])
	quit(0)
