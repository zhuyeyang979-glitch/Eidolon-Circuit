extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const TrainingValidationReportService := preload("res://scripts/services/training_validation_report_service.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _assert_contains(label: String, text: String, phrase: String) -> void:
	if text.find(phrase) < 0:
		_fail("%s missing phrase: %s" % [label, phrase])


func _assert_array_has_tag(tags: Array, tag: String) -> void:
	if not tags.has(tag):
		_fail("Expected reason tag %s in %s" % [tag, str(tags)])


func _init() -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	_assert_contains("README", readme, "## Attack Rule Explanation")
	_assert_contains("README", readme, "short cause tags")
	_assert_contains("README", readme, "Training validation")

	var plan := FileAccess.get_file_as_string("res://docs/plans/2026-06-15-attack-rule-explanation.md")
	_assert_contains("plan", plan, "Goal: help players understand why attacks work or fail")
	_assert_contains("plan", plan, "attack-result breakdown")
	_assert_contains("plan", plan, "attack_breakdowns")

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for required in [
		"attack_breakdowns",
		"_attack_rule_breakdown_for_result",
		"_training_validation_sample_record_attack_breakdown",
		"_attack_rule_live_feedback_status",
		"_attack_rule_explanation_build_preview_line",
		"_attack_rule_move_possibility_tags",
		"battle_attack_rule_log",
		"_record_battle_attack_rule_log",
		"_battle_attack_rule_summary_text",
		"_battle_review_diagnostic_summary_text",
	]:
		_assert_contains("main.gd", main_source, required)

	var service_source := FileAccess.get_file_as_string("res://scripts/services/training_validation_report_service.gd")
	for required in [
		"_runtime_attack_breakdown_lines",
		"命中解释",
		"Hit explanation",
	]:
		_assert_contains("training_validation_report_service.gd", service_source, required)

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main.battle_mode = MainScene.MODE_TRAINING
	main.ai_battle_seat = 1
	main._reset_training_validation_sample()

	if not main.has_method("_attack_rule_breakdown_for_result"):
		_fail("Main should expose _attack_rule_breakdown_for_result.")
	else:
		var breakdown: Dictionary = main._attack_rule_breakdown_for_result({
			"projectile": true,
			"damage_type": "bullet",
			"attack_key": 1,
			"group_name": "Probe Rifle",
			"projectile_material_resist": 0.82,
			"map_occlusion_kind": "barrier",
			"projectile_style": "beam",
		}, {
			"outcome": "hit",
			"raw_damage": 32.0,
			"final_damage": 21,
			"target_part_kind": "terminal",
			"target_part_name": "LEFT CLAW",
			"counter_tier": 2,
			"blocked": false,
		})
		var tags: Array = Array(breakdown.get("reason_tags", []))
		_assert_array_has_tag(tags, "hit")
		_assert_array_has_tag(tags, "material_down")
		_assert_array_has_tag(tags, "occluded")
		if String(breakdown.get("live_tag", "")) == "":
			_fail("Attack breakdown should expose a compact live tag.")
		if String(breakdown.get("text_zh", "")).find("LEFT CLAW") < 0 or String(breakdown.get("text_zh", "")).find("伤害") < 0:
			_fail("Attack breakdown should expose readable zh text: %s" % str(breakdown))

	if not main.has_method("_training_validation_sample_record_attack_breakdown"):
		_fail("Main should expose _training_validation_sample_record_attack_breakdown.")
	else:
		main._training_validation_sample_record_attack_breakdown(1, {
			"attack_label": "U键 / Probe Rifle",
			"outcome": "hit",
			"live_tag": "遮挡",
			"reason_tags": ["hit", "material_down", "occluded"],
			"text_zh": "U键 / Probe Rifle：命中 LEFT CLAW，伤害 21；材料不利，存在遮挡。",
			"text_en": "U / Probe Rifle: hit LEFT CLAW for 21 damage; material disadvantage and occlusion applied.",
		})
		var runtime: Dictionary = main._training_validation_sample_runtime_metrics()
		var breakdowns: Array = Array(runtime.get("attack_breakdowns", []))
		if breakdowns.size() != 1:
			_fail("Training runtime should carry one attack breakdown, got: %s" % str(runtime))
		main._record_battle_attack_rule_log(1, Dictionary(breakdowns[0]) if not breakdowns.is_empty() else {})
		if main.battle_attack_rule_log.size() != 1:
			_fail("Attack breakdown should also enter post-battle result log.")
		var review_summary: String = main._battle_attack_rule_summary_text(4)
		if review_summary.find("攻击结果") < 0 or review_summary.find("材料不利") < 0:
			_fail("Post-battle result log should summarize attack reasons: %s" % review_summary)

	if not main.has_method("_attack_rule_move_possibility_tags"):
		_fail("Main should expose _attack_rule_move_possibility_tags.")
	else:
		var melee_tags: Array = main._attack_rule_move_possibility_tags({
			"module_action_profile": "swing_180",
			"motion": "swing",
		}, {
			"category": "melee",
			"profile": "swing_180",
			"target_kind": "ball_joint",
		})
		if not melee_tags.has("横扫控距"):
			_fail("Swing profile should preview sweep control possibility: %s" % str(melee_tags))
		var missile_tags: Array = main._attack_rule_move_possibility_tags({
			"module_action_profile": "missile_lock_activate",
			"projectile_behavior": "missile",
		}, {
			"category": "ranged",
			"profile": "missile_lock_activate",
			"target_kind": "gun_terminal",
		})
		if not missile_tags.has("锁定射击"):
			_fail("Missile profile should preview lock-on shot possibility: %s" % str(missile_tags))
		var module_model: Dictionary = main._module_action_card_model({
			"module_action_profile": "swing_180",
			"module_target_kind": "ball_joint",
			"motion": "swing",
		})
		if not Array(module_model.get("move_possibility_tags", [])).has("横扫控距"):
			_fail("Action module card model should expose structured move possibilities: %s" % str(module_model))
		var module_detail: Dictionary = main._module_action_detail_model({
			"module_action_profile": "swing_180",
			"module_target_kind": "ball_joint",
			"motion": "swing",
		})
		if "\n".join(Array(module_detail.get("lines", []))).find("#招式可能性") < 0:
			_fail("Action module detail should visibly expose move possibilities.")

	var service := TrainingValidationReportService.new()
	var report := service.report({
		"intent_key": "ranged_pressure",
		"runtime": {
			"seconds": 4.0,
			"shots_fired": 1,
			"hits": 1,
			"damage_dealt": 21.0,
			"attack_breakdowns": [{
				"attack_label": "U键 / Probe Rifle",
				"outcome": "hit",
				"live_tag": "遮挡",
				"text_zh": "U键 / Probe Rifle：命中 LEFT CLAW，伤害 21；材料不利，存在遮挡。",
				"text_en": "U / Probe Rifle: hit LEFT CLAW for 21 damage; material disadvantage and occlusion applied.",
			}],
		},
	})
	var zh_text := service.report_text(report, "zh")
	var en_text := service.report_text(report, "en")
	if zh_text.find("命中解释") < 0 or zh_text.find("材料不利") < 0:
		_fail("Chinese training report should render hit explanation, got: %s" % zh_text)
	if en_text.find("Hit explanation") < 0 or en_text.find("material disadvantage") < 0:
		_fail("English training report should render hit explanation, got: %s" % en_text)

	root.remove_child(main)
	main.free()
	print("ATTACK_RULE_EXPLANATION_PROBE failed=%s" % str(failed))
	quit(1 if failed else 0)
