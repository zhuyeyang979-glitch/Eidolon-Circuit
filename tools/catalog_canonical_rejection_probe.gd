extends SceneTree

const DataRuleService := preload("res://scripts/services/data_rule_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var rules := DataRuleService.new()
	var bad_module := {"module_action_profile": "two_link_forward_snap", "normal_damage": 8}
	if rules.canonical_part_rejection_reason("module", bad_module).find("normal_damage") < 0:
		_fail("Action module raw damage field is not diagnosed.")
		return
	var bad_equipment := {"kind": "engine", "hp": 12}
	if rules.canonical_part_rejection_reason("engine", bad_equipment).find("hp") < 0:
		_fail("Equipment HP field is not diagnosed.")
		return
	var bad_gun := {"projectile": true, "gun_kind": "rifle", "projectile_damage_coeff": 3.0}
	if rules.canonical_part_rejection_reason("muscle", bad_gun).find("projectile_damage_coeff") < 0:
		_fail("Gun legacy damage field is not diagnosed.")
		return
	var canonical := rules.canonical_catalog_part(bad_gun, "muscle")
	if rules.canonical_part_rejection_reason("muscle", canonical) != "":
		_fail("Canonical catalog part remains invalid after the authoritative conversion.")
		return
	print("CATALOG_CANONICAL_REJECTION_PROBE ok")
	quit()
