extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	_require(fighter.has_method("_hardware_fault_visual_overlay_for_segment"), "Fighter should expose a hardware fault visual overlay contract.")
	if failed:
		quit(1)
		return
	var normal: Dictionary = fighter._hardware_fault_visual_overlay_for_segment({
		"node_index": 1,
		"name": "Normal Connector",
		"hardware_fault_state": "normal",
	})
	var faulted: Dictionary = fighter._hardware_fault_visual_overlay_for_segment({
		"node_index": 2,
		"name": "Faulted Connector",
		"hardware_fault_state": "faulted",
		"hardware_fault_transition_sequence": 2,
	})
	var destroyed: Dictionary = fighter._hardware_fault_visual_overlay_for_segment({
		"node_index": 3,
		"name": "Destroyed Connector",
		"hardware_fault_state": "destroyed",
	})
	_require(not bool(normal.get("visible", false)), "Normal hardware should not draw a fault overlay.")
	_require(bool(faulted.get("visible", false)), "Faulted hardware should draw an in-battle visual overlay.")
	var color: Color = faulted.get("color", Color.TRANSPARENT)
	_require(color.r >= 0.92 and color.g >= 0.42 and color.b <= 0.24 and color.a >= 0.34, "Faulted overlay should be a readable amber pulse color, got %s." % str(color))
	_require(String(faulted.get("label", "")) == "FAULT / 故障", "Faulted overlay should expose a non-color marker label.")
	_require(float(faulted.get("outline_width", 0.0)) >= 2.8, "Faulted overlay outline should be strong enough to read.")
	_require(not bool(destroyed.get("visible", false)), "Destroyed hardware should leave the fault overlay path; destruction has its own kill/cleanup flow.")
	var source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	_require(source.find("_hardware_fault_visual_overlay_for_segment(draw_segment)") >= 0, "Runtime segment drawing should query the hardware fault overlay contract.")
	_require(source.find("draw_runtime_segment_status_overlay(self, draw_segment") >= 0, "Runtime segment drawing should render the fault overlay through AssemblyBoardRenderer.")
	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_VISUAL_OVERLAY_PROBE ok color=%s" % str(color))
	quit()
