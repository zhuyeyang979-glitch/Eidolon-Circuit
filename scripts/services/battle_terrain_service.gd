extends RefCounted
class_name BattleTerrainService

const TERRAIN_KIND_FLOOR := "floor"
const TERRAIN_KIND_WALL := "wall"
const TERRAIN_KIND_GAP := "gap"
const TERRAIN_KIND_HAZARD := "hazard"

const PLACEMENT_FREE := "free"
const PLACEMENT_ATTACH := "attach"
const PLACEMENT_BRIDGE := "bridge"
const PLACEMENT_OVERLAP := "overlap"
const PLACEMENT_REPLACE := "replace"
const PLACEMENT_BLOCKED := "blocked"


func normalize_feature(data: Dictionary, index: int = -1) -> Dictionary:
	var feature_id := String(data.get("feature_id", data.get("id", ""))).strip_edges()
	if feature_id == "":
		feature_id = "terrain_%03d" % maxi(0, index)
	var terrain_kind := _normalize_token(data.get("terrain_kind", data.get("kind", TERRAIN_KIND_FLOOR)))
	if terrain_kind == "":
		terrain_kind = TERRAIN_KIND_FLOOR
	var orientation := _normalized_or(_vec(data.get("orientation", Vector2.RIGHT)), Vector2.RIGHT)
	return {
		"feature_id": feature_id,
		"terrain_kind": terrain_kind,
		"collider": _normalize_collider(_dict(data.get("collider", {}))),
		"orientation": orientation,
		"surface_tags": _normalized_token_list(data.get("surface_tags", [])),
		"owner_id": int(data.get("owner_id", 0)),
		"destructible": bool(data.get("destructible", false)),
		"anchor_points": _normalize_anchor_points(data.get("anchor_points", [])),
		"effect_channels": _normalized_token_list(data.get("effect_channels", [])),
		"metadata": _dict(data.get("metadata", {})).duplicate(true),
		"name": String(data.get("name", data.get("blocker_name", feature_id))),
	}


func arena_snapshot(context: Dictionary) -> Dictionary:
	var features: Array = []
	var raw_features: Array = Array(context.get("features", []))
	for i in range(raw_features.size()):
		var feature_data := _dict(raw_features[i])
		if feature_data.is_empty():
			continue
		features.append(normalize_feature(feature_data, i))
	return {
		"arena_id": String(context.get("arena_id", "")),
		"version": int(context.get("version", 1)),
		"features": features,
	}


func features_with_tag(snapshot: Dictionary, tag) -> Array:
	var normalized_tag := _normalize_token(tag)
	var result: Array = []
	if normalized_tag == "":
		return result
	for feature in Array(snapshot.get("features", [])):
		var item := _dict(feature)
		if Array(item.get("surface_tags", [])).has(normalized_tag):
			result.append(item.duplicate(true))
	return result


func features_for_kind(snapshot: Dictionary, terrain_kind) -> Array:
	var normalized_kind := _normalize_token(terrain_kind)
	var result: Array = []
	if normalized_kind == "":
		return result
	for feature in Array(snapshot.get("features", [])):
		var item := _dict(feature)
		if String(item.get("terrain_kind", "")) == normalized_kind:
			result.append(item.duplicate(true))
	return result


func features_overlapping_point(snapshot: Dictionary, point: Vector2, radius: float = 0.0) -> Array:
	var result: Array = []
	var query_radius := maxf(0.0, radius)
	for feature in Array(snapshot.get("features", [])):
		var item := _dict(feature)
		var collider := _dict(item.get("collider", {}))
		if collider.is_empty():
			continue
		if _point_overlaps_collider(point, query_radius, collider):
			result.append(item.duplicate(true))
	return result


func placement_query(context: Dictionary) -> Dictionary:
	var snapshot := _dict(context.get("snapshot", {}))
	var position := _vec(context.get("position", Vector2.INF))
	if position == Vector2.INF:
		return _placement_result(PLACEMENT_BLOCKED, "blocked_invalid_position", {})
	var radius := maxf(0.0, float(context.get("radius", 0.0)))
	var overlaps := features_overlapping_point(snapshot, position, radius)
	var blocked := _first_matching_kind(overlaps, context.get("blocked_kinds", []))
	if not blocked.is_empty():
		return _placement_result(PLACEMENT_BLOCKED, "blocked_by_terrain", blocked, overlaps)
	var replace := _first_matching_kind(overlaps, context.get("replace_kinds", []))
	if not replace.is_empty():
		return _placement_result(PLACEMENT_REPLACE, "replace_terrain", replace, overlaps)
	var attach := _first_matching_kind(overlaps, context.get("attach_kinds", []))
	if not attach.is_empty():
		return _placement_result(PLACEMENT_ATTACH, "attach_to_terrain", attach, overlaps, _nearest_anchor(attach, position))
	var bridge := _first_matching_kind(overlaps, context.get("bridge_kinds", []))
	if not bridge.is_empty():
		return _placement_result(PLACEMENT_BRIDGE, "bridge_terrain_gap", bridge, overlaps)
	var overlap := _first_matching_kind(overlaps, context.get("overlap_kinds", []))
	if not overlap.is_empty():
		return _placement_result(PLACEMENT_OVERLAP, "overlap_terrain", overlap, overlaps)
	return {
		"outcome": PLACEMENT_FREE,
		"reason": "free_space",
		"reason_text": "free terrain placement",
		"overlaps": overlaps,
	}


func combined_occlusion_candidates(snapshot: Dictionary, barrier_candidates: Array = []) -> Array:
	var candidates: Array = []
	for feature in Array(snapshot.get("features", [])):
		var item := _dict(feature)
		var channels := Array(item.get("effect_channels", []))
		if not channels.has("occlusion"):
			continue
		candidates.append({
			"source": "terrain",
			"kind": _occlusion_kind_for_feature(item),
			"feature_id": String(item.get("feature_id", "")),
			"blocker_name": String(item.get("name", item.get("feature_id", ""))),
			"collider": _dict(item.get("collider", {})).duplicate(true),
			"terrain_kind": String(item.get("terrain_kind", "")),
		})
	for candidate in barrier_candidates:
		var item := _dict(candidate)
		if item.is_empty():
			continue
		candidates.append(item.duplicate(true))
	return candidates


func combined_collision_candidates(snapshot: Dictionary, static_candidates: Array = []) -> Array:
	var candidates: Array = []
	for feature in Array(snapshot.get("features", [])):
		var item := _dict(feature)
		var channels := Array(item.get("effect_channels", []))
		if not channels.has("collision"):
			continue
		candidates.append({
			"source": "terrain",
			"feature_id": String(item.get("feature_id", "")),
			"blocker_name": String(item.get("name", item.get("feature_id", ""))),
			"collider": _dict(item.get("collider", {})).duplicate(true),
			"terrain_kind": String(item.get("terrain_kind", "")),
			"surface_tags": Array(item.get("surface_tags", [])).duplicate(true),
			"destructible": bool(item.get("destructible", false)),
		})
	for candidate in static_candidates:
		var item := _dict(candidate)
		if item.is_empty():
			continue
		candidates.append(item.duplicate(true))
	return candidates


func _placement_result(outcome: String, reason: String, feature: Dictionary, overlaps: Array = [], anchor: Dictionary = {}) -> Dictionary:
	var result := {
		"outcome": outcome,
		"reason": reason,
		"reason_text": reason.replace("_", " "),
		"feature_id": String(feature.get("feature_id", "")),
		"terrain_kind": String(feature.get("terrain_kind", "")),
		"overlaps": overlaps,
	}
	if not anchor.is_empty():
		result["anchor_id"] = String(anchor.get("anchor_id", ""))
		result["anchor"] = anchor.duplicate(true)
	return result


func _first_matching_kind(features: Array, kinds_value) -> Dictionary:
	var kinds := _normalized_token_list(kinds_value)
	if kinds.is_empty():
		return {}
	for feature in features:
		var item := _dict(feature)
		if kinds.has(String(item.get("terrain_kind", ""))):
			return item
	return {}


func _nearest_anchor(feature: Dictionary, position: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for raw_anchor in Array(feature.get("anchor_points", [])):
		var anchor := _dict(raw_anchor)
		var distance := _vec(anchor.get("position", Vector2.ZERO)).distance_to(position)
		if distance < best_distance:
			best_distance = distance
			best = anchor
	return best


func _normalize_anchor_points(value) -> Array:
	var result: Array = []
	for raw_anchor in Array(value):
		var anchor := _dict(raw_anchor)
		if anchor.is_empty():
			continue
		var anchor_id := String(anchor.get("anchor_id", anchor.get("id", ""))).strip_edges()
		if anchor_id == "":
			anchor_id = "anchor_%03d" % result.size()
		result.append({
			"anchor_id": anchor_id,
			"position": _vec(anchor.get("position", Vector2.ZERO)),
			"normal": _normalized_or(_vec(anchor.get("normal", Vector2.UP)), Vector2.UP),
			"supports": _normalized_token_list(anchor.get("supports", [])),
			"metadata": _dict(anchor.get("metadata", {})).duplicate(true),
		})
	return result


func _normalize_collider(collider: Dictionary) -> Dictionary:
	if collider.is_empty():
		return {}
	var result := collider.duplicate(true)
	result["shape"] = _normalize_token(result.get("shape", "circle"))
	if not result.has("center") and result.has("position"):
		result["center"] = _vec(result.get("position", Vector2.ZERO))
	return result


func _point_overlaps_collider(point: Vector2, query_radius: float, collider: Dictionary) -> bool:
	var shape := String(collider.get("shape", "circle"))
	if shape == "circle":
		var center := _vec(collider.get("center", Vector2.ZERO))
		var radius := maxf(0.0, float(collider.get("radius", 0.0)))
		return point.distance_to(center) <= radius + query_radius
	if shape in ["segment", "capsule"]:
		var a := _vec(collider.get("a", collider.get("start", Vector2.ZERO)))
		var b := _vec(collider.get("b", collider.get("end", a)))
		var radius := maxf(0.0, float(collider.get("radius", 0.0)))
		return _distance_point_to_segment(point, a, b) <= radius + query_radius
	if shape == "rect":
		var center := _vec(collider.get("center", Vector2.ZERO))
		var half_extents := _vec(collider.get("half_extents", Vector2.ZERO))
		if half_extents == Vector2.ZERO and collider.has("size"):
			half_extents = _vec(collider.get("size", Vector2.ZERO)) * 0.5
		var closest := Vector2(
			clampf(point.x, center.x - half_extents.x, center.x + half_extents.x),
			clampf(point.y, center.y - half_extents.y, center.y + half_extents.y)
		)
		return point.distance_to(closest) <= query_radius
	return false


func _distance_point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_sq := ab.length_squared()
	if length_sq <= 0.000001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / length_sq, 0.0, 1.0)
	return point.distance_to(a + ab * t)


func _occlusion_kind_for_feature(feature: Dictionary) -> String:
	var kind := String(feature.get("terrain_kind", ""))
	if kind == TERRAIN_KIND_WALL:
		return "solid"
	if kind == TERRAIN_KIND_GAP:
		return "gap"
	return kind if kind != "" else "terrain"


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
