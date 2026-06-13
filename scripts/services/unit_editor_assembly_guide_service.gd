extends RefCounted
class_name UnitEditorAssemblyGuideService

const IDENTITY_FILTER_BY_ROLE := {
	"hero": "soul",
	"puppet": "code",
	"barrier": "ether",
}

const IDENTITY_TITLE_ZH_BY_ROLE := {
	"hero": "英魂",
	"puppet": "源代码",
	"barrier": "以太",
}

const IDENTITY_TITLE_EN_BY_ROLE := {
	"hero": "SOUL",
	"puppet": "CODE",
	"barrier": "ETHER",
}

const BODY_STEPS := [
	{
		"key": "torso",
		"slot_key": "muscle",
		"part_group_mode": "torso",
		"part_filter_mode": "connector_torso",
		"zh_title": "躯干",
		"en_title": "TORSO",
		"zh_instruction": "先放躯干，确定端口、体量和承载空间。",
		"en_instruction": "Start with a torso to set ports, size, and capacity.",
	},
	{
		"key": "joint_muscle",
		"slot_key": "limb_muscle",
		"part_group_mode": "limb",
		"part_filter_mode": "connector_limb",
		"zh_title": "关节/肌肉",
		"en_title": "JOINT/MUSCLE",
		"zh_instruction": "再接关节/连接肌肉，让躯干拥有可驱动的肢体结构。",
		"en_instruction": "Add jointed connector muscles so the torso has driven limbs.",
	},
	{
		"key": "weapon",
		"slot_key": "muscle",
		"part_group_mode": "terminal_weapon",
		"part_filter_mode": "weapon_all",
		"weapon_filter_group": "all",
		"weapon_filter_subtype": "all",
		"zh_title": "武器",
		"en_title": "WEAPON",
		"zh_instruction": "选择末端武器，决定主要伤害类型和攻击距离。",
		"en_instruction": "Choose a terminal weapon to define damage type and reach.",
	},
	{
		"key": "connection",
		"slot_key": "",
		"part_group_mode": "",
		"part_filter_mode": "",
		"zh_title": "连接",
		"en_title": "CONNECT",
		"zh_instruction": "运行自动连接，检查拓扑，再用评估连接确认能进入入场姿态。",
		"en_instruction": "Run Auto Connect, inspect topology, then Evaluate Connection before entry pose.",
	},
	{
		"key": "engine",
		"slot_key": "engine",
		"part_group_mode": "software_muscle",
		"part_filter_mode": "engine",
		"zh_title": "引擎",
		"en_title": "ENGINE",
		"zh_instruction": "安装引擎，给推进、肢体和行动模块提供动力预算。",
		"en_instruction": "Install an engine to power movement, limbs, and actions.",
	},
	{
		"key": "cooling",
		"slot_key": "cooling",
		"part_group_mode": "software_muscle",
		"part_filter_mode": "cooling",
		"zh_title": "散热",
		"en_title": "COOLING",
		"zh_instruction": "加入散热器，给连招、开火和推进留下热量余地。",
		"en_instruction": "Add cooling so attacks, fire, and boosts can be sustained.",
	},
	{
		"key": "booster",
		"slot_key": "booster",
		"part_group_mode": "software_muscle",
		"part_filter_mode": "booster",
		"zh_title": "推进",
		"en_title": "BOOSTER",
		"zh_instruction": "需要机动时再加推进器；高推进会吃动力并增加热量。",
		"en_instruction": "Add boosters for mobility; strong boost costs drive and heat.",
	},
	{
		"key": "identity",
		"slot_key": "special",
		"part_group_mode": "software",
		"part_filter_mode": "soul",
		"zh_title": "英魂",
		"en_title": "SOUL",
		"zh_instruction": "放入身份核心，让单位符合当前身份的基本需求。",
		"en_instruction": "Install the role core so this unit satisfies its identity.",
	},
	{
		"key": "module",
		"slot_key": "module",
		"part_group_mode": "software",
		"part_filter_mode": "module",
		"zh_title": "行动模块",
		"en_title": "ACTION",
		"zh_instruction": "最后装行动模块并绑定目标；完成后可保存或进入训练测试。",
		"en_instruction": "Finish with an action module and target binding; then save or test.",
	},
]

const BARRIER_STEPS := [
	{
		"key": "barrier_panel",
		"slot_key": "muscle",
		"part_group_mode": "barrier_panel",
		"part_filter_mode": "barrier_muscle",
		"zh_title": "结界板",
		"en_title": "BARRIER",
		"zh_instruction": "先放结界板，确定固定空间和屏障覆盖。",
		"en_instruction": "Start with barrier panels to define space and coverage.",
	},
	{
		"key": "identity",
		"slot_key": "special",
		"part_group_mode": "software",
		"part_filter_mode": "ether",
		"zh_title": "以太",
		"en_title": "ETHER",
		"zh_instruction": "放入以太核心，让结界拥有身份与空间规则。",
		"en_instruction": "Install Ether so the barrier has identity and spatial rules.",
	},
	{
		"key": "engine",
		"slot_key": "engine",
		"part_group_mode": "software_muscle",
		"part_filter_mode": "engine",
		"zh_title": "引擎",
		"en_title": "ENGINE",
		"zh_instruction": "需要主动效果时补引擎，给结界模块留下动力预算。",
		"en_instruction": "Add engine power when active barrier modules need drive.",
	},
	{
		"key": "cooling",
		"slot_key": "cooling",
		"part_group_mode": "software_muscle",
		"part_filter_mode": "cooling",
		"zh_title": "散热",
		"en_title": "COOLING",
		"zh_instruction": "有持续效果或高热模块时补散热。",
		"en_instruction": "Add cooling for sustained effects or high-heat modules.",
	},
	{
		"key": "module",
		"slot_key": "module",
		"part_group_mode": "software",
		"part_filter_mode": "module",
		"zh_title": "行动模块",
		"en_title": "ACTION",
		"zh_instruction": "最后选择结界行动模块；完成后可保存或进入训练测试。",
		"en_instruction": "Finish with barrier action modules; then save or test.",
	},
]


func steps_for_role(role_key: String) -> Array:
	var source_steps := BARRIER_STEPS if role_key == "barrier" else BODY_STEPS
	var result: Array = []
	for raw_step in source_steps:
		var step: Dictionary = Dictionary(raw_step).duplicate(true)
		if String(step.get("key", "")) == "identity":
			step["part_filter_mode"] = _identity_filter_for_role(role_key)
			step["zh_title"] = String(IDENTITY_TITLE_ZH_BY_ROLE.get(role_key, IDENTITY_TITLE_ZH_BY_ROLE["hero"]))
			step["en_title"] = String(IDENTITY_TITLE_EN_BY_ROLE.get(role_key, IDENTITY_TITLE_EN_BY_ROLE["hero"]))
		result.append(step)
	return result


func step_count(role_key: String) -> int:
	return steps_for_role(role_key).size()


func clamp_step_index(role_key: String, step_index: int) -> int:
	var count := step_count(role_key)
	if count <= 0:
		return 0
	return clampi(step_index, 0, count - 1)


func next_step_index(role_key: String, step_index: int, delta: int) -> int:
	return clamp_step_index(role_key, step_index + delta)


func step_model(role_key: String, step_index: int, zh: bool) -> Dictionary:
	var steps := steps_for_role(role_key)
	if steps.is_empty():
		return {"valid": false, "index": 0, "step_count": 0}
	var index := clampi(step_index, 0, steps.size() - 1)
	var step: Dictionary = Dictionary(steps[index]).duplicate(true)
	var title := String(step.get("zh_title" if zh else "en_title", ""))
	var instruction := String(step.get("zh_instruction" if zh else "en_instruction", ""))
	var custom_note := "推荐路径只负责指路；仍可直接点下方分类自由组装。" if zh else "Recommended path only points; use the catalog freely in any order."
	step["valid"] = true
	step["index"] = index
	step["step_number"] = index + 1
	step["step_count"] = steps.size()
	step["title"] = title
	step["instruction"] = instruction
	step["short_label"] = ("%d/%d %s" if zh else "%d/%d %s") % [index + 1, steps.size(), title]
	step["tooltip_text"] = "%s\n%s" % [instruction, custom_note]
	step["custom_order_note"] = custom_note
	step["can_prev"] = index > 0
	step["can_next"] = index < steps.size() - 1
	return step


func catalog_state_for_step(role_key: String, step_index: int, build_slots: Array) -> Dictionary:
	var model := step_model(role_key, step_index, false)
	if not bool(model.get("valid", false)):
		return {"valid": false}
	if String(model.get("key", "")) == "connection":
		return {
			"valid": true,
			"action_key": "auto_connect",
			"part_group_mode": "",
			"part_filter_mode": "",
			"slot_index": -1,
		}
	var slot_key := String(model.get("slot_key", ""))
	var slot_index := build_slots.find(slot_key)
	if slot_index < 0:
		return {"valid": false, "reason": "missing_slot", "slot_key": slot_key}
	return {
		"valid": true,
		"slot_index": slot_index,
		"part_group_mode": String(model.get("part_group_mode", "")),
		"part_filter_mode": String(model.get("part_filter_mode", "")),
		"weapon_filter_group": String(model.get("weapon_filter_group", "all")),
		"weapon_filter_subtype": String(model.get("weapon_filter_subtype", "all")),
	}


func step_index_for_catalog_state(role_key: String, part_group_mode: String, part_filter_mode: String, fallback_index: int) -> int:
	var steps := steps_for_role(role_key)
	for i in range(steps.size()):
		var step: Dictionary = steps[i]
		if String(step.get("part_group_mode", "")) == part_group_mode and String(step.get("part_filter_mode", "")) == part_filter_mode:
			return i
		if String(step.get("key", "")) == "weapon" and part_group_mode == "terminal_weapon" and _filter_is_weapon_filter(part_filter_mode):
			return i
		if String(step.get("key", "")) == "module" and part_group_mode == "software" and part_filter_mode.begins_with("module"):
			return i
	return clamp_step_index(role_key, fallback_index)


func _identity_filter_for_role(role_key: String) -> String:
	return String(IDENTITY_FILTER_BY_ROLE.get(role_key, IDENTITY_FILTER_BY_ROLE["hero"]))


func _filter_is_weapon_filter(filter_key: String) -> bool:
	return (
		filter_key == "weapon_all"
		or filter_key.begins_with("weapon_")
		or filter_key.begins_with("gun_")
		or filter_key.begins_with("terminal")
	)
