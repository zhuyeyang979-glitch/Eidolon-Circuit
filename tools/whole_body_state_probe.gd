extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "STATE_PROBE",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 32.0,
			"runtime_topology_segments": [
				{"node_index": 1, "part_kind": "limb_muscle", "a_local": Vector2.ZERO, "b_local": Vector2(0.8, 0.0), "mass": 4.0, "allocated_limb_momentum": 60.0},
			],
		},
	})
	fighter._apply_whole_body_action_state("armor", 0.5)
	if fighter.current_state != "armor" or fighter.state_timer <= 0.0:
		_fail("Armor state should be written to the whole fighter.")
	fighter._refresh_visuals()
	if fighter.state_flash == null or not fighter.state_flash.visible:
		_fail("Whole-body armor state should display a body-level flash.")
	fighter._apply_whole_body_action_state("active", 0.5)
	if fighter.current_state != "active" or fighter.state_timer <= 0.0:
		_fail("Active state should be written to the whole fighter.")
	print("WHOLE_BODY_STATE_PROBE ok")
	quit()
