extends RefCounted
class_name BarrierTerrainInteractionService

const BattleTerrainServiceScript := preload("res://scripts/services/battle_terrain_service.gd")

const OUTCOME_FREE := "free"
const OUTCOME_ATTACH := "attach"
const OUTCOME_BRIDGE := "bridge"
const OUTCOME_REINFORCE := "reinforce"
const OUTCOME_BREACH := "breach"
const OUTCOME_PORTAL := "portal"
const OUTCOME_MECHANISM := "mechanism"
const OUTCOME_OVERLAP := "overlap"
const OUTCOME_REPLACE := "replace"
const OUTCOME_BLOCKED := "blocked"


func barrier_tile_policy(context: Dictionary) -> Dictionary:
	var tile := _dict(context.get("tile", {}))
	var component := _dict(context.get("component", {}))
	var tile_policy := _dict(tile.get("terrain_policy", {}))
	var component_policy := _dict(component.get("terrain_policy", {}))
	var radius := float(component_policy.get("radius", 0.0))
	radius = float(tile_policy.get("radius", radius))
	radius = float(component.get("radius", radius))
	radius = float(tile.get("radius", radius))
	return {
		"attach_kinds": _normalized_token_list(tile_policy.get("attach_kinds", component_policy.get("attach_kinds", []))),
		"bridge_kinds": _normalized_token_list(tile_policy.get("bridge_kinds", component_policy.get("bridge_kinds", []))),
		"reinforce_kinds": _normalized_token_list(tile_policy.get("reinforce_kinds", component_policy.get("reinforce_kinds", []))),
		"breach_kinds": _normalized_token_list(tile_policy.get("breach_kinds", component_policy.get("breach_kinds", []))),
		"portal_kinds": _normalized_token_list(tile_policy.get("portal_kinds", component_policy.get("portal_kinds", []))),
		"mechanism_kinds": _normalized_token_list(tile_policy.get("mechanism_kinds", component_policy.get("mechanism_kinds", []))),
		"blocked_kinds": _normalized_token_list(tile_policy.get("blocked_kinds", component_policy.get("blocked_kinds", []))),
		"overlap_kinds": _normalized_token_list(tile_policy.get("overlap_kinds", component_policy.get("overlap_kinds", []))),
		"replace_kinds": _normalized_token_list(tile_policy.get("replace_kinds", component_policy.get("replace_kinds", []))),
		"anchor_support": _normalize_token(tile_policy.get("anchor_support", component_policy.get("anchor_support", ""))),
		"inherit_orientation": bool(tile_policy.get("inherit_orientation", component_policy.get("inherit_orientation", false))),
		"reinforce_amount": maxf(0.0, float(tile_policy.get("reinforce_amount", component_policy.get("reinforce_amount", component.get("terrain_reinforce_amount", tile.get("terrain_reinforce_amount", 0.0)))))),
		"breach_damage": maxf(0.0, float(tile_policy.get("breach_damage", component_policy.get("breach_damage", component.get("terrain_breach_damage", component.get("entry_breach_damage", tile.get("terrain_breach_damage", tile.get("entry_breach_damage", 0.0)))))))),
		"radius": maxf(0.0, radius),
	}


func barrier_placement_intent(context: Dictionary) -> Dictionary:
	var tile := _dict(context.get("tile", {}))
	var policy := barrier_tile_policy({"tile": tile, "component": _dict(context.get("component", {}))})
	var terrain_policy := _dict(tile.get("terrain_policy", {}))
	if not terrain_policy.is_empty():
		policy = _merge_policy(policy, terrain_policy)
	var terrain_service = BattleTerrainServiceScript.new()
	var placement: Dictionary = terrain_service.placement_query({
		"snapshot": _dict(context.get("snapshot", {})),
		"position": _vec(tile.get("position", context.get("position", Vector2.INF)), Vector2.INF),
		"radius": maxf(float(tile.get("radius", policy.get("radius", 0.0))), float(policy.get("radius", 0.0))),
		"blocked_kinds": Array(policy.get("blocked_kinds", [])),
		"replace_kinds": Array(policy.get("replace_kinds", [])),
		"reinforce_kinds": Array(policy.get("reinforce_kinds", [])),
		"breach_kinds": Array(policy.get("breach_kinds", [])),
		"portal_kinds": Array(policy.get("portal_kinds", [])),
		"mechanism_kinds": Array(policy.get("mechanism_kinds", [])),
		"attach_kinds": Array(policy.get("attach_kinds", [])),
		"bridge_kinds": Array(policy.get("bridge_kinds", [])),
		"overlap_kinds": Array(policy.get("overlap_kinds", [])),
	})
	var result := _base_intent(tile, policy, placement)
	if String(result.get("outcome", "")) == OUTCOME_ATTACH:
		var support_result := _anchor_support_result(result, policy)
		if not support_result.is_empty():
			return support_result
		if bool(policy.get("inherit_orientation", false)):
			result["inherits_orientation"] = true
			result["orientation"] = _terrain_orientation_from_result(result, _vec(tile.get("orientation", Vector2.RIGHT), Vector2.RIGHT))
	if String(result.get("outcome", "")) == OUTCOME_BRIDGE:
		result["reason"] = "bridge_terrain_gap"
		result["allowed"] = true
	if String(result.get("outcome", "")) == OUTCOME_REINFORCE:
		result["reason"] = "reinforce_terrain_feature"
		result["allowed"] = true
	if String(result.get("outcome", "")) == OUTCOME_BREACH:
		result["reason"] = "breach_terrain_feature"
		result["allowed"] = true
	if String(result.get("outcome", "")) == OUTCOME_PORTAL:
		result["reason"] = "activate_terrain_portal"
		result["allowed"] = true
	if String(result.get("outcome", "")) == OUTCOME_MECHANISM:
		result["reason"] = "trigger_arena_mechanism"
		result["allowed"] = true
	if String(result.get("outcome", "")) == OUTCOME_ATTACH:
		result["reason"] = "attach_to_terrain"
		result["allowed"] = true
	if String(result.get("outcome", "")) in [OUTCOME_FREE, OUTCOME_OVERLAP, OUTCOME_REPLACE]:
		result["allowed"] = true
	return result


func terrain_deployment_intents(placement_intent: Dictionary) -> Array:
	if not bool(placement_intent.get("allowed", false)):
		return []
	var outcome := String(placement_intent.get("outcome", OUTCOME_FREE))
	var tile_id := String(placement_intent.get("tile_id", ""))
	var feature_id := String(placement_intent.get("feature_id", ""))
	var intents: Array = []
	if outcome == OUTCOME_ATTACH:
		intents.append({
			"action": "attach_to_terrain",
			"tile_id": tile_id,
			"feature_id": feature_id,
			"anchor_id": String(placement_intent.get("anchor_id", "")),
			"terrain_kind": String(placement_intent.get("terrain_kind", "")),
		})
		if bool(placement_intent.get("inherits_orientation", false)):
			intents.append({
				"action": "inherit_terrain_orientation",
				"tile_id": tile_id,
				"feature_id": feature_id,
				"orientation": _vec(placement_intent.get("orientation", Vector2.RIGHT), Vector2.RIGHT),
			})
		return intents
	if outcome == OUTCOME_BRIDGE:
		return [{
			"action": "bridge_terrain_gap",
			"tile_id": tile_id,
			"feature_id": feature_id,
			"terrain_kind": String(placement_intent.get("terrain_kind", "")),
		}]
	if outcome == OUTCOME_REINFORCE:
		return [{
			"action": "reinforce_terrain_feature",
			"tile_id": tile_id,
			"feature_id": feature_id,
			"terrain_kind": String(placement_intent.get("terrain_kind", "")),
			"reinforce_amount": maxf(0.0, float(_dict(placement_intent.get("policy", {})).get("reinforce_amount", 0.0))),
		}]
	if outcome == OUTCOME_BREACH:
		return [{
			"action": "breach_terrain_feature",
			"tile_id": tile_id,
			"feature_id": feature_id,
			"terrain_kind": String(placement_intent.get("terrain_kind", "")),
			"breach_damage": maxf(0.0, float(_dict(placement_intent.get("policy", {})).get("breach_damage", 0.0))),
		}]
	if outcome == OUTCOME_PORTAL:
		return [{
			"action": "activate_terrain_portal",
			"tile_id": tile_id,
			"feature_id": feature_id,
			"terrain_kind": String(placement_intent.get("terrain_kind", "")),
		}]
	if outcome == OUTCOME_MECHANISM:
		return [{
			"action": "trigger_arena_mechanism",
			"tile_id": tile_id,
			"feature_id": feature_id,
			"terrain_kind": String(placement_intent.get("terrain_kind", "")),
		}]
	if outcome == OUTCOME_REPLACE:
		return [{
			"action": "replace_terrain_feature",
			"tile_id": tile_id,
			"feature_id": feature_id,
			"terrain_kind": String(placement_intent.get("terrain_kind", "")),
		}]
	if outcome == OUTCOME_OVERLAP:
		return [{
			"action": "overlap_terrain_feature",
			"tile_id": tile_id,
			"feature_id": feature_id,
			"terrain_kind": String(placement_intent.get("terrain_kind", "")),
		}]
	return [{
		"action": "deploy_without_terrain",
		"tile_id": tile_id,
	}]


func _base_intent(tile: Dictionary, policy: Dictionary, placement: Dictionary) -> Dictionary:
	var outcome := String(placement.get("outcome", OUTCOME_BLOCKED))
	var feature_id := String(placement.get("feature_id", ""))
	var anchor := _dict(placement.get("anchor", {}))
	return {
		"allowed": outcome != OUTCOME_BLOCKED,
		"outcome": outcome,
		"reason": String(placement.get("reason", "blocked_unknown")),
		"reason_text": String(placement.get("reason_text", placement.get("reason", ""))),
		"tile_id": String(tile.get("tile_id", tile.get("id", ""))),
		"position": _vec(tile.get("position", Vector2.ZERO), Vector2.ZERO),
		"radius": maxf(float(tile.get("radius", 0.0)), float(policy.get("radius", 0.0))),
		"feature_id": feature_id,
		"terrain_kind": String(placement.get("terrain_kind", "")),
		"anchor_id": String(placement.get("anchor_id", anchor.get("anchor_id", ""))),
		"anchor": anchor.duplicate(true),
		"overlaps": Array(placement.get("overlaps", [])).duplicate(true),
		"policy": policy.duplicate(true),
		"orientation": _vec(tile.get("orientation", Vector2.RIGHT), Vector2.RIGHT),
		"inherits_orientation": false,
	}


func _anchor_support_result(result: Dictionary, policy: Dictionary) -> Dictionary:
	var required_support := String(policy.get("anchor_support", ""))
	if required_support == "":
		return {}
	var anchor := _dict(result.get("anchor", {}))
	var supports := Array(anchor.get("supports", []))
	if supports.has(required_support):
		return {}
	var blocked := result.duplicate(true)
	blocked["allowed"] = false
	blocked["outcome"] = OUTCOME_BLOCKED
	blocked["reason"] = "blocked_anchor_support"
	blocked["reason_text"] = "blocked anchor support"
	return blocked


func _terrain_orientation_from_result(result: Dictionary, fallback: Vector2) -> Vector2:
	var feature_id := String(result.get("feature_id", ""))
	for raw_feature in Array(result.get("overlaps", [])):
		var feature := _dict(raw_feature)
		if String(feature.get("feature_id", "")) == feature_id:
			return _normalized_or(_vec(feature.get("orientation", fallback), fallback), fallback)
	var anchor := _dict(result.get("anchor", {}))
	if not anchor.is_empty():
		return _normalized_or(_vec(anchor.get("normal", fallback), fallback), fallback)
	return _normalized_or(fallback, Vector2.RIGHT)


func _merge_policy(base: Dictionary, override_policy: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in ["attach_kinds", "bridge_kinds", "reinforce_kinds", "breach_kinds", "portal_kinds", "mechanism_kinds", "blocked_kinds", "overlap_kinds", "replace_kinds"]:
		if override_policy.has(key):
			result[key] = _normalized_token_list(override_policy.get(key, []))
	if override_policy.has("anchor_support"):
		result["anchor_support"] = _normalize_token(override_policy.get("anchor_support", ""))
	if override_policy.has("inherit_orientation"):
		result["inherit_orientation"] = bool(override_policy.get("inherit_orientation", false))
	if override_policy.has("reinforce_amount"):
		result["reinforce_amount"] = maxf(0.0, float(override_policy.get("reinforce_amount", 0.0)))
	if override_policy.has("breach_damage"):
		result["breach_damage"] = maxf(0.0, float(override_policy.get("breach_damage", 0.0)))
	if override_policy.has("radius"):
		result["radius"] = maxf(0.0, float(override_policy.get("radius", 0.0)))
	return result


func _normalized_or(value: Vector2, fallback: Vector2) -> Vector2:
	var result := value
	if result.length() <= 0.0001:
		result = fallback
	if result.length() <= 0.0001:
		result = Vector2.RIGHT
	return result.normalized()


func _normalized_token_list(value) -> Array:
	var result: Array = []
	if value is Array:
		for item in value:
			_append_unique_token(result, item)
	else:
		_append_unique_token(result, value)
	result.sort()
	return result


func _append_unique_token(result: Array, value) -> void:
	var token := _normalize_token(value)
	if token != "" and not result.has(token):
		result.append(token)


func _normalize_token(value) -> String:
	return String(value).strip_edges().to_lower().replace(" ", "_").replace("-", "_")


func _vec(value, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	return value if value is Vector2 else fallback


func _dict(value) -> Dictionary:
	return value if value is Dictionary else {}
