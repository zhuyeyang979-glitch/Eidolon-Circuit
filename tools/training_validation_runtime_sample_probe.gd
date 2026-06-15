extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _has_entry(entries: Array, kind: String, code_prefix: String) -> bool:
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		if String(entry.get("kind", "")) == kind and String(entry.get("code", "")).begins_with(code_prefix):
			return true
	return false


func _init() -> void:
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/main.gd"))
	for token in [
		"var training_validation_sample := {}",
		"func _reset_training_validation_sample",
		"func _training_validation_sample_record_shot",
		"func _training_validation_sample_record_hit",
		"func _training_validation_sample_record_boost",
		"func _training_validation_sample_runtime_metrics",
		"\"runtime\": _training_validation_sample_runtime_metrics()",
		"var health_before := int(target.health)",
		"health_before - int(target.health)",
	]:
		if source.find(token) < 0:
			_fail("Main training validation runtime sample integration missing token: %s" % token)
			return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = 1
	main._reset_training_validation_sample()
	var player_id: int = main._training_validation_sample_player_id()
	if player_id != 1:
		_fail("Training sample player should resolve to P1 by default.")
	main._training_validation_sample_record_shot(player_id, {"projectile": true, "ammo_kind": "bullet"})
	main._training_validation_sample_record_shot(player_id, {"projectile": true, "ammo_kind": "bullet"})
	main._training_validation_sample_record_hit(player_id, 8.0, {"projectile": true})
	var delayed_projectile := {"projectile": true, "ammo_kind": "laser"}
	main._training_validation_sample_record_shot(player_id, delayed_projectile)
	main._training_validation_sample_record_shot(player_id, delayed_projectile)
	main._training_validation_sample_record_hit(player_id, 5.0, {"projectile": false})
	main._training_validation_sample_record_ammo_spent(player_id, "bullet", 2)
	main._training_validation_sample_record_boost(player_id)
	main._training_validation_sample_record_motion(player_id, 1.35)
	main._training_validation_sample_record_heat(player_id, 145.0, 100.0, true)
	main._training_validation_sample_tick(4.0)

	var runtime: Dictionary = main._training_validation_sample_runtime_metrics()
	if int(runtime.get("shots_fired", 0)) != 3:
		_fail("Runtime sample should count one delayed projectile only once.")
	if int(runtime.get("hits", 0)) != 1:
		_fail("Runtime projectile hits should exclude melee contacts.")
	if absf(float(runtime.get("damage_dealt", 0.0)) - 13.0) > 0.01:
		_fail("Runtime damage should include projectile and melee damage.")
	if int(runtime.get("ammo_spent", 0)) != 2:
		_fail("Runtime sample should record ammo spent.")
	if int(runtime.get("boost_count", 0)) != 1:
		_fail("Runtime sample should record boost count.")
	if float(runtime.get("distance_moved", 0.0)) < 1.3:
		_fail("Runtime sample should record movement distance.")
	if float(runtime.get("heat_peak_ratio", 0.0)) < 1.44 or int(runtime.get("overheat_count", 0)) != 1:
		_fail("Runtime sample should record heat peak and overheat: %s" % str(runtime))

	var report: Dictionary = main._training_validation_report_for_current_training("ranged_pressure")
	var entries: Array = Array(report.get("entries", []))
	if not _has_entry(entries, "RISK", "heat:"):
		_fail("Runtime heat sample should flow into training report: %s" % str(entries))
	if not _has_entry(entries, "RISK", "accuracy:"):
		_fail("Runtime hit ratio should flow into training report: %s" % str(entries))
	var text := main._training_validation_report_text(report)
	if text.find("训练样本") < 0 and text.find("Training sample") < 0:
		_fail("Report text should expose runtime sample summary, got: %s" % text)
	if text.find("弹余 -1") >= 0 or text.find("ammo left -1") >= 0:
		_fail("Unknown remaining ammo should render as a placeholder, got: %s" % text)

	root.remove_child(main)
	main.free()
	if failed:
		quit(1)
		return
	print("TRAINING_VALIDATION_RUNTIME_SAMPLE_PROBE ok")
	quit(0)
