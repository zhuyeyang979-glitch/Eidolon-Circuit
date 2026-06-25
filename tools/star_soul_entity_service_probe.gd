extends SceneTree

const BP_SERVICE_PATH := "res://scripts/services/star_soul_bp_service.gd"
const ENTITY_SERVICE_PATH := "res://scripts/services/star_soul_entity_service.gd"

var failed := false


func _init() -> void:
	_require(FileAccess.file_exists(BP_SERVICE_PATH), "Missing StarSoulBPService script.")
	_require(FileAccess.file_exists(ENTITY_SERVICE_PATH), "Missing StarSoulEntityService script.")
	if failed:
		quit(1)
		return
	var BPServiceScript = load(BP_SERVICE_PATH)
	var EntityServiceScript = load(ENTITY_SERVICE_PATH)
	_require(BPServiceScript != null, "Cannot load StarSoulBPService.")
	_require(EntityServiceScript != null, "Cannot load StarSoulEntityService.")
	if failed:
		quit(1)
		return
	var bp_service = BPServiceScript.new()
	var entity_service = EntityServiceScript.new()
	var catalog: Dictionary = bp_service.catalog_by_id()
	var context := {
		"ring_length": 24.0,
		"battle_half_height": 7.5,
		"spawn_points": {
			1: {"ring": 0.0, "lane": 0.0},
			2: {"ring": 12.0, "lane": 0.0},
		},
		"primary_colors": {1: Color(0.1, 0.8, 1.0, 1.0), 2: Color(1.0, 0.2, 0.4, 1.0)},
		"accent_colors": {1: Color(1.0, 0.8, 0.2, 1.0), 2: Color(0.4, 1.0, 0.7, 1.0)},
	}

	var own_payload: Dictionary = entity_service.spawn_payload({
		"entry": {"owner": 1, "star_soul_id": "defense_tower_c", "sequence_index": 0, "vp": 3},
	}, context, catalog)
	_require(bool(own_payload.get("valid", false)), "Own-spawn payload should be valid.")
	_require(is_equal_approx(float(own_payload.get("ring", -1.0)), 0.0), "Own-spawn Star Soul should spawn at P1 spawn.")
	_require(int(own_payload.get("owner", 0)) == 1, "Payload owner should be P1.")
	_require(String(own_payload.get("role", "")) == "star_soul", "Payload role should be star_soul.")
	var own_stats: Dictionary = Dictionary(own_payload.get("stats", {}))
	_require(bool(own_stats.get("star_soul", false)), "Stats should mark star_soul.")
	_require(bool(own_stats.get("training_ball_dummy", false)), "Stats should use training ball visuals for the placeholder entity.")
	_require(int(own_stats.get("health", 0)) >= 120, "High HP band should create a durable entity.")
	_require(int(own_stats.get("vp", 0)) == 3, "Payload should preserve VP value.")
	_require(float(own_stats.get("duration", 0.0)) == 30.0, "Defense tower C should keep catalog duration.")
	var own_meta: Dictionary = Dictionary(own_payload.get("meta", {}))
	_require(String(own_meta.get("star_soul_id", "")) == "defense_tower_c", "Meta should expose Star Soul id.")
	_require(String(own_meta.get("star_soul_runtime_id", "")) == "star_soul_001", "Default runtime id should be deterministic.")

	var enemy_payload: Dictionary = entity_service.spawn_payload({
		"entry": {"owner": 1, "star_soul_id": "punishment_tower_a", "sequence_index": 1},
	}, context, catalog)
	_require(is_equal_approx(float(enemy_payload.get("ring", -1.0)), 12.0), "Enemy-spawn Star Soul should spawn at opponent spawn.")

	var midfield_payload: Dictionary = entity_service.spawn_payload({
		"entry": {"owner": 2, "star_soul_id": "wandering_giant_a", "sequence_index": 2},
	}, context, catalog)
	_require(is_equal_approx(float(midfield_payload.get("ring", -1.0)), 18.0), "P2 midfield Star Soul should spawn a quarter-ring past P2 spawn.")
	var mid_stats: Dictionary = Dictionary(midfield_payload.get("stats", {}))
	_require(float(mid_stats.get("speed", 0.0)) > 0.0, "Wandering giant should have movement speed.")
	_require(String(mid_stats.get("star_soul_movement", "")) == "follow_nearest_any_unit", "Movement type should preserve catalog behavior.")

	var fallback_payload: Dictionary = entity_service.spawn_payload({"star_soul_id": "missing_custom_soul", "owner": 1}, context, {})
	_require(bool(fallback_payload.get("valid", false)), "Unknown catalog entries should still create a safe placeholder.")
	_require(int(Dictionary(fallback_payload.get("stats", {})).get("vp", 0)) == 1, "Unknown fallback should be worth 1 VP.")

	if failed:
		quit(1)
		return
	print("STAR_SOUL_ENTITY_SERVICE_PROBE ok own=%s enemy=%s mid=%s" % [str(own_payload.get("ring", 0.0)), str(enemy_payload.get("ring", 0.0)), str(midfield_payload.get("ring", 0.0))])
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
