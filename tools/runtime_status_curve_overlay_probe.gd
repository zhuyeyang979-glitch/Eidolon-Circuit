extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const AssemblyBoardRendererScene := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _runtime_stats() -> Dictionary:
	return {
		"teamedit_runtime_topology": true,
		"runtime_visual_scale": 120.0,
		"length": 1.0,
		"radius": 0.22,
		"runtime_topology_segments": [
			{
				"node_index": 0,
				"part_kind": "torso",
				"name": "CORE",
				"a_local": Vector2(-0.18, 0.0),
				"b_local": Vector2(0.18, 0.0),
				"radius": 0.08,
				"material_class": "torso",
				"joint_ports": 4,
			},
			{
				"node_index": 1,
				"part_kind": "limb_muscle",
				"name": "ARM",
				"a_local": Vector2(0.18, 0.0),
				"b_local": Vector2(0.58, 0.0),
				"radius": 0.035,
				"material_class": "body",
			},
		],
	}


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"stats": _runtime_stats(),
	})
	fighter.deploy(10.0, 0.0)
	fighter.current_state = "armor"
	fighter.state_timer = 0.45
	fighter._refresh_visuals()
	if fighter.state_flash == null:
		_fail("State flash visual was not built.")
		return
	if fighter.state_flash.visible:
		_fail("Team-edit runtime unit still uses generic state_flash polygon.")
		return
	var color: Color = fighter._runtime_status_curve_overlay_color()
	if color.a <= 0.0:
		_fail("Armor state did not produce a curve overlay color.")
		return
	var segments: Array = fighter._runtime_status_curve_overlay_segments()
	if segments.size() != 2:
		_fail("Curve overlay did not use runtime topology segments; got %d." % segments.size())
		return
	var polygon := AssemblyBoardRendererScene.runtime_segment_overlay_polygon(Dictionary(segments[0]), Vector2(fighter.ring_pos, fighter.lane), fighter.rotation, fighter._runtime_visual_scale())
	if polygon.size() < 8:
		_fail("Overlay polygon is too small to follow the model curve; points=%d." % polygon.size())
		return
	var signature_before := fighter._runtime_visual_redraw_signature()
	fighter.set_meta("electronic_armor_flash", 0.18)
	var signature_after := fighter._runtime_visual_redraw_signature()
	if signature_before == signature_after:
		_fail("Runtime redraw signature ignored electronic armor flash changes.")
		return
	print("RUNTIME_STATUS_CURVE_OVERLAY_PROBE ok segments=%d points=%d" % [segments.size(), polygon.size()])
	quit()
