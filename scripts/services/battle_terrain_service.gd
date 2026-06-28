extends RefCounted
class_name BattleTerrainService

const TERRAIN_KIND_FLOOR := "floor"
const TERRAIN_KIND_WALL := "wall"
const TERRAIN_KIND_GAP := "gap"
const TERRAIN_KIND_HAZARD := "hazard"
const TERRAIN_KIND_PORTAL := "portal"

const PLACEMENT_FREE := "free"
const PLACEMENT_ATTACH := "attach"
const PLACEMENT_BRIDGE := "bridge"
const PLACEMENT_REINFORCE := "reinforce"
const PLACEMENT_BREACH := "breach"
const PLACEMENT_PORTAL := "portal"
const PLACEMENT_MECHANISM := "mechanism"
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
	var breach := _first_matching_kind(overlaps, context.get("breach_kinds", []))
	if not breach.is_empty():
		if not bool(breach.get("destructible", false)):
			return _placement_result(PLACEMENT_BLOCKED, "blocked_indestructible_terrain", breach, overlaps)
		return _placement_result(PLACEMENT_BREACH, "breach_terrain_feature", breach, overlaps)
	var reinforce := _first_matching_kind(overlaps, context.get("reinforce_kinds", []))
	if not reinforce.is_empty():
		if not bool(reinforce.get("destructible", false)):
			return _placement_result(PLACEMENT_BLOCKED, "blocked_indestructible_terrain", reinforce, overlaps)
		return _placement_result(PLACEMENT_REINFORCE, "reinforce_terrain_feature", reinforce, overlaps)
	var replace := _first_matching_kind(overlaps, context.get("replace_kinds", []))
	if not replace.is_empty():
		return _placement_result(PLACEMENT_REPLACE, "replace_terrain", replace, overlaps)
	var attach := _first_matching_kind(overlaps, context.get("attach_kinds", []))
	if not attach.is_empty():
		return _placement_result(PLACEMENT_ATTACH, "attach_to_terrain", attach, overlaps, _nearest_anchor(attach, position))
	var bridge := _first_matching_kind(overlaps, context.get("bridge_kinds", []))
	if not bridge.is_empty():
		return _placement_result(PLACEMENT_BRIDGE, "bridge_terrain_gap", bridge, overlaps)
	var portal := _first_matching_kind(overlaps, context.get("portal_kinds", []))
	if not portal.is_empty():
		return _placement_result(PLACEMENT_PORTAL, "activate_terrain_portal", portal, overlaps)
	var mechanism := _first_matching_kind(overlaps, context.get("mechanism_kinds", []))
	if not mechanism.is_empty():
		return _placement_result(PLACEMENT_MECHANISM, "trigger_arena_mechanism", mechanism, overlaps)
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


func traversal_query(context: Dictionary) -> Dictionary:
	var snapshot := _dict(context.get("snapshot", {}))
	var start := _vec(context.get("start", Vector2.INF), Vector2.INF)
	var target := _vec(context.get("target", Vector2.INF), Vector2.INF)
	if start == Vector2.INF or target == Vector2.INF:
		return _traversal_clear_result("clear_invalid_endpoint")
	var path_radius := maxf(0.0, float(context.get("radius", context.get("path_radius", 0.0))))
	var ring_length := maxf(0.0, float(context.get("ring_length", 0.0)))
	var bridge_feature_ids := _bridge_feature_ids(context.get("bridge_intents", []))
	var best: Dictionary = {}
	var best_priority := -999999
	for raw_feature in Array(snapshot.get("features", [])):
		var feature := _dict(raw_feature)
		if feature.is_empty() or not _feature_affects_traversal(feature):
			continue
		var overlap := _path_overlaps_feature(start, target, path_radius, feature, ring_length)
		if not bool(overlap.get("hit", false)):
			continue
		var candidate := _traversal_result_for_feature(feature, start, target, overlap, bridge_feature_ids)
		var priority := _traversal_priority(candidate)
		if priority > best_priority:
			best_priority = priority
			best = candidate
	if best.is_empty():
		return _traversal_clear_result("clear_path")
	return best


func _placement_result(outcome: String, reason: String, feature: Dictionary, overlaps: Array = [], anchor: Dictionary = {}) -> Dictionary:
	var result := {
		"outcome": outcome,
		"reason": reason,
		"reason_text": reason.replace("_", " "),
		"feature_id": String(feature.get("feature_id", "")),
		"terrain_kind": String(feature.get("terrain_kind", "")),
		"destructible": bool(feature.get("destructible", false)),
		"overlaps": overlaps,
	}
	if not anchor.is_empty():
		result["anchor_id"] = String(anchor.get("anchor_id", ""))
		result["anchor"] = anchor.duplicate(true)
	return result


func _traversal_clear_result(reason: String) -> Dictionary:
	return {
		"mode": "clear",
		"blocked": false,
		"reason": reason,
		"path_modifier": "none",
		"feature_id": "",
		"terrain_kind": "",
		"surface_tags": [],
		"bridge_active": false,
		"recommended_direction": Vector2.ZERO,
	}


func _traversal_result_for_feature(feature: Dictionary, start: Vector2, target: Vector2, overlap: Dictionary, bridge_feature_ids: Array) -> Dictionary:
	var feature_id := String(feature.get("feature_id", ""))
	var terrain_kind := String(feature.get("terrain_kind", ""))
	var tags := Array(feature.get("surface_tags", []))
	var bridge_active := bridge_feature_ids.has(feature_id)
	var route_direction := _normalized_or(_vec(feature.get("orientation", target - start), target - start), target - start)
	var detour_direction := _terrain_detour_direction(start, target, _vec(overlap.get("center", (start + target) * 0.5), (start + target) * 0.5))
	var mode := "route"
	var blocked := false
	var path_modifier := "route"
	var recommended_direction := route_direction
	if terrain_kind == TERRAIN_KIND_GAP:
		if bridge_active:
			mode = "bridged"
			path_modifier = "bridge"
			recommended_direction = route_direction
		else:
			mode = "blocked"
			blocked = true
			path_modifier = "detour"
			recommended_direction = detour_direction
	elif terrain_kind == TERRAIN_KIND_HAZARD or tags.has("hazard"):
		mode = "hazard"
		path_modifier = "avoid"
		recommended_direction = detour_direction
	return {
		"mode": mode,
		"blocked": blocked,
		"reason": "%s_terrain_path" % mode,
		"path_modifier": path_modifier,
		"feature_id": feature_id,
		"terrain_kind": terrain_kind,
		"surface_tags": tags.duplicate(true),
		"bridge_active": bridge_active,
		"recommended_direction": recommended_direction,
		"route_direction": route_direction,
		"detour_direction": detour_direction,
		"distance_to_path": float(overlap.get("distance", 0.0)),
		"source": "terrain",
	}


func _traversal_priority(result: Dictionary) -> int:
	var mode := String(result.get("mode", ""))
	if mode == "blocked":
		return 100
	if mode == "hazard":
		return 80
	if mode == "bridged":
		return 60
	if mode == "route":
		return 40
	return 0


func _feature_affects_traversal(feature: Dictionary) -> bool:
	var terrain_kind := String(feature.get("terrain_kind", ""))
	if terrain_kind in [TERRAIN_KIND_GAP, TERRAIN_KIND_HAZARD]:
		return true
	var channels := Array(feature.get("effect_channels", []))
	if channels.has("traversal"):
		return true
	var tags := Array(feature.get("surface_tags", []))
	for tag in ["route", "speed_route", "speed_lane", "bridgeable", "hazard", "gap"]:
		if tags.has(tag):
			return true
	return false


func _path_overlaps_feature(start: Vector2, target: Vector2, path_radius: float, feature: Dictionary, ring_length: float) -> Dictionary:
	var collider := _dict(feature.get("collider", {}))
	if collider.is_empty():
		return {"hit": false}
	var shifts := [0.0]
	if ring_length > 0.001:
		shifts = [-ring_length, 0.0, ring_length]
	var best_distance := INF
	var best_center := Vector2.ZERO
	var hit := false
	for raw_shift in shifts:
		var shifted := _shift_collider(collider, Vector2(float(raw_shift), 0.0))
		var distance := _distance_segment_to_collider(start, target, shifted)
		if distance < best_distance:
			best_distance = distance
			best_center = _collider_center(shifted)
		if _segment_overlaps_collider(start, target, path_radius, shifted):
			hit = true
	if not hit:
		return {"hit": false, "distance": best_distance, "center": best_center}
	return {"hit": true, "distance": best_distance, "center": best_center}


func _bridge_feature_ids(value) -> Array:
	var ids: Array = []
	for raw_intent in Array(value):
		var intent := _dict(raw_intent)
		if String(intent.get("action", "")) != "bridge_terrain_gap":
			continue
		var feature_id := String(intent.get("feature_id", ""))
		if feature_id != "" and not ids.has(feature_id):
			ids.append(feature_id)
	return ids


func _terrain_detour_direction(start: Vector2, target: Vector2, center: Vector2) -> Vector2:
	var path_dir := _normalized_or(target - start, Vector2.RIGHT)
	var side := Vector2(-path_dir.y, path_dir.x)
	var mid := (start + target) * 0.5
	var sign_value := signf((mid - center).dot(side))
	if sign_value == 0.0:
		sign_value = signf((start - center).dot(side))
	if sign_value == 0.0:
		sign_value = 1.0
	return (side * sign_value).normalized()


func _segment_overlaps_collider(a: Vector2, b: Vector2, query_radius: float, collider: Dictionary) -> bool:
	var shape := String(collider.get("shape", "circle"))
	if shape == "circle":
		var center := _vec(collider.get("center", Vector2.ZERO))
		var radius := maxf(0.0, float(collider.get("radius", 0.0)))
		return _distance_point_to_segment(center, a, b) <= radius + query_radius
	if shape in ["segment", "capsule"]:
		var segment_a := _vec(collider.get("a", collider.get("start", Vector2.ZERO)))
		var segment_b := _vec(collider.get("b", collider.get("end", segment_a)))
		var radius := maxf(0.0, float(collider.get("radius", 0.0)))
		return _distance_segment_to_segment(a, b, segment_a, segment_b) <= radius + query_radius
	if shape == "rect":
		var center := _vec(collider.get("center", Vector2.ZERO))
		var half_extents := _vec(collider.get("half_extents", Vector2.ZERO))
		if half_extents == Vector2.ZERO and collider.has("size"):
			half_extents = _vec(collider.get("size", Vector2.ZERO)) * 0.5
		return _segment_intersects_rect(a, b, center, half_extents + Vector2(query_radius, query_radius))
	return false


func _distance_segment_to_collider(a: Vector2, b: Vector2, collider: Dictionary) -> float:
	var shape := String(collider.get("shape", "circle"))
	if shape == "circle":
		var center := _vec(collider.get("center", Vector2.ZERO))
		var radius := maxf(0.0, float(collider.get("radius", 0.0)))
		return maxf(0.0, _distance_point_to_segment(center, a, b) - radius)
	if shape in ["segment", "capsule"]:
		var segment_a := _vec(collider.get("a", collider.get("start", Vector2.ZERO)))
		var segment_b := _vec(collider.get("b", collider.get("end", segment_a)))
		var radius := maxf(0.0, float(collider.get("radius", 0.0)))
		return maxf(0.0, _distance_segment_to_segment(a, b, segment_a, segment_b) - radius)
	if shape == "rect":
		return _distance_point_to_segment(_collider_center(collider), a, b)
	return INF


func _distance_segment_to_segment(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	if _segments_intersect(a, b, c, d):
		return 0.0
	return minf(
		minf(_distance_point_to_segment(a, c, d), _distance_point_to_segment(b, c, d)),
		minf(_distance_point_to_segment(c, a, b), _distance_point_to_segment(d, a, b))
	)


func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var ab := b - a
	var cd := d - c
	var ac := c - a
	var ad := d - a
	var ca := a - c
	var cb := b - c
	var cross1 := _cross2(ab, ac)
	var cross2 := _cross2(ab, ad)
	var cross3 := _cross2(cd, ca)
	var cross4 := _cross2(cd, cb)
	if absf(cross1) <= 0.00001 and _point_on_segment(c, a, b):
		return true
	if absf(cross2) <= 0.00001 and _point_on_segment(d, a, b):
		return true
	if absf(cross3) <= 0.00001 and _point_on_segment(a, c, d):
		return true
	if absf(cross4) <= 0.00001 and _point_on_segment(b, c, d):
		return true
	return (cross1 > 0.0) != (cross2 > 0.0) and (cross3 > 0.0) != (cross4 > 0.0)


func _point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> bool:
	return point.x >= minf(a.x, b.x) - 0.00001 and point.x <= maxf(a.x, b.x) + 0.00001 and point.y >= minf(a.y, b.y) - 0.00001 and point.y <= maxf(a.y, b.y) + 0.00001


func _segment_intersects_rect(a: Vector2, b: Vector2, center: Vector2, half_extents: Vector2) -> bool:
	var min_point := center - half_extents
	var max_point := center + half_extents
	if _point_in_rect(a, min_point, max_point) or _point_in_rect(b, min_point, max_point):
		return true
	var top_left := Vector2(min_point.x, min_point.y)
	var top_right := Vector2(max_point.x, min_point.y)
	var bottom_right := Vector2(max_point.x, max_point.y)
	var bottom_left := Vector2(min_point.x, max_point.y)
	return _segments_intersect(a, b, top_left, top_right) or _segments_intersect(a, b, top_right, bottom_right) or _segments_intersect(a, b, bottom_right, bottom_left) or _segments_intersect(a, b, bottom_left, top_left)


func _point_in_rect(point: Vector2, min_point: Vector2, max_point: Vector2) -> bool:
	return point.x >= min_point.x and point.x <= max_point.x and point.y >= min_point.y and point.y <= max_point.y


func _shift_collider(collider: Dictionary, offset: Vector2) -> Dictionary:
	var result := collider.duplicate(true)
	if result.has("center") and result.get("center") is Vector2:
		result["center"] = _vec(result.get("center", Vector2.ZERO)) + offset
	for key in ["a", "b", "start", "end", "position"]:
		if result.has(key) and result.get(key) is Vector2:
			result[key] = _vec(result.get(key, Vector2.ZERO)) + offset
	return result


func _collider_center(collider: Dictionary) -> Vector2:
	if collider.has("center") and collider.get("center") is Vector2:
		return _vec(collider.get("center", Vector2.ZERO))
	if collider.has("a") and collider.has("b"):
		return (_vec(collider.get("a", Vector2.ZERO)) + _vec(collider.get("b", Vector2.ZERO))) * 0.5
	if collider.has("start") and collider.has("end"):
		return (_vec(collider.get("start", Vector2.ZERO)) + _vec(collider.get("end", Vector2.ZERO))) * 0.5
	if collider.has("position") and collider.get("position") is Vector2:
		return _vec(collider.get("position", Vector2.ZERO))
	return Vector2.ZERO


func _cross2(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x


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
