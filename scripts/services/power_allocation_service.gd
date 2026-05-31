extends RefCounted
class_name PowerAllocationService


func totals(data: Dictionary) -> Dictionary:
	var thruster_drive := 0.0
	var thruster_boost_brake := 0.0
	var limb := 0.0
	for raw_entry in Array(data.get("entries", [])):
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var momentum := maxf(0.0, float(entry.get("momentum", 0.0)))
		match String(entry.get("kind", "")):
			"booster", "booster_drive":
				thruster_drive += momentum
			"booster_boost_brake":
				thruster_boost_brake += momentum
			"limb":
				limb += momentum
	var engine := maxf(0.0, float(data.get("engine_output", 0.0)))
	var thruster := thruster_drive + thruster_boost_brake
	return {
		"engine": engine,
		"thruster": thruster,
		"thruster_drive": thruster_drive,
		"thruster_boost_brake": thruster_boost_brake,
		"limb": limb,
		"remaining": maxf(0.0, engine - thruster - limb),
		"over": thruster + limb > engine + 0.001,
	}


func equalized_entry_momentum(entries: Array, engine_output: float) -> Dictionary:
	var pool := maxf(0.0, engine_output)
	var adjustable_items: Array = []
	var min_total := 0.0
	var range_total := 0.0
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var kind := String(entry.get("kind", ""))
		if not ["booster_drive", "booster_boost_brake", "limb"].has(kind):
			continue
		var entry_id := String(entry.get("id", ""))
		if entry_id == "":
			continue
		var min_momentum := maxf(0.0, float(entry.get("min_momentum", 0.0)))
		var max_momentum := maxf(min_momentum, float(entry.get("max_momentum", min_momentum)))
		adjustable_items.append({
			"id": entry_id,
			"min": min_momentum,
			"range": max_momentum - min_momentum,
		})
		min_total += min_momentum
		range_total += max_momentum - min_momentum
	var shared_range_percent := 0.0
	if range_total > 0.0:
		shared_range_percent = clampf((pool - min_total) / range_total, 0.0, 1.0)
	var result := {}
	for raw_item in adjustable_items:
		if not (raw_item is Dictionary):
			continue
		var item: Dictionary = raw_item
		result[String(item.get("id", ""))] = float(item.get("min", 0.0)) + float(item.get("range", 0.0)) * shared_range_percent
	return result
