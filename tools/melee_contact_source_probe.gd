extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(owner_id: int):
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": owner_id,
		"role": "hero",
		"unit_name": "ContactProbe%d" % owner_id,
		"stats": {
			"health": 100,
			"mass": 10.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso"}],
		},
	})
	unit.deploy(float(owner_id), 0.0)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	var attacker = _make_unit(1)
	var target = _make_unit(2)
	var attacker_collider := {"part_kind": "terminal", "node_index": 10, "torso_unit_index": 0}
	var target_collider := {"part_kind": "torso", "node_index": 0, "torso_unit_index": 0}
	main._mark_active_melee_contact_suppression(attacker, attacker_collider, target, target_collider)
	if not main._active_melee_contact_damage_suppressed(target, target_collider, attacker, attacker_collider):
		_fail("Active melee suppression should block reciprocal target->attacker damage.")
		return
	if main._active_melee_contact_damage_suppressed(attacker, attacker_collider, target, target_collider):
		_fail("Active melee suppression must not block attacker->target damage.")
		return
	print("MELEE_CONTACT_SOURCE_PROBE ok")
	quit()
