extends RefCounted
class_name RuntimeColliderGeometryService


func collider_center(collider: Dictionary) -> Vector2:
	if String(collider.get("shape", "circle")) == "polygon":
		var polygon := Array(collider.get("polygon", []))
		if polygon.is_empty():
			return Vector2.ZERO
		var sum := Vector2.ZERO
		var count := 0
		for raw_point in polygon:
			if raw_point is Vector2:
				sum += Vector2(raw_point)
				count += 1
		return sum / maxf(1.0, float(count))
	if String(collider.get("shape", "circle")) == "capsule":
		var a: Vector2 = collider.get("a", Vector2.ZERO)
		var b: Vector2 = collider.get("b", a)
		return (a + b) * 0.5
	return collider.get("center", Vector2.ZERO)


func collider_extent_radius(collider: Dictionary) -> float:
	var center := collider_center(collider)
	var result := 0.0
	if String(collider.get("shape", "circle")) == "polygon":
		for raw_point in Array(collider.get("polygon", [])):
			if raw_point is Vector2:
				result = maxf(result, center.distance_to(Vector2(raw_point)))
	elif String(collider.get("shape", "circle")) == "capsule":
		result = maxf(center.distance_to(Vector2(collider.get("a", center))), center.distance_to(Vector2(collider.get("b", center)))) + maxf(0.0, float(collider.get("radius", 0.0)))
	else:
		result = maxf(0.0, float(collider.get("radius", 0.0)))
	return maxf(result, 0.001)


func collider_bounding_radius(collider: Dictionary) -> float:
	if collider.has("bounding_radius"):
		return maxf(0.001, float(collider.get("bounding_radius", 0.0)))
	var center := collider_center(collider)
	var shape := String(collider.get("shape", "circle"))
	if shape == "polygon":
		var radius := 0.0
		for raw_point in Array(collider.get("polygon", [])):
			if raw_point is Vector2:
				radius = maxf(radius, center.distance_to(Vector2(raw_point)))
		return radius
	if shape == "capsule":
		var a: Vector2 = collider.get("a", center)
		var b: Vector2 = collider.get("b", a)
		return maxf(center.distance_to(a), center.distance_to(b)) + maxf(0.0, float(collider.get("radius", 0.0)))
	return maxf(0.0, float(collider.get("radius", 0.0)))


func collider_broadphase_gap(a: Dictionary, b: Dictionary) -> float:
	return collider_center(a).distance_to(collider_center(b)) - collider_bounding_radius(a) - collider_bounding_radius(b)


func collider_overlap_depth_estimate(a: Dictionary, b: Dictionary) -> float:
	var center_distance := collider_center(a).distance_to(collider_center(b))
	var raw_depth := collider_bounding_radius(a) + collider_bounding_radius(b) - center_distance
	return clampf(raw_depth, 0.001, 0.12)


func collider_hit_position(a: Dictionary, b: Dictionary) -> Vector2:
	return (collider_center(a) + collider_center(b)) * 0.5


func collider_segments(collider: Dictionary) -> Array:
	var shape := String(collider.get("shape", "circle"))
	if shape == "polygon":
		var polygon := Array(collider.get("polygon", []))
		var segments: Array = []
		for i in range(polygon.size()):
			if not (polygon[i] is Vector2):
				continue
			var next_index := (i + 1) % polygon.size()
			if not (polygon[next_index] is Vector2):
				continue
			segments.append([polygon[i], polygon[next_index]])
		return segments
	if shape == "capsule":
		return [[collider.get("a", Vector2.ZERO), collider.get("b", Vector2.ZERO)]]
	return []


func collider_gap(a: Dictionary, b: Dictionary) -> float:
	var a_radius: float = float(a.get("radius", 0.0))
	var b_radius: float = float(b.get("radius", 0.0))
	var a_shape := String(a.get("shape", "circle"))
	var b_shape := String(b.get("shape", "circle"))
	var distance := 0.0
	if a_shape == "polygon" or b_shape == "polygon":
		distance = polygon_collider_distance(a, b)
		if distance <= 0.0:
			return -collider_overlap_depth_estimate(a, b)
	elif a_shape == "capsule" and b_shape == "capsule":
		var a0: Vector2 = a.get("a", Vector2.ZERO)
		var a1: Vector2 = a.get("b", Vector2.ZERO)
		var b0: Vector2 = b.get("a", Vector2.ZERO)
		var b1: Vector2 = b.get("b", Vector2.ZERO)
		distance = segment_segment_distance(a0, a1, b0, b1)
	elif a_shape == "capsule":
		var point_b: Vector2 = b.get("center", Vector2.ZERO)
		var capsule_a0: Vector2 = a.get("a", Vector2.ZERO)
		var capsule_a1: Vector2 = a.get("b", Vector2.ZERO)
		distance = point_segment_distance(point_b, capsule_a0, capsule_a1)
	elif b_shape == "capsule":
		var point_a: Vector2 = a.get("center", Vector2.ZERO)
		var capsule_b0: Vector2 = b.get("a", Vector2.ZERO)
		var capsule_b1: Vector2 = b.get("b", Vector2.ZERO)
		distance = point_segment_distance(point_a, capsule_b0, capsule_b1)
	else:
		var center_a: Vector2 = a.get("center", Vector2.ZERO)
		var center_b: Vector2 = b.get("center", Vector2.ZERO)
		distance = center_a.distance_to(center_b)
	return distance - a_radius - b_radius


func collider_with_bounds(collider: Dictionary) -> Dictionary:
	var result: Dictionary = collider.duplicate(true)
	var center := collider_center(result)
	var min_point := center
	var max_point := center
	var radius := 0.0
	var polygon := Array(result.get("polygon", []))
	if polygon.size() > 0:
		var initialized := false
		for raw_point in polygon:
			if not (raw_point is Vector2):
				continue
			var point: Vector2 = raw_point
			if not initialized:
				min_point = point
				max_point = point
				initialized = true
			min_point.x = minf(min_point.x, point.x)
			min_point.y = minf(min_point.y, point.y)
			max_point.x = maxf(max_point.x, point.x)
			max_point.y = maxf(max_point.y, point.y)
			radius = maxf(radius, point.distance_to(center))
	else:
		var a: Vector2 = result.get("a", center) if result.get("a", center) is Vector2 else center
		var b: Vector2 = result.get("b", a) if result.get("b", a) is Vector2 else a
		var shape_radius := float(result.get("radius", 0.0))
		min_point = Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2.ONE * shape_radius
		max_point = Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2.ONE * shape_radius
		radius = maxf(a.distance_to(center), b.distance_to(center)) + shape_radius
	if radius <= 0.0:
		radius = maxf((max_point.x - min_point.x) * 0.5, (max_point.y - min_point.y) * 0.5)
	result["center"] = center
	result["bounding_radius"] = radius
	result["aabb_min"] = min_point
	result["aabb_max"] = max_point
	return result


func scale_collider_around_center(collider: Dictionary, scale_value: float) -> Dictionary:
	var scale := maxf(0.001, scale_value)
	if absf(scale - 1.0) <= 0.001:
		return collider
	var scaled := collider.duplicate(true)
	var center := collider_center(collider)
	scaled["visual_hitbox_scale"] = scale
	if scaled.has("radius"):
		scaled["radius"] = maxf(0.0, float(scaled.get("radius", 0.0)) * scale)
	for key in ["center", "a", "b", "pivot", "local_joint_center"]:
		if scaled.has(key) and scaled[key] is Vector2:
			var value: Vector2 = scaled[key]
			scaled[key] = center + (value - center) * scale
	if scaled.has("polygon"):
		var scaled_polygon: Array = []
		for raw_point in Array(scaled.get("polygon", [])):
			if raw_point is Vector2:
				var point: Vector2 = raw_point
				scaled_polygon.append(center + (point - center) * scale)
		if scaled_polygon.size() >= 3:
			scaled["polygon"] = scaled_polygon
	return scaled


func shift_collider_by_offset(collider: Dictionary, offset: Vector2) -> Dictionary:
	var shifted := collider.duplicate(true)
	if offset.length_squared() <= 0.00000001:
		return shifted
	for key in ["center", "a", "b", "pivot", "local_joint_center"]:
		if shifted.has(key) and shifted[key] is Vector2:
			var value: Vector2 = shifted[key]
			shifted[key] = value + offset
	if shifted.has("polygon"):
		var shifted_polygon: Array = []
		for raw_point in Array(shifted.get("polygon", [])):
			if raw_point is Vector2:
				shifted_polygon.append(Vector2(raw_point) + offset)
		if shifted_polygon.size() >= 3:
			shifted["polygon"] = shifted_polygon
	return shifted


func point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var inside := false
	var count := polygon.size()
	if count < 3:
		return false
	var j := count - 1
	for i in range(count):
		if not (polygon[i] is Vector2) or not (polygon[j] is Vector2):
			j = i
			continue
		var pi: Vector2 = polygon[i]
		var pj: Vector2 = polygon[j]
		if ((pi.y > point.y) != (pj.y > point.y)) and (point.x < (pj.x - pi.x) * (point.y - pi.y) / maxf(0.000001, pj.y - pi.y) + pi.x):
			inside = not inside
		j = i
	return inside


func polygon_collider_distance(a: Dictionary, b: Dictionary) -> float:
	var a_shape := String(a.get("shape", "circle"))
	var b_shape := String(b.get("shape", "circle"))
	var a_polygon := Array(a.get("polygon", []))
	var b_polygon := Array(b.get("polygon", []))
	if a_shape == "polygon" and b_shape == "polygon":
		for point in a_polygon:
			if point is Vector2 and point_in_polygon(point, b_polygon):
				return 0.0
		for point in b_polygon:
			if point is Vector2 and point_in_polygon(point, a_polygon):
				return 0.0
	elif a_shape == "polygon":
		var center_b := collider_center(b)
		if point_in_polygon(center_b, a_polygon):
			return 0.0
	elif b_shape == "polygon":
		var center_a := collider_center(a)
		if point_in_polygon(center_a, b_polygon):
			return 0.0
	var a_segments := collider_segments(a)
	var b_segments := collider_segments(b)
	for raw_a in a_segments:
		var seg_a: Array = raw_a
		for raw_b in b_segments:
			var seg_b: Array = raw_b
			if segments_intersect(seg_a[0], seg_a[1], seg_b[0], seg_b[1]):
				return 0.0
	var best := 999999.0
	if a_shape == "polygon":
		for point in a_polygon:
			if not (point is Vector2):
				continue
			if b_shape == "capsule":
				best = minf(best, point_segment_distance(point, b.get("a", Vector2.ZERO), b.get("b", Vector2.ZERO)))
			else:
				best = minf(best, point.distance_to(collider_center(b)))
	if b_shape == "polygon":
		for point in b_polygon:
			if not (point is Vector2):
				continue
			if a_shape == "capsule":
				best = minf(best, point_segment_distance(point, a.get("a", Vector2.ZERO), a.get("b", Vector2.ZERO)))
			else:
				best = minf(best, point.distance_to(collider_center(a)))
	for raw_a in a_segments:
		var seg_a: Array = raw_a
		for raw_b in b_segments:
			var seg_b: Array = raw_b
			best = minf(best, segment_segment_distance(seg_a[0], seg_a[1], seg_b[0], seg_b[1]))
	return best if best < 999998.0 else collider_center(a).distance_to(collider_center(b))


func point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var denom := ab.length_squared()
	if denom <= 0.000001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / denom, 0.0, 1.0)
	return point.distance_to(a + ab * t)


func segment_segment_distance(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	if segments_intersect(a, b, c, d):
		return 0.0
	return minf(
		minf(point_segment_distance(a, c, d), point_segment_distance(b, c, d)),
		minf(point_segment_distance(c, a, b), point_segment_distance(d, a, b))
	)


func segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var r := b - a
	var s := d - c
	var denom := r.cross(s)
	var qmp := c - a
	if absf(denom) <= 0.000001:
		return point_segment_distance(a, c, d) <= 0.0001 or point_segment_distance(c, a, b) <= 0.0001
	var t := qmp.cross(s) / denom
	var u := qmp.cross(r) / denom
	return t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0
