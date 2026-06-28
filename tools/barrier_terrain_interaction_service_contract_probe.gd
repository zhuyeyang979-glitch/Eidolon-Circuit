extends SceneTree

const SERVICE_PATH := "res://scripts/services/barrier_terrain_interaction_service.gd"
const TERRAIN_SERVICE_PATH := "res://scripts/services/battle_terrain_service.gd"

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)
	quit(1)


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _expect_eq(actual, expected, message: String) -> bool:
	if actual != expected:
		_fail("%s expected=%s actual=%s" % [message, str(expected), str(actual)])
		return false
	return true


func _init() -> void:
	var source := FileAccess.get_file_as_string(SERVICE_PATH)
	if source.is_empty():
		_fail("BarrierTerrainInteractionService is missing.")
		return
	for token in [
		"class_name BarrierTerrainInteractionService",
		"func barrier_placement_intent",
		"func barrier_tile_policy",
		"func terrain_deployment_intents",
	]:
		if not source.contains(token):
			_fail("BarrierTerrainInteractionService missing boundary token: %s" % token)
			return
	for forbidden in ["Input.", "FileAccess", "DirAccess", "JSON.parse_string", "extends Node", "extends Control", "active_units", "all_units", "Fighter", "take_hit", "queue_free", "randf", "randi", "Time", "user://"]:
		if source.contains(forbidden):
			_fail("BarrierTerrainInteractionService contains forbidden runtime/save token: %s" % forbidden)
			return

	var terrain_script = load(TERRAIN_SERVICE_PATH)
	if terrain_script == null:
		_fail("Unable to load BattleTerrainService.")
		return
	var terrain_service = terrain_script.new()
	var snapshot: Dictionary = terrain_service.arena_snapshot({
		"arena_id": "terrain_interaction_test",
		"version": 2,
		"features": [
			{
				"id": "wall-alpha",
				"kind": "wall",
				"collider": {"shape": "circle", "center": Vector2(2.0, 0.0), "radius": 0.55},
				"orientation": Vector2(0.0, 1.0),
				"surface_tags": ["cover", "stone"],
				"effect_channels": ["collision", "occlusion"],
				"anchor_points": [
					{"id": "socket-a", "position": Vector2(2.0, 0.45), "normal": Vector2(0.0, 1.0), "supports": ["barrier_panel"]},
				],
			},
			{
				"id": "gap-beta",
				"kind": "gap",
				"collider": {"shape": "circle", "center": Vector2(5.0, 0.0), "radius": 0.5},
				"surface_tags": ["void"],
				"effect_channels": ["traversal"],
			},
			{
				"id": "lava-gamma",
				"kind": "hazard",
				"collider": {"shape": "circle", "center": Vector2(7.0, 0.0), "radius": 0.45},
				"surface_tags": ["heat"],
				"effect_channels": ["hazard"],
			},
			{
				"id": "weak-wall-delta",
				"kind": "wall",
				"collider": {"shape": "circle", "center": Vector2(10.0, 0.0), "radius": 0.45},
				"surface_tags": ["cover"],
				"effect_channels": ["collision", "occlusion"],
				"destructible": true,
				"metadata": {"terrain_hp": 40.0, "max_terrain_hp": 60.0},
			},
			{
				"id": "weak-wall-epsilon",
				"kind": "wall",
				"collider": {"shape": "circle", "center": Vector2(11.2, 0.0), "radius": 0.45},
				"surface_tags": ["cover"],
				"effect_channels": ["collision", "occlusion"],
				"destructible": true,
				"metadata": {"terrain_hp": 40.0, "max_terrain_hp": 60.0},
			},
			{
				"id": "portal-zeta",
				"kind": "portal",
				"collider": {"shape": "circle", "center": Vector2(12.4, 0.0), "radius": 0.45},
				"surface_tags": ["portal", "scripted_mechanism"],
				"effect_channels": ["portal"],
				"metadata": {"portal_index": 0, "portal_name": "ZETA FOLD"},
			},
			{
				"id": "mechanism-eta",
				"kind": "mechanism",
				"collider": {"shape": "circle", "center": Vector2(13.6, 0.0), "radius": 0.45},
				"surface_tags": ["scripted_mechanism"],
				"effect_channels": ["scripted_mechanism"],
				"metadata": {"mechanism_id": "eta"},
			},
		],
	})

	var script = load(SERVICE_PATH)
	if script == null:
		_fail("Unable to load BarrierTerrainInteractionService.")
		return
	var service = script.new()

	var barrier_blueprint := {
		"name": "Map-independent barrier",
		"barrier_tiles": [{"index": 0, "muscle": 1}],
		"saved_marker": "must_not_mutate",
	}
	var blueprint_before := str(barrier_blueprint)

	var attach_policy: Dictionary = service.barrier_tile_policy({
		"tile": {
			"tile_id": "panel-a",
			"radius": 0.08,
			"terrain_policy": {
				"attach_kinds": ["wall"],
				"bridge_kinds": ["gap"],
				"blocked_kinds": ["hazard"],
				"anchor_support": "barrier_panel",
				"inherit_orientation": true,
			},
		},
	})
	if not _expect_eq(Array(attach_policy.get("attach_kinds", [])), ["wall"], "attach policy normalized"):
		return
	if not _expect_eq(Array(attach_policy.get("blocked_kinds", [])), ["hazard"], "blocked policy normalized"):
		return
	if not _expect(bool(attach_policy.get("inherit_orientation", false)), "inherit orientation policy"):
		return

	var attach: Dictionary = service.barrier_placement_intent({
		"snapshot": snapshot,
		"barrier_blueprint": barrier_blueprint,
		"tile": {
			"tile_id": "panel-a",
			"position": Vector2(2.0, 0.45),
			"radius": 0.08,
			"terrain_policy": attach_policy,
		},
	})
	if not _expect(bool(attach.get("allowed", false)), "attach should be allowed: %s" % str(attach)):
		return
	if not _expect_eq(String(attach.get("outcome", "")), "attach", "attach outcome"):
		return
	if not _expect_eq(String(attach.get("feature_id", "")), "wall-alpha", "attach feature id"):
		return
	if not _expect_eq(String(attach.get("anchor_id", "")), "socket-a", "attach anchor id"):
		return
	if not _expect_eq(String(attach.get("reason", "")), "attach_to_terrain", "attach reason"):
		return
	if not _expect(Vector2(attach.get("orientation", Vector2.ZERO)) == Vector2(0.0, 1.0), "attach should inherit wall orientation: %s" % str(attach)):
		return
	var attach_intents: Array = service.terrain_deployment_intents(attach)
	if not _expect_eq(attach_intents.size(), 2, "attach deployment intent count"):
		return
	if not _expect_eq(String(Dictionary(attach_intents[0]).get("action", "")), "attach_to_terrain", "attach intent action"):
		return
	if not _expect_eq(String(Dictionary(attach_intents[1]).get("action", "")), "inherit_terrain_orientation", "orientation intent action"):
		return

	var bridge: Dictionary = service.barrier_placement_intent({
		"snapshot": snapshot,
		"tile": {
			"tile_id": "bridge-a",
			"position": Vector2(5.0, 0.0),
			"radius": 0.08,
			"terrain_policy": attach_policy,
		},
	})
	if not _expect(bool(bridge.get("allowed", false)) and String(bridge.get("outcome", "")) == "bridge", "bridge should be allowed: %s" % str(bridge)):
		return
	if not _expect_eq(String(Dictionary(service.terrain_deployment_intents(bridge)[0]).get("action", "")), "bridge_terrain_gap", "bridge intent action"):
		return

	var portal_policy: Dictionary = service.barrier_tile_policy({
		"tile": {
			"tile_id": "portal-trigger",
			"terrain_policy": {
				"portal_kinds": ["portal"],
			},
		},
	})
	if not _expect_eq(Array(portal_policy.get("portal_kinds", [])), ["portal"], "portal policy normalized"):
		return
	var portal: Dictionary = service.barrier_placement_intent({
		"snapshot": snapshot,
		"tile": {
			"tile_id": "portal-trigger",
			"position": Vector2(12.4, 0.0),
			"radius": 0.08,
			"terrain_policy": portal_policy,
		},
	})
	if not _expect(bool(portal.get("allowed", false)) and String(portal.get("outcome", "")) == "portal", "portal should be allowed: %s" % str(portal)):
		return
	if not _expect_eq(String(Dictionary(service.terrain_deployment_intents(portal)[0]).get("action", "")), "activate_terrain_portal", "portal intent action"):
		return

	var mechanism_policy: Dictionary = service.barrier_tile_policy({
		"tile": {
			"tile_id": "mechanism-trigger",
			"terrain_policy": {
				"mechanism_kinds": ["mechanism"],
			},
		},
	})
	if not _expect_eq(Array(mechanism_policy.get("mechanism_kinds", [])), ["mechanism"], "mechanism policy normalized"):
		return
	var mechanism: Dictionary = service.barrier_placement_intent({
		"snapshot": snapshot,
		"tile": {
			"tile_id": "mechanism-trigger",
			"position": Vector2(13.6, 0.0),
			"radius": 0.08,
			"terrain_policy": mechanism_policy,
		},
	})
	if not _expect(bool(mechanism.get("allowed", false)) and String(mechanism.get("outcome", "")) == "mechanism", "mechanism should be allowed: %s" % str(mechanism)):
		return
	if not _expect_eq(String(Dictionary(service.terrain_deployment_intents(mechanism)[0]).get("action", "")), "trigger_arena_mechanism", "mechanism intent action"):
		return

	var destructible_policy: Dictionary = service.barrier_tile_policy({
		"tile": {
			"tile_id": "terrain-state-panel",
			"terrain_policy": {
				"reinforce_kinds": ["wall"],
				"breach_kinds": ["wall"],
				"reinforce_amount": 18.0,
				"breach_damage": 44.0,
			},
		},
	})
	if not _expect_eq(Array(destructible_policy.get("reinforce_kinds", [])), ["wall"], "reinforce policy normalized"):
		return
	if not _expect_eq(Array(destructible_policy.get("breach_kinds", [])), ["wall"], "breach policy normalized"):
		return
	if not _expect(float(destructible_policy.get("reinforce_amount", 0.0)) == 18.0, "reinforce amount policy normalized"):
		return
	if not _expect(float(destructible_policy.get("breach_damage", 0.0)) == 44.0, "breach damage policy normalized"):
		return
	var reinforce: Dictionary = service.barrier_placement_intent({
		"snapshot": snapshot,
		"tile": {
			"tile_id": "reinforce-a",
			"position": Vector2(10.0, 0.0),
			"radius": 0.08,
			"terrain_policy": {
				"reinforce_kinds": ["wall"],
				"reinforce_amount": 18.0,
			},
		},
	})
	if not _expect(bool(reinforce.get("allowed", false)) and String(reinforce.get("outcome", "")) == "reinforce", "reinforce should be allowed: %s" % str(reinforce)):
		return
	var reinforce_intent: Dictionary = Dictionary(service.terrain_deployment_intents(reinforce)[0])
	if not _expect_eq(String(reinforce_intent.get("action", "")), "reinforce_terrain_feature", "reinforce intent action"):
		return
	if not _expect(float(reinforce_intent.get("reinforce_amount", 0.0)) == 18.0, "reinforce intent amount"):
		return
	var breach: Dictionary = service.barrier_placement_intent({
		"snapshot": snapshot,
		"tile": {
			"tile_id": "breach-a",
			"position": Vector2(11.2, 0.0),
			"radius": 0.08,
			"terrain_policy": {
				"breach_kinds": ["wall"],
				"breach_damage": 44.0,
			},
		},
	})
	if not _expect(bool(breach.get("allowed", false)) and String(breach.get("outcome", "")) == "breach", "breach should be allowed: %s" % str(breach)):
		return
	var breach_intent: Dictionary = Dictionary(service.terrain_deployment_intents(breach)[0])
	if not _expect_eq(String(breach_intent.get("action", "")), "breach_terrain_feature", "breach intent action"):
		return
	if not _expect(float(breach_intent.get("breach_damage", 0.0)) == 44.0, "breach intent damage"):
		return

	var blocked: Dictionary = service.barrier_placement_intent({
		"snapshot": snapshot,
		"tile": {
			"tile_id": "blocked-a",
			"position": Vector2(7.0, 0.0),
			"radius": 0.08,
			"terrain_policy": attach_policy,
		},
	})
	if not _expect(not bool(blocked.get("allowed", true)) and String(blocked.get("outcome", "")) == "blocked", "hazard should block: %s" % str(blocked)):
		return
	if not _expect_eq(Array(service.terrain_deployment_intents(blocked)).size(), 0, "blocked placement should produce no deployment intents"):
		return

	var mismatch: Dictionary = service.barrier_placement_intent({
		"snapshot": snapshot,
		"tile": {
			"tile_id": "wrong-support",
			"position": Vector2(2.0, 0.45),
			"radius": 0.08,
			"terrain_policy": {
				"attach_kinds": ["wall"],
				"anchor_support": "speed_lane",
			},
		},
	})
	if not _expect(not bool(mismatch.get("allowed", true)) and String(mismatch.get("reason", "")) == "blocked_anchor_support", "anchor support mismatch should block: %s" % str(mismatch)):
		return

	var free: Dictionary = service.barrier_placement_intent({
		"snapshot": snapshot,
		"tile": {
			"tile_id": "free-a",
			"position": Vector2(9.0, 0.0),
			"radius": 0.08,
			"terrain_policy": attach_policy,
		},
	})
	if not _expect(bool(free.get("allowed", false)) and String(free.get("outcome", "")) == "free", "free placement should be allowed: %s" % str(free)):
		return
	if not _expect_eq(String(Dictionary(service.terrain_deployment_intents(free)[0]).get("action", "")), "deploy_without_terrain", "free intent action"):
		return

	if not _expect_eq(str(barrier_blueprint), blueprint_before, "barrier blueprint should stay map-independent and unmodified"):
		return
	if failed:
		quit(1)
		return
	print("BARRIER_TERRAIN_INTERACTION_SERVICE_CONTRACT_PROBE ok")
	quit(0)
