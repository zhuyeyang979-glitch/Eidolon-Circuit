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
		"core_concept": "heat",
		"slot_key": "cooling",
		"part_group_mode": "software_muscle",
		"part_filter_mode": "cooling",
		"zh_title": "热量/散热",
		"en_title": "HEAT/COOLING",
		"zh_instruction": "热量是战斗节奏的核心；加入散热器，并为进攻、撤退、停止行动和主动散热预留窗口。",
		"en_instruction": "Heat is the combat-tempo core; add cooling and plan attack, disengage, stop, and active-cooling windows.",
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
		"zh_instruction": "最后装行动模块并绑定目标；完成后检查热节奏，再保存或进入训练测试。",
		"en_instruction": "Finish with an action module and target binding; review heat rhythm, then save or test.",
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
		"core_concept": "heat",
		"slot_key": "cooling",
		"part_group_mode": "software_muscle",
		"part_filter_mode": "cooling",
		"zh_title": "热量/散热",
		"en_title": "HEAT/COOLING",
		"zh_instruction": "热量是持续效果的节奏核心；为高热模块补散热并规划停止或主动散热窗口。",
		"en_instruction": "Heat is the tempo core for sustained effects; add cooling and plan stop or active-cooling windows.",
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

const TUTORIAL_ZH_BY_KEY := {
	"torso": {
		"function": "躯干是英雄的承载核心，决定接口数量、体量、机内插件槽和软件槽。",
		"limit": "接口数量限制可连接肢体；插件/软件槽限制引擎、散热、推进器、弹药和行动模块容量。",
		"next": "点“前往”筛选躯干，把一个躯干核心拖到画布，作为第一次组装的根节点。",
	},
	"joint_muscle": {
		"function": "关节/连接肌肉把躯干延伸成可驱动的肢体，是武器和动作的力臂。",
		"limit": "连接件要和接口贴合；长度、材料和承载会影响后续武器、动力分配和连接合法性。",
		"next": "选择一段基础肢体连接件，拖到躯干附近，之后用自动连接或手动接口把它接上。",
	},
	"weapon": {
		"function": "武器决定主要伤害方式：近战靠接触姿态，枪械靠弹药、射程和行动模块触发。",
		"limit": "多数末端武器只有一个接口；侧挂刃需要选择左右方向，枪械还要匹配弹药和动作模块。",
		"next": "选择一种新手易读的末端武器，放在肢体末端，先保证结构清楚再追求复杂组合。",
	},
	"connection": {
		"function": "连接阶段把零件变成真正的拓扑结构，系统会检查接口贴合、材料组和可进入姿态条件。",
		"limit": "未贴合、接口占用或材料非法时不能安全进入下一阶段；连接变动后需要重新评估。",
		"next": "先点“自动连接”，再点“评估连接”；通过后才能继续到引擎与动力配置。",
	},
	"engine": {
		"function": "引擎提供动力预算，驱动移动、推进器、绑定肢体和部分行动模块。",
		"limit": "动力输出必须覆盖需求；过强引擎会增加热压力，过弱会让动作或推进不足。",
		"next": "安装一个均衡引擎，观察构筑仪表中的动力预算是否还有余量。",
	},
	"cooling": {
		"function": "散热决定英雄能持续进攻多久，是攻击、撤退、停手和主动散热节奏的核心。",
		"limit": "散热不足会让高热行动难以连续使用；专项散热只对匹配热源最有效。",
		"next": "安装散热器，确认热管理没有明显短板，再进入推进配置。",
	},
	"booster": {
		"function": "推进器提供移动和 Boost，让英雄接近、脱离或调整攻击角度。",
		"limit": "推进会占用动力并产生热；高机动不等于更强，必须和武器距离、热节奏配合。",
		"next": "选择一个基础推进器，优先保证可控移动，再考虑高速爆发。",
	},
	"identity": {
		"function": "身份核心让单位符合英雄/傀儡/结界的基本身份规则，也会改变队伍和行为定位。",
		"limit": "英雄需要英魂，傀儡需要源代码，结界需要以太；身份核心不占战斗体积但受槽位限制。",
		"next": "为当前角色装入对应身份核心，然后进入行动模块配置。",
	},
	"module": {
		"function": "行动模块把输入变成攻击、投射、冷却或特殊动作，是玩家实际操作英雄的按钮逻辑。",
		"limit": "模块需要合法目标、键位和软件槽；绑定肢体会消耗动力，并可能改变热节奏。",
		"next": "安装一个简单行动模块，选择目标与攻击键，最后保存单位或进入训练测试。",
	},
	"barrier_panel": {
		"function": "结界板决定固定空间、屏障覆盖和以太构件的基础形状。",
		"limit": "结界格数量和材料槽有限；部分构件只能放在屏幕格或自由画布的合法位置。",
		"next": "先放一个清晰的结界板，再补身份核心和主动模块。",
	},
}

const TUTORIAL_EN_BY_KEY := {
	"torso": {
		"function": "The torso is the hero's core: ports, size, internal payload slots, and software slots.",
		"limit": "Ports limit limb count; payload and software slots limit engines, cooling, boosters, ammo, and actions.",
		"next": "Press GO to filter torsos, then drag one torso core onto the board as the root node.",
	},
	"joint_muscle": {
		"function": "Joint/connector muscle extends the torso into driven limbs for weapons and actions.",
		"limit": "Connectors must align to sockets; length, material, and load affect legal links and drive.",
		"next": "Drag one beginner connector near the torso, then link it manually or with Auto Connect.",
	},
	"weapon": {
		"function": "Weapons define damage: melee uses contact pose, guns use ammo, range, and action modules.",
		"limit": "Most terminal weapons have one socket; side blades need left/right choice, guns need ammo and actions.",
		"next": "Choose a readable terminal weapon and place it at the limb end before making complex combos.",
	},
	"connection": {
		"function": "Connection turns loose parts into topology and checks socket fit, material groups, and entry-pose readiness.",
		"limit": "Misfit sockets, occupied ports, or illegal material links block safe progress; edits require re-evaluation.",
		"next": "Use Auto Connect, then Evaluate Connection. Passing unlocks engine and drive setup.",
	},
	"engine": {
		"function": "Engines provide drive budget for movement, boosters, bound limbs, and some action modules.",
		"limit": "Output must cover demand; stronger engines add heat pressure, weaker engines starve actions.",
		"next": "Install a balanced engine and check the build meter for remaining drive margin.",
	},
	"cooling": {
		"function": "Cooling sets combat tempo: attack, disengage, stop, and active-cooling windows.",
		"limit": "Poor cooling blocks repeated hot actions; specialized cooling mainly helps matching heat sources.",
		"next": "Install cooling, confirm heat has no obvious shortage, then configure boosters.",
	},
	"booster": {
		"function": "Boosters provide movement and burst repositioning for approach, escape, and attack angles.",
		"limit": "Boost costs drive and heat; mobility must match weapon range and heat tempo.",
		"next": "Pick a basic booster for controlled movement before chasing high-speed bursts.",
	},
	"identity": {
		"function": "Identity cores satisfy hero/puppet/barrier rules and shape team and behavior roles.",
		"limit": "Heroes need Soul, puppets need Code, barriers need Ether; identity has no battle volume but uses slots.",
		"next": "Install the matching identity core, then move to action modules.",
	},
	"module": {
		"function": "Action modules turn player input into attacks, shots, cooling, or special moves.",
		"limit": "Modules need legal targets, keys, and software slots; bound limbs consume drive and can change heat tempo.",
		"next": "Install one simple action, choose its target and key, then save or enter Training.",
	},
	"barrier_panel": {
		"function": "Barrier panels define fixed space, coverage, and the base shape for Ether parts.",
		"limit": "Barrier cells and material slots are limited; some parts only fit screen cells or valid board positions.",
		"next": "Place one clear barrier panel, then add identity and active modules.",
	},
}


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
	var tutorial_copy := _tutorial_copy_for_step(step, zh)
	var function_text := String(tutorial_copy.get("function", instruction))
	var limit_text := String(tutorial_copy.get("limit", custom_note))
	var next_action_text := String(tutorial_copy.get("next", instruction))
	step["valid"] = true
	step["index"] = index
	step["step_number"] = index + 1
	step["step_count"] = steps.size()
	step["title"] = title
	step["instruction"] = instruction
	step["short_label"] = ("%d/%d %s" if zh else "%d/%d %s") % [index + 1, steps.size(), title]
	step["tooltip_text"] = "%s\n%s" % [instruction, custom_note]
	step["custom_order_note"] = custom_note
	step["function_text"] = function_text
	step["limit_text"] = limit_text
	step["next_action_text"] = next_action_text
	step["tutorial_text"] = ("作用：%s\n限制：%s\n下一步：%s" if zh else "Function: %s\nLimit: %s\nNext: %s") % [function_text, limit_text, next_action_text]
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


func _tutorial_copy_for_step(step: Dictionary, zh: bool) -> Dictionary:
	var key := String(step.get("key", ""))
	var source := TUTORIAL_ZH_BY_KEY if zh else TUTORIAL_EN_BY_KEY
	if source.has(key):
		return Dictionary(source[key])
	return {}
