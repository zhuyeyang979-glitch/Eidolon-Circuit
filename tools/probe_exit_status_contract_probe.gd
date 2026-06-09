extends SceneTree

const GUARDED_PROBES := {
	"res://tools/battle_actor_command_service_contract_probe.gd": [
		"var failures",
		"failures.append",
		"if not failures.is_empty()",
		"quit(1)",
		"return",
		"quit(0)",
	],
	"res://tools/battle_action_event_service_contract_probe.gd": [
		"var failures",
		"failures.append",
		"if not failures.is_empty()",
		"quit(1)",
		"return",
		"quit(0)",
	],
	"res://tools/battle_action_diagnostics_overlay_probe.gd": [
		"var failures",
		"failures.append",
		"if not failures.is_empty()",
		"quit(1)",
		"return",
		"quit(0)",
	],
	"res://tools/battle_real_training_movement_screen_direction_probe.gd": [
		"var failures",
		"failures.append",
		"if not failures.is_empty()",
		"quit(1)",
		"return",
		"quit(0)",
	],
	"res://tools/battle_runtime_action_telemetry_service_contract_probe.gd": [
		"var failures",
		"failures.append",
		"if not failures.is_empty()",
		"quit(1)",
		"return",
		"quit(0)",
	],
	"res://tools/battle_runtime_frame_budget_probe.gd": [
		"var failures",
		"failures.append",
		"if not failures.is_empty()",
		"quit(1)",
		"return",
		"quit(0)",
	],
	"res://tools/gun_activation_service_contract_probe.gd": [
		"var failures",
		"failures.append",
		"if not failures.is_empty()",
		"quit(1)",
		"return",
		"quit(0)",
	],
	"res://tools/held_melee_activation_service_contract_probe.gd": [
		"var failures",
		"failures.append",
		"if not failures.is_empty()",
		"quit(1)",
		"return",
		"quit(0)",
	],
	"res://tools/training_import_spawn_role_probe.gd": [
		"var failures",
		"failures.append",
		"if not failures.is_empty()",
		"quit(1)",
		"return",
		"quit(0)",
	],
}

var failures: Array = []


func _fail(message: String) -> void:
	push_error(message)
	failures.append(message)


func _init() -> void:
	for path in GUARDED_PROBES.keys():
		var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(String(path)))
		if source.is_empty():
			_fail("Guarded probe source is empty or missing: %s" % String(path))
		for token in Array(GUARDED_PROBES[path]):
			if source.find(String(token)) < 0:
				_fail("%s must preserve failure aggregation token: %s" % [String(path), String(token)])
	if not failures.is_empty():
		print("PROBE_EXIT_STATUS_CONTRACT_PROBE failed count=%d" % failures.size())
		quit(1)
		return
	print("PROBE_EXIT_STATUS_CONTRACT_PROBE ok guarded=%d" % GUARDED_PROBES.size())
	quit(0)
