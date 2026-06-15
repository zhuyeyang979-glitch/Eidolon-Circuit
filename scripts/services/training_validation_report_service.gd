extends RefCounted
class_name TrainingValidationReportService

const HeatDoctrineService = preload("res://scripts/services/heat_doctrine_service.gd")

const KIND_OBSERVE := "OBSERVE"
const KIND_RISK := "RISK"
const KIND_COUNTER := "COUNTER"
const KIND_SUGGEST := "SUGGEST"

const INTENT_LABELS := {
	"ranged_pressure": {
		"zh": "远程压制",
		"en": "ranged pressure",
	},
	"close_burst": {
		"zh": "近身爆发",
		"en": "close burst",
	},
	"mobile_pick": {
		"zh": "机动点杀",
		"en": "mobile pick",
	},
	"barrier_anchor": {
		"zh": "阵地控制",
		"en": "barrier anchor",
	},
	"summon_expand": {
		"zh": "召唤铺场",
		"en": "summon expansion",
	},
	"general_validation": {
		"zh": "通用验证",
		"en": "general validation",
	},
}

const KIND_LABELS_ZH := {
	KIND_OBSERVE: "观察",
	KIND_RISK: "风险",
	KIND_COUNTER: "克制",
	KIND_SUGGEST: "建议",
}

const KIND_LABELS_EN := {
	KIND_OBSERVE: "OBSERVE",
	KIND_RISK: "RISK",
	KIND_COUNTER: "COUNTER",
	KIND_SUGGEST: "SUGGEST",
}

var heat_doctrine = HeatDoctrineService.new()


func report(context: Dictionary) -> Dictionary:
	var units: Array = Array(context.get("units", []))
	var runtime: Dictionary = Dictionary(context.get("runtime", {}))
	var metrics := _metrics_for(units, runtime)
	var intent_key := _resolve_intent_key(context, metrics)
	var intent_source := "player" if String(context.get("intent_key", "")).strip_edges() != "" else String(context.get("intent_source", "auto"))
	var entries: Array = []
	_add_observation(entries, intent_key, metrics)
	_add_heat_rhythm_observation(entries, metrics, runtime)
	_add_static_risks(entries, intent_key, metrics)
	_add_runtime_risks(entries, runtime)
	_add_counter(entries, intent_key, metrics)
	_add_suggestions(entries, intent_key, metrics, runtime)
	if entries.is_empty():
		entries.append(_entry(
			KIND_OBSERVE,
			"intent:general_validation",
			"当前训练样本还不足，先记录机体动作、距离、热量和命中反馈。",
			"Training sample is still sparse; first observe movement, range, heat, and hit feedback."
		))
	return {
		"blocking": false,
		"advisory_only": true,
		"intent_key": intent_key,
		"intent_source": intent_source,
		"intent_label_zh": _intent_label(intent_key, "zh"),
		"intent_label_en": _intent_label(intent_key, "en"),
		"metrics": metrics,
		"heat_core": heat_doctrine.build_profile(maxf(float(metrics.get("max_heat_ratio", 0.0)), float(runtime.get("heat_peak_ratio", 0.0)))),
		"runtime": runtime.duplicate(true),
		"entries": entries,
	}


func report_text(report_data: Dictionary, language: String = "zh") -> String:
	var use_zh := not language.begins_with("en")
	var entries: Array = Array(report_data.get("entries", []))
	var intent_key := String(report_data.get("intent_key", "general_validation"))
	var intent_source := String(report_data.get("intent_source", "auto"))
	var runtime: Dictionary = Dictionary(report_data.get("runtime", {}))
	var ammo_remaining := int(runtime.get("ammo_remaining", -1))
	var ammo_remaining_text := str(ammo_remaining) if ammo_remaining >= 0 else "--"
	var lines: Array = []
	if use_zh:
		lines.append("训练验证报告")
		lines.append("%s：%s" % ["玩家目标" if intent_source == "player" else "系统观察", _intent_label(intent_key, "zh")])
		lines.append("提示只作为建议，不会阻止保存或出战。")
		lines.append("核心概念：热量决定进攻、撤退、停止行动和主动散热的战斗节奏。")
		lines.append("战斗逻辑：输出应形成爆发窗口，不是无限连续攻击；低热量英雄、短爆发循环、压线循环和红温超限都可以成为玩法方向。")
		if _runtime_sample_has_values(runtime):
			lines.append("训练样本：%.1fs / 开火 %d / 命中 %d / 伤害 %.0f / 热峰 %.0f%% / 弹余 %s / Boost %d / 移动 %.1fm" % [
				float(runtime.get("seconds", 0.0)),
				int(runtime.get("shots_fired", 0)),
				int(runtime.get("hits", 0)),
				float(runtime.get("damage_dealt", 0.0)),
				float(runtime.get("heat_peak_ratio", 0.0)) * 100.0,
				ammo_remaining_text,
				int(runtime.get("boost_count", 0)),
				float(runtime.get("distance_moved", 0.0)),
			])
		for breakdown_line in _runtime_attack_breakdown_lines(runtime, true):
			lines.append(breakdown_line)
	else:
		lines.append("TRAINING VALIDATION")
		lines.append("%s: %s" % ["Player Goal" if intent_source == "player" else "Observed Intent", _intent_label(intent_key, "en")])
		lines.append("Advisory only; this report never blocks save or sortie.")
		lines.append("Core concept: heat sets the combat rhythm between attack, disengage, stop, and active cooling.")
		lines.append("Combat logic: offense forms burst windows rather than infinite continuous attacks; low-heat endurance, short-burst loops, pressure loops, and redline overlimit can all be valid playstyle directions.")
		if _runtime_sample_has_values(runtime):
			lines.append("Training sample: %.1fs / shots %d / hits %d / damage %.0f / heat peak %.0f%% / ammo left %s / Boost %d / moved %.1fm" % [
				float(runtime.get("seconds", 0.0)),
				int(runtime.get("shots_fired", 0)),
				int(runtime.get("hits", 0)),
				float(runtime.get("damage_dealt", 0.0)),
				float(runtime.get("heat_peak_ratio", 0.0)) * 100.0,
				ammo_remaining_text,
				int(runtime.get("boost_count", 0)),
				float(runtime.get("distance_moved", 0.0)),
			])
		for breakdown_line in _runtime_attack_breakdown_lines(runtime, false):
			lines.append(breakdown_line)
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var kind := String(entry.get("kind", KIND_OBSERVE))
		var label := String(KIND_LABELS_ZH.get(kind, kind)) if use_zh else String(KIND_LABELS_EN.get(kind, kind))
		var text := String(entry.get("text_zh", "")) if use_zh else String(entry.get("text_en", ""))
		if text.strip_edges() == "":
			continue
		lines.append("%s：%s" % [label, text] if use_zh else "%s: %s" % [label, text])
	return "\n".join(lines)


func _runtime_sample_has_values(runtime: Dictionary) -> bool:
	if runtime.is_empty():
		return false
	return float(runtime.get("seconds", 0.0)) > 0.0 \
		or int(runtime.get("shots_fired", 0)) > 0 \
		or int(runtime.get("hits", 0)) > 0 \
		or float(runtime.get("damage_dealt", 0.0)) > 0.0 \
		or float(runtime.get("heat_peak_ratio", 0.0)) > 0.0 \
		or int(runtime.get("overheat_count", 0)) > 0 \
		or int(runtime.get("ammo_spent", 0)) > 0 \
		or int(runtime.get("ammo_remaining", -1)) >= 0 \
		or int(runtime.get("boost_count", 0)) > 0 \
		or float(runtime.get("distance_moved", 0.0)) > 0.0 \
		or not Array(runtime.get("attack_breakdowns", [])).is_empty()


func _runtime_attack_breakdown_lines(runtime: Dictionary, use_zh: bool) -> Array:
	var breakdowns: Array = Array(runtime.get("attack_breakdowns", []))
	if breakdowns.is_empty():
		return []
	var lines: Array = []
	lines.append("命中解释：" if use_zh else "Hit explanation:")
	var count := 0
	for raw_breakdown in breakdowns:
		if not (raw_breakdown is Dictionary):
			continue
		var breakdown: Dictionary = raw_breakdown
		var text := String(breakdown.get("text_zh", "")) if use_zh else String(breakdown.get("text_en", ""))
		if text.strip_edges() == "":
			text = _fallback_attack_breakdown_text(breakdown, use_zh)
		if text.strip_edges() == "":
			continue
		lines.append("- %s" % text)
		count += 1
		if count >= 4:
			break
	return lines


func _fallback_attack_breakdown_text(breakdown: Dictionary, use_zh: bool) -> String:
	var attack_label := String(breakdown.get("attack_label", "ATTACK"))
	var live_tag := String(breakdown.get("live_tag", "结果")) if use_zh else String(breakdown.get("live_tag_en", "result"))
	var damage := int(breakdown.get("final_damage", breakdown.get("damage", 0)))
	if use_zh:
		return "%s：%s，伤害 %d。" % [attack_label, live_tag, damage] if damage > 0 else "%s：%s。" % [attack_label, live_tag]
	return "%s: %s, %d damage." % [attack_label, live_tag, damage] if damage > 0 else "%s: %s." % [attack_label, live_tag]


func _metrics_for(units: Array, runtime: Dictionary) -> Dictionary:
	var unit_count := 0
	var total_cost := 0
	var total_ammo := 0
	var max_range := 0.0
	var max_damage := 0
	var total_damage := 0
	var max_speed := 0.0
	var avg_speed := 0.0
	var avg_turn := 0.0
	var max_boost := 0.0
	var max_heat_ratio := 0.0
	var max_group_count := 1
	var barrier_like_count := 0
	var projectile_count := 0
	var support_count := 0
	for raw_unit in units:
		if not (raw_unit is Dictionary):
			continue
		var unit: Dictionary = raw_unit
		var stats: Dictionary = Dictionary(unit.get("stats", {}))
		unit_count += 1
		total_cost += int(stats.get("cost", stats.get("deploy_cost", 0)))
		total_ammo += _ammo_total(stats.get("ammo_capacity", {}))
		var unit_range := maxf(float(stats.get("projectile_range", 0.0)), maxf(float(stats.get("normal_range", 0.0)), float(stats.get("active_range", 0.0))))
		max_range = maxf(max_range, unit_range)
		var unit_damage := maxi(int(stats.get("normal_damage", 0)), maxi(int(stats.get("armor_damage", 0)), int(stats.get("active_damage", 0))))
		max_damage = maxi(max_damage, unit_damage)
		total_damage += unit_damage
		var speed := float(stats.get("speed", 0.0))
		var turn_speed := float(stats.get("turn_speed", 0.0))
		var boost_speed := float(stats.get("boost_speed", 0.0))
		avg_speed += speed
		avg_turn += turn_speed
		max_speed = maxf(max_speed, speed)
		max_boost = maxf(max_boost, boost_speed)
		var heat_capacity := maxf(0.0, float(stats.get("heat_capacity", 0.0)))
		var heat_load := maxf(float(stats.get("normal_heat", 0.0)), float(stats.get("active_heat", 0.0)))
		if heat_capacity > 0.0:
			max_heat_ratio = maxf(max_heat_ratio, heat_load / heat_capacity)
		if bool(stats.get("projectile", false)) or String(stats.get("projectile_style", "")) != "" or unit_range >= 2.4:
			projectile_count += 1
		if String(unit.get("role", "")) == "barrier" or int(stats.get("material_slots", 0)) > 0 or float(stats.get("space_size", 0.0)) > 0.0:
			barrier_like_count += 1
		if bool(stats.get("is_support_node", false)) or bool(stats.get("is_trap_field", false)) or bool(stats.get("is_speed_lane", false)):
			support_count += 1
		max_group_count = maxi(max_group_count, int(stats.get("group_count", 1)))
	if unit_count > 0:
		avg_speed /= float(unit_count)
		avg_turn /= float(unit_count)
	var runtime_shots := int(runtime.get("shots_fired", 0))
	var runtime_hits := int(runtime.get("hits", 0))
	var hit_ratio := -1.0
	if runtime_shots > 0:
		hit_ratio = float(runtime_hits) / float(runtime_shots)
	return {
		"unit_count": unit_count,
		"total_cost": total_cost,
		"total_ammo": total_ammo,
		"max_range": max_range,
		"max_damage": max_damage,
		"total_damage": total_damage,
		"max_speed": max_speed,
		"avg_speed": avg_speed,
		"avg_turn_speed": avg_turn,
		"max_boost_speed": max_boost,
		"max_heat_ratio": max_heat_ratio,
		"max_group_count": max_group_count,
		"barrier_like_count": barrier_like_count,
		"projectile_count": projectile_count,
		"support_count": support_count,
		"runtime_hit_ratio": hit_ratio,
	}


func _resolve_intent_key(context: Dictionary, metrics: Dictionary) -> String:
	var explicit := String(context.get("intent_key", "")).strip_edges()
	if explicit != "":
		return explicit
	if int(metrics.get("barrier_like_count", 0)) > 0 or int(metrics.get("support_count", 0)) > 0:
		return "barrier_anchor"
	if int(metrics.get("max_group_count", 1)) > 1:
		return "summon_expand"
	if float(metrics.get("max_range", 0.0)) >= 2.5 or int(metrics.get("projectile_count", 0)) > 0:
		return "ranged_pressure"
	if float(metrics.get("max_speed", 0.0)) >= 1.25 or float(metrics.get("max_boost_speed", 0.0)) >= 1.4:
		return "mobile_pick"
	if int(metrics.get("max_damage", 0)) >= 16 and float(metrics.get("max_range", 0.0)) < 2.0:
		return "close_burst"
	return "general_validation"


func _add_observation(entries: Array, intent_key: String, metrics: Dictionary) -> void:
	match intent_key:
		"ranged_pressure":
			entries.append(_entry(
				KIND_OBSERVE,
				"intent:ranged_pressure",
				"设计倾向于用 %.1fm 射程和弹药节奏制造远程压制。" % float(metrics.get("max_range", 0.0)),
				"Design leans toward ranged pressure with %.1fm reach and ammunition tempo." % float(metrics.get("max_range", 0.0))
			))
		"close_burst":
			entries.append(_entry(
				KIND_OBSERVE,
				"intent:close_burst",
				"设计倾向于靠近后用高单次伤害打开缺口。",
				"Design leans toward closing distance and opening a gap with burst damage."
			))
		"mobile_pick":
			entries.append(_entry(
				KIND_OBSERVE,
				"intent:mobile_pick",
				"设计倾向于用速度、转向或 Boost 寻找侧翼机会。",
				"Design leans toward speed, turning, or boost windows to create flank picks."
			))
		"barrier_anchor":
			entries.append(_entry(
				KIND_OBSERVE,
				"intent:barrier_anchor",
				"设计倾向于用结界、陷阱或支援节点建立阵地。",
				"Design leans toward anchoring space with barriers, traps, or support nodes."
			))
		"summon_expand":
			entries.append(_entry(
				KIND_OBSERVE,
				"intent:summon_expand",
				"设计倾向于通过多个傀儡或分体单位扩大场面覆盖。",
				"Design leans toward expanding board coverage with multiple puppets or bodies."
			))
		_:
			entries.append(_entry(
				KIND_OBSERVE,
				"intent:general_validation",
				"当前设计意图还不够尖锐，训练时优先观察距离、动作、热量和命中反馈。",
				"Current intent is broad; prioritize observing range, actions, heat, and hit feedback."
			))


func _add_heat_rhythm_observation(entries: Array, metrics: Dictionary, runtime: Dictionary) -> void:
	var heat_peak_ratio := maxf(float(metrics.get("max_heat_ratio", 0.0)), float(runtime.get("heat_peak_ratio", 0.0)))
	var stage := heat_doctrine.rhythm_stage({"heat_ratio": heat_peak_ratio, "overheated": int(runtime.get("overheat_count", 0)) > 0})
	var labels_zh := {"stable": "稳定", "pressure": "升压", "decision": "决策", "vent": "排热", "overheat": "过热"}
	var labels_en := {"stable": "stable", "pressure": "pressure", "decision": "decision", "vent": "vent", "overheat": "overheat"}
	entries.append(_entry(
		KIND_OBSERVE,
		"heat:rhythm",
		"热量是战斗节奏的核心；当前热峰约 %.0f%%，处于“%s”阶段。它把输出切成爆发窗口，而不是无限连续攻击；继续进攻、撤退、停止行动或主动散热都可以，但应服务于构筑意图。" % [heat_peak_ratio * 100.0, String(labels_zh.get(stage, stage))],
		"Heat is the combat-tempo core; the current %.0f%% peak reaches the %s stage. It slices offense into burst windows rather than infinite continuous attacks; attack, disengage, stop, or active cooling are all valid when they serve the build intent." % [heat_peak_ratio * 100.0, String(labels_en.get(stage, stage))]
	))


func _add_static_risks(entries: Array, intent_key: String, metrics: Dictionary) -> void:
	var max_heat_ratio := float(metrics.get("max_heat_ratio", 0.0))
	if max_heat_ratio >= 1.15:
		entries.append(_entry(
			KIND_RISK,
			"heat:static_load",
			"构筑热负载已经超过热池约 %.0f%%，连续动作时容易提前进入过热压力。" % (max_heat_ratio * 100.0),
			"Build heat load reaches about %.0f%% of capacity, so repeated actions may enter overheat pressure early." % (max_heat_ratio * 100.0)
		))
	elif max_heat_ratio >= 0.82:
		entries.append(_entry(
			KIND_RISK,
			"heat:thin_margin",
			"热量余量偏薄；如果实战需要连续开火或冲刺，散热节奏会变成关键变量。",
			"Heat margin is thin; if the plan needs repeated firing or boosting, cooling tempo becomes a key variable."
		))
	var total_ammo := int(metrics.get("total_ammo", 0))
	if intent_key == "ranged_pressure" and total_ammo <= 4:
		entries.append(_entry(
			KIND_RISK,
			"ammo:low_pool",
			"远程压制意图下总弹药偏少，容易在第二轮接触前失去压制手段。",
			"Ammo pool is low for ranged pressure and may lose suppression before a second contact."
		))
	if intent_key == "ranged_pressure" and float(metrics.get("avg_speed", 0.0)) < 0.75:
		entries.append(_entry(
			KIND_RISK,
			"mobility:kite_gap",
			"射程够长但平均机动偏低；被迫换位时可能无法维持安全距离。",
			"Range is strong but average mobility is low; forced repositioning may break safe spacing."
		))


func _add_runtime_risks(entries: Array, runtime: Dictionary) -> void:
	var heat_peak_ratio := float(runtime.get("heat_peak_ratio", 0.0))
	var overheat_count := int(runtime.get("overheat_count", 0))
	if overheat_count > 0 or heat_peak_ratio >= 1.0:
		entries.append(_entry(
			KIND_RISK,
			"heat:overheat",
			"训练中热峰值达到 %.0f%%，并出现 %d 次过热；这说明爆发窗口需要冷却间隔。" % [heat_peak_ratio * 100.0, overheat_count],
			"Training heat peaked at %.0f%% with %d overheat event(s), so burst windows need cooling gaps." % [heat_peak_ratio * 100.0, overheat_count]
		))
	var ammo_spent := int(runtime.get("ammo_spent", 0))
	var ammo_remaining := int(runtime.get("ammo_remaining", -1))
	if ammo_spent > 0 and ammo_remaining == 0:
		entries.append(_entry(
			KIND_RISK,
			"ammo:endurance",
			"训练样本中弹药打空；如果目标是持续压制，需要更明确的换弹、节弹或近战收尾方案。",
			"Ammo emptied in the training sample; sustained pressure needs a clearer reload, conservation, or melee finish plan."
		))
	var shots := int(runtime.get("shots_fired", 0))
	var hits := int(runtime.get("hits", 0))
	if shots >= 2:
		var hit_ratio := float(hits) / maxf(1.0, float(shots))
		if hit_ratio <= 0.5:
			entries.append(_entry(
				KIND_RISK,
				"accuracy:stability",
				"训练命中率约 %.0f%%；移动、转向或弹道稳定性可能比面板伤害更限制输出。" % (hit_ratio * 100.0),
				"Training hit rate is about %.0f%%; movement, turning, or projectile stability may limit output more than listed damage." % (hit_ratio * 100.0)
			))
	if int(runtime.get("boost_count", 0)) == 0 and float(runtime.get("seconds", 0.0)) >= 8.0:
		entries.append(_entry(
			KIND_RISK,
			"mobility:unused_boost",
			"这段训练没有产生 Boost 行为；如果机体依赖机动窗口，需要确认按键、热量和驱动余量是否支持。",
			"No boost behavior appeared in this sample; if the unit relies on mobility windows, confirm input, heat, and drive margin."
		))


func _add_counter(entries: Array, intent_key: String, metrics: Dictionary) -> void:
	match intent_key:
		"ranged_pressure":
			entries.append(_entry(
				KIND_COUNTER,
				"counter:fast_flank",
				"高速侧翼、反射/盾面或干扰场会压缩远程窗口；测试时应让靶机移动或加入横向压力。",
				"Fast flankers, reflectors/shields, or jamming fields can shrink ranged windows; test with moving targets or lateral pressure."
			))
		"close_burst":
			entries.append(_entry(
				KIND_COUNTER,
				"counter:zone_control",
				"减速场、陷阱和保持距离的远程单位会拖慢接近过程，削弱爆发节奏。",
				"Slow fields, traps, and kiting ranged units can delay approach and weaken burst timing."
			))
		"mobile_pick":
			entries.append(_entry(
				KIND_COUNTER,
				"counter:wide_zone",
				"大范围结界、蛛丝或锁定弹幕会限制走位收益，需要验证脱离路线。",
				"Wide barriers, web effects, or lock-on barrage can limit movement value; validate escape routes."
			))
		"barrier_anchor":
			entries.append(_entry(
				KIND_COUNTER,
				"counter:long_artillery",
				"超远距离火力、爆炸半径和绕后单位会绕开固定阵地，需要检查覆盖盲区。",
				"Long artillery, blast radius, and backline divers can bypass fixed anchors; inspect coverage blind spots."
			))
		"summon_expand":
			entries.append(_entry(
				KIND_COUNTER,
				"counter:aoe_jam",
				"范围伤害、信号干扰和连锁控制会压缩多体铺场价值。",
				"Area damage, signal disruption, and chain control can compress multi-body expansion value."
			))
		_:
			entries.append(_entry(
				KIND_COUNTER,
				"counter:unknown_pressure",
				"当前意图较泛，建议至少分别测试高速、远程和控制型压力。",
				"Intent is broad; test at least fast, ranged, and control pressure styles."
			))


func _add_suggestions(entries: Array, intent_key: String, metrics: Dictionary, runtime: Dictionary) -> void:
	var added := false
	if float(runtime.get("heat_peak_ratio", 0.0)) >= 1.0 or float(metrics.get("max_heat_ratio", 0.0)) >= 0.82:
		entries.append(_entry(
			KIND_SUGGEST,
			"suggest:heat",
			"如果目标是持续输出，考虑降低单轮热负载、加入冷却间隔，或把爆发动作改成短窗口使用。",
			"If the goal is sustained output, consider lowering per-cycle heat, adding cooling gaps, or using burst actions in short windows."
		))
		added = true
	if int(runtime.get("ammo_remaining", -1)) == 0 or int(metrics.get("total_ammo", 0)) <= 4:
		entries.append(_entry(
			KIND_SUGGEST,
			"suggest:ammo",
			"如果目标是远程压制，考虑提高弹药池、减少无效射击，或准备弹尽后的近身/控场切换。",
			"If the goal is ranged pressure, consider more ammo, fewer low-value shots, or a melee/control transition after depletion."
		))
		added = true
	if float(metrics.get("runtime_hit_ratio", -1.0)) >= 0.0 and float(metrics.get("runtime_hit_ratio", 1.0)) < 0.5:
		entries.append(_entry(
			KIND_SUGGEST,
			"suggest:accuracy",
			"如果目标是稳定命中，考虑降低开火时转向压力、缩短有效距离，或搭配减速/控制模块。",
			"If the goal is stable hits, consider reducing turn pressure while firing, shortening effective range, or pairing slows/control modules."
		))
		added = true
	if intent_key == "ranged_pressure" and float(metrics.get("avg_speed", 0.0)) < 0.75:
		entries.append(_entry(
			KIND_SUGGEST,
			"suggest:mobility",
			"如果目标是风筝消耗，考虑增加基础速度、转向或一次可靠的脱身动作。",
			"If the goal is kiting attrition, consider more base speed, turning, or one reliable disengage action."
		))
		added = true
	if not added:
		entries.append(_entry(
			KIND_SUGGEST,
			"suggest:next_test",
			"如果目标已经清楚，下一轮训练可以切换靶机状态，分别记录命中率、过热次数和弹药剩余。",
			"If the goal is clear, switch dummy behavior next and record hit rate, overheat count, and remaining ammo separately."
		))


func _entry(kind: String, code: String, text_zh: String, text_en: String) -> Dictionary:
	return {
		"kind": kind,
		"code": code,
		"text_zh": text_zh,
		"text_en": text_en,
		"advisory_only": true,
	}


func _ammo_total(value) -> int:
	if value is Dictionary:
		var total := 0
		for raw_key in Dictionary(value).keys():
			total += maxi(0, int(Dictionary(value).get(raw_key, 0)))
		return total
	if value is Array:
		var array_total := 0
		for raw_value in Array(value):
			array_total += maxi(0, int(raw_value))
		return array_total
	return maxi(0, int(value))


func _intent_label(intent_key: String, language: String) -> String:
	var labels: Dictionary = Dictionary(INTENT_LABELS.get(intent_key, INTENT_LABELS.get("general_validation", {})))
	return String(labels.get("zh" if language == "zh" else "en", intent_key))
