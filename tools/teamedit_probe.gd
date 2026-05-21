extends SceneTree

const MainScene := preload("res://scripts/main.gd")

func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._legalize_ai_player_roster(1, true)
	main._legalize_ai_player_roster(2, true)
	var hero_bp: Dictionary = main._blueprint_for(1, "hero", 0)
	var stats: Dictionary = main._compute_unit_stats(1, "hero", 0)
	var topology_note: String = main._topology_rule_note(hero_bp, "hero", stats)
	var runtime_segments: Array = stats.get("runtime_topology_segments", [])
	var runtime_bindings: Array = stats.get("runtime_module_bindings", [])
	var topology: Dictionary = hero_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var illegal_edges := 0
	for edge in edges:
		if edge is Array and edge.size() >= 2:
			var a := int(edge[0])
			var b := int(edge[1])
			if a >= 0 and b >= 0 and a < nodes.size() and b < nodes.size():
				if not main._topology_edge_can_connect(nodes[a], nodes[b]):
					illegal_edges += 1
	print("TEAMEDIT_PROBE nodes=%d edges=%d illegal_edges=%d note=%s runtime_segments=%d bindings=%d cost=%d deploy=%d" % [
		nodes.size(),
		edges.size(),
		illegal_edges,
		topology_note,
		runtime_segments.size(),
		runtime_bindings.size(),
		int(stats.get("cost", 0)),
		int(stats.get("deploy_cost", 0)),
	])
	var summary_1: Dictionary = main._team_summary(1)
	var summary_2: Dictionary = main._team_summary(2)
	print("TEAMEDIT_SUMMARY p1_valid=%s p2_valid=%s p1=%s p2=%s" % [
		str(bool(summary_1.get("valid", false))),
		str(bool(summary_2.get("valid", false))),
		String(summary_1.get("length_note", "")),
		String(summary_2.get("length_note", "")),
	])
	for role_key in MainScene.ROLE_ORDER:
		var roster: Array = main.blueprints[1][role_key]
		for i in range(roster.size()):
			var unit_bp: Dictionary = roster[i]
			var unit_stats: Dictionary = main._compute_unit_stats(1, role_key, i)
			var notes := []
			if main._role_uses_body_board(role_key):
				notes.append(main._module_material_rule_note(unit_bp))
				notes.append(main._topology_rule_note(unit_bp, role_key, unit_stats))
			for note_key in ["load_note", "slot_payload_note", "momentum_note", "power_note"]:
				if String(unit_stats.get(note_key, "")) != "":
					notes.append("%s=%s" % [note_key, String(unit_stats.get(note_key, ""))])
			print("TEAMEDIT_UNIT %s%d %s cost=%d deploy=%d len=%.2f notes=%s" % [
				role_key,
				i,
				String(unit_bp.get("name", "")),
				int(unit_stats.get("cost", 0)),
				int(unit_stats.get("deploy_cost", 0)),
				float(unit_stats.get("length", 0.0)),
				" | ".join(notes),
			])
	main._show_editor()
	main._clear_editor_team()
	var blank_bp: Dictionary = main._editor_current_blueprint()
	var blank_stats: Dictionary = main._editor_current_stats()
	var blank_summary: Dictionary = main._team_summary(1)
	print("TEAMEDIT_BLANK mode=%s nodes=%d pending=%s unit_cost=%d team_cost=%d" % [
		String(main.editor_canvas_mode),
		Array(Dictionary(blank_bp.get("custom_topology", {})).get("nodes", [])).size(),
		main._pending_canvas_part_name("hero"),
		int(blank_stats.get("cost", -1)),
		int(blank_summary.get("cost", -1)),
	])
	quit()
