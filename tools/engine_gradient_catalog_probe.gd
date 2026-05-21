extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var seen_ranks := {}
	var seen_families := {}
	var required_fields := [
		"power",
		"idle_heat",
		"mass",
		"cost",
		"slot_volume_tier",
		"heat_capacity",
		"engine_family",
		"engine_motion_scale",
		"engine_weapon_tags",
		"engine_team_role",
		"engine_heat_profile",
		"engine_recoil_stability",
		"engine_boost_control",
		"engine_command_drive",
		"engine_supply_load",
		"summary",
	]
	var catalog: Array = main._catalog_for("hero", "engine")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "engine", i)
		var name := String(part.get("name", "engine-%d" % i))
		for field in required_fields:
			if not part.has(field):
				_fail("%s missing required engine field %s" % [name, field])
		var rank := int(main._payload_slot_volume_rank("engine", part, {"kind": "engine"}, "engine"))
		if rank < 1 or rank > 5:
			_fail("%s has invalid slot rank %d" % [name, rank])
		seen_ranks[rank] = true
		var family := String(part.get("engine_family", "")).to_lower()
		seen_families[family] = true
		if float(part.get("power", 0.0)) + 0.01 < main._economy_engine_power_target(rank):
			_fail("%s power %.2f below same-size target %.2f" % [name, float(part.get("power", 0.0)), main._economy_engine_power_target(rank)])
		if float(part.get("idle_heat", 0.0)) <= 0.0:
			_fail("%s idle heat must be explicit and positive" % name)
		if float(part.get("engine_motion_scale", 0.0)) <= 0.0:
			_fail("%s engine_motion_scale must be positive" % name)
		if String(part.get("summary", "")).strip_edges() == "":
			_fail("%s summary must explain its use case" % name)
	for rank in range(1, 6):
		if not seen_ranks.has(rank):
			_fail("No engine exists for slot rank %d" % rank)
	for family in ["balanced", "melee_drive", "ranged_control", "booster_core", "swarm_lite", "siege_reactor"]:
		if not seen_families.has(family):
			_fail("Missing engine family %s" % family)
	if failed:
		quit(1)
		return
	print("ENGINE_GRADIENT_CATALOG_PROBE ok engines=%d families=%d ranks=%d" % [catalog.size(), seen_families.size(), seen_ranks.size()])
	quit()
