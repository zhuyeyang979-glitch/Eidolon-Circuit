extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if main_source.strip_edges() == "":
		_fail("Unable to read main.gd")
		return
	if main_source.find("func _separate_unit_part_pair_gpu") >= 0:
		_fail("Legacy per-unit GPU pair function still exists")
		return
	if main_source.find("_gpu_collision_and_response_step(live_subjects, delta)") < 0:
		_fail("Runtime spacing does not call the full-scene GPU response step")
		return
	var spacing_start := main_source.find("func _resolve_unit_body_spacing")
	var pair_start := main_source.find("func _separate_unit_pair", spacing_start)
	if spacing_start < 0 or pair_start < 0:
		_fail("Unable to locate runtime spacing functions")
		return
	var spacing_body := main_source.substr(spacing_start, pair_start - spacing_start)
	if spacing_body.find("_collider_gap(") >= 0 or spacing_body.find("_separate_unit_part_pair(") >= 0:
		_fail("Runtime spacing still enters CPU geometry before GPU response step")
		return
	if main_source.find("func _resolve_runtime_gpu_contact_once") < 0:
		_fail("GPU contact response consumer is missing")
		return
	var melee_start := main_source.find("func _resolve_runtime_melee_attack")
	var resolve_start := main_source.find("func _resolve_attack", melee_start)
	if melee_start < 0 or resolve_start < 0:
		_fail("Unable to locate runtime melee/attack functions")
		return
	var melee_body := main_source.substr(melee_start, resolve_start - melee_start)
	var direct_guard := "if _unit_uses_direct_runtime_topology(attacker):"
	if melee_body.find(direct_guard) < 0:
		_fail("Runtime melee attack lacks direct-topology GPU-only guard")
		return
	var attack_hit_start := main_source.find("func _attack_part_hit")
	var attack_collider_start := main_source.find("func _attack_collider_for_event", attack_hit_start)
	if attack_hit_start < 0 or attack_collider_start < 0:
		_fail("Unable to locate attack hit function")
		return
	var attack_hit_body := main_source.substr(attack_hit_start, attack_collider_start - attack_hit_start)
	if attack_hit_body.find("_first_projectile_impact_gpu") < 0 or attack_hit_body.find("return {}") < 0:
		_fail("Runtime attack hit does not route projectile geometry to GPU query and block CPU melee geometry")
		return
	print("RUNTIME_NO_CPU_GEOMETRY_PROBE ok")
	quit()
