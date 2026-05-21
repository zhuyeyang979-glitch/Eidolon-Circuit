extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "Shield Probe",
		"stats": {
			"health": 100,
			"electronic_armor_max": 40.0,
			"electronic_armor_regen": 0.0,
			"counter_tiers": {},
			"resistances": {},
		},
	})
	fighter.deploy(0.0, 0.0)
	fighter.take_hit(25, "normal", 2, "blunt", "weapon")
	if fighter.health != 100:
		_fail("Shield did not absorb before HP; health=%d" % fighter.health)
	if absf(fighter.shield_value() - 15.0) > 0.01:
		_fail("Shield value after blunt hit expected 15, got %.2f" % fighter.shield_value())
	fighter.take_hit(20, "normal", 2, "blunt", "weapon")
	if fighter.health != 95 or absf(fighter.shield_value()) > 0.01:
		_fail("Shield spillover expected hp=95 shield=0, got hp=%d shield=%.2f" % [fighter.health, fighter.shield_value()])
	fighter.deploy(0.0, 0.0)
	fighter.take_hit(10, "normal", 2, "pierce", "weapon")
	if fighter.health != 100 or absf(fighter.shield_value() - 20.0) > 0.01:
		_fail("Pierce should apply double shield pressure; hp=%d shield=%.2f" % [fighter.health, fighter.shield_value()])

	var main = MainScene.new()
	root.add_child(main)
	var shield_catalog_ok := false
	for part in MainScene.COMMON_CATALOG["muscle"]:
		if part is Dictionary and bool(Dictionary(part).get("shield_payload", false)):
			shield_catalog_ok = true
			if int(Dictionary(part).get("hp", -1)) != 0 or float(Dictionary(part).get("radius", -1.0)) != 0.0 or float(Dictionary(part).get("length", -1.0)) != 0.0:
				_fail("Shield payload must have no HP and no physical volume: %s" % String(Dictionary(part).get("name", "")))
			if main._part_slot_volume_rank(part, "muscle") != 0.0:
				_fail("Shield payload should consume no slot volume: %s" % String(Dictionary(part).get("name", "")))
	if not shield_catalog_ok:
		_fail("No shield payload components found in muscle catalog.")
	var shield_rect := ColorRect.new()
	shield_rect.position = Vector2(34.0, 87.0)
	shield_rect.size = Vector2.ZERO
	main._set_corner_bar(shield_rect, 1, 330.0, 0.6)
	if shield_rect.size.x <= 190.0 or absf(shield_rect.position.x - 34.0) > 0.01:
		_fail("HUD shield bar geometry failed for P1: pos=%.1f width=%.1f" % [shield_rect.position.x, shield_rect.size.x])
	main._set_corner_bar(shield_rect, 2, 330.0, 0.5)
	if shield_rect.size.x <= 160.0 or shield_rect.position.x <= 34.0:
		_fail("HUD shield bar geometry failed for P2: pos=%.1f width=%.1f" % [shield_rect.position.x, shield_rect.size.x])
	print("SHIELD_PROBE absorb_ok hp=%d shield=%.1f bar_width=%.1f" % [fighter.health, fighter.shield_value(), shield_rect.size.x])
	shield_rect.queue_free()
	fighter.queue_free()
	main.queue_free()
	quit()
