extends RefCounted
class_name MenuController

const MAIN_MENU_SPECS := [
	{"key": "training_config", "zh": "开始训练", "en": "TRAINING", "description_zh": "先选择训练单位、席位和靶机状态，再进入训练场。", "description_en": "Choose training units, seat, and dummy behavior before entering the arena."},
	{"key": "saved_units", "zh": "已保存单位", "en": "SAVED UNITS", "description_zh": "查看已保存的单个单位，载入编辑，或单选/多选直接导入训练场。", "description_en": "Browse saved units, load one back into Unit Edit, compose teams, or send units into Training."},
	{"key": "unit_edit", "zh": "单位编辑", "en": "UNIT EDIT", "description_zh": "空白画布优先：编辑单个单位，保存后再编成队伍。", "description_en": "Blank-canvas first: edit one unit, save it, then compose teams."},
	{"key": "pvp", "zh": "本地双人", "en": "LOCAL VERSUS", "description_zh": "正式战斗优先设计对象：双控制器本地对战，P1/P2 各自操作。", "description_en": "Formal battle priority: local two-controller versus, with P1/P2 controlling their own sides."},
	{"key": "show_ai_seat_panel", "zh": "电脑对战", "en": "COMPUTER BATTLE", "description_zh": "选择电脑对战席位：P1 左侧、P2 右侧，或 P3 观战双方规则队伍。", "description_en": "Choose a Computer Battle seat: P1 left, P2 right, or P3 watching two rule-driven sides."},
	{"key": "settings", "zh": "设置", "en": "SETTINGS", "description_zh": "声音、画面、语言和战斗按键绑定。", "description_en": "Sound, video, language, and battle input bindings."},
	{"key": "quit", "zh": "退出", "en": "QUIT", "description_zh": "退出游戏。", "description_en": "Quit the game."},
]

const PAGE_OPTION_SPECS := [
	{"key": "back", "zh": "返回上级", "en": "BACK"},
	{"key": "main_menu", "zh": "主菜单", "en": "MAIN MENU"},
	{"key": "settings", "zh": "设置", "en": "SETTINGS"},
	{"key": "help", "zh": "帮助/说明", "en": "HELP"},
	{"key": "close", "zh": "关闭", "en": "CLOSE"},
]

const BATTLE_RUNTIME_OPTION_SPECS := [
	{"key": "continue", "zh": "继续", "en": "CONTINUE"},
	{"key": "post_review", "zh": "赛后复盘", "en": "POST REVIEW", "game_over_only": true},
	{"key": "reset_positions", "zh": "重置位置", "en": "RESET POS"},
	{"key": "reset_resources", "zh": "重置 HP/护盾/弹药", "en": "RESET HP/AMMO"},
	{"key": "dummy_state", "zh": "靶机：静止待机", "en": "DUMMY: IDLE", "training_only": true},
	{"key": "input", "zh": "输入设置", "en": "INPUTS"},
	{"key": "settings", "zh": "画面/声音", "en": "VIDEO/SOUND"},
	{"key": "training_config", "zh": "返回训练配置", "en": "TRAINING CFG", "training_only": true},
	{"key": "main_menu", "zh": "主菜单", "en": "MAIN MENU"},
]

const POST_BATTLE_REVIEW_SPECS := [
	{"key": "review", "zh": "留在战场复盘", "en": "REVIEW FIELD"},
	{"key": "adjust_sortie", "zh": "调整出战配置", "en": "ADJUST SORTIE"},
	{"key": "edit_units", "zh": "编辑单位构筑", "en": "UNIT EDIT"},
	{"key": "rematch", "zh": "立即再战", "en": "REMATCH"},
	{"key": "main_menu", "zh": "主菜单", "en": "MAIN MENU"},
]

const AI_SEAT_SPECS := [
	{"seat": 1, "zh": "P1 左侧", "en": "P1 LEFT", "description_zh": "操控玩家 1", "description_en": "Control player 1"},
	{"seat": 2, "zh": "P2 右侧", "en": "P2 RIGHT", "description_zh": "操控玩家 2", "description_en": "Control player 2"},
	{"seat": 3, "zh": "P3 观战", "en": "P3 WATCH", "description_zh": "自由镜头", "description_en": "Spectator camera"},
]

var main_ref: Object
var state_store
var dirty_graph
var cache
var profiler
var selected_index := 0


func bind(main: Object, store, graph, derived_cache, hot_profiler) -> void:
	main_ref = main
	state_store = store
	dirty_graph = graph
	cache = derived_cache
	profiler = hot_profiler
	selected_index = int(main_ref.get("menu_index")) if main_ref != null else 0


func mark_dirty(reason: String = "menu") -> void:
	if state_store != null:
		state_store.mark_dirty("menu", 1, reason)
	if dirty_graph != null:
		dirty_graph.mark("menu", 1, reason)


func menu_count() -> int:
	return MAIN_MENU_SPECS.size()


func select_index(index: int) -> int:
	selected_index = wrapi(index, 0, maxi(1, menu_count()))
	if main_ref != null:
		main_ref.set("menu_index", selected_index)
	mark_dirty("menu_select")
	return selected_index


func move_selection(delta: int) -> int:
	return select_index(selected_index + delta)


func main_menu_action(index: int) -> Dictionary:
	select_index(index)
	var spec: Dictionary = MAIN_MENU_SPECS[selected_index]
	return {"action": String(spec.get("key", "")), "index": selected_index}


func page_option_action(action_key: String, route_action: Dictionary) -> Dictionary:
	var result := route_action.duplicate(true)
	result["source"] = "page_options"
	result["key"] = action_key
	return result


func battle_runtime_action(action_key: String) -> Dictionary:
	match action_key:
		"post_review":
			return {"action": "post_review", "key": action_key}
		"reset_positions", "reset_resources":
			return {"action": "battle_reset", "key": action_key}
		"dummy_state":
			return {"action": "cycle_dummy_state", "key": action_key}
		"input":
			return {"action": "settings_input", "key": action_key}
		"settings":
			return {"action": "settings", "key": action_key}
		"training_config":
			return {"action": "training_config", "key": action_key}
		"main_menu":
			return {"action": "main_menu", "key": action_key}
	return {"action": action_key, "key": action_key}


func post_battle_review_action(action_key: String) -> Dictionary:
	match action_key:
		"review":
			return {"action": "review", "key": action_key}
		"adjust_sortie":
			return {"action": "adjust_sortie", "key": action_key}
		"edit_units":
			return {"action": "edit_units", "key": action_key}
		"rematch":
			return {"action": "rematch", "key": action_key}
		"main_menu":
			return {"action": "main_menu", "key": action_key}
	return {"action": action_key, "key": action_key}


func main_menu_model(language: String, ai_battle_seat: int, match_format_short: String, team_status: String = "") -> Dictionary:
	var zh := language == "zh"
	var selected_key := String(MAIN_MENU_SPECS[selected_index].get("key", "")) if MAIN_MENU_SPECS.size() > 0 else ""
	return {
		"items": _localized_specs(MAIN_MENU_SPECS, zh, true),
		"selected_index": selected_index,
		"ai_seats": _localized_specs(AI_SEAT_SPECS, zh, true),
		"ai_seat_visible": selected_key == "show_ai_seat_panel",
		"ai_battle_seat": ai_battle_seat,
		"match_format_short": match_format_short,
		"team_status": team_status,
		"title": "EIDOLON CIRCUIT" if not zh else "星魂回环",
		"subtitle": "Mobius Arsenal" if not zh else "莫比乌斯兵装",
		"callsign": "拓扑机甲 / 资源召唤" if zh else "topology mechs / resource summons",
		"telemetry": ("实验室就绪 / %s / 首发200" if zh else "LAB READY / %s / START 200") % match_format_short,
		"help": "鼠标点击菜单；Enter 仅提交数值，Esc 仅关闭详情。" if zh else "Click menus; Enter only submits numeric values, Esc only closes details.",
		"ai_seat_title": "电脑对战席位" if zh else "COMPUTER BATTLE SEAT",
		"ai_seat_hint": "点击下方 P1/P2/P3 进入电脑对战。" if zh else "Click P1/P2/P3 below to enter Computer Battle.",
	}


func page_options_model(language: String) -> Dictionary:
	var zh := language == "zh"
	return {
		"title": "选项" if zh else "OPTIONS",
		"items": _localized_specs(PAGE_OPTION_SPECS, zh, false),
	}


func battle_runtime_model(language: String, battle_mode: String, training_mode: String, dummy_state: String, game_over: bool = false) -> Dictionary:
	var zh := language == "zh"
	var is_training := battle_mode == training_mode
	var items := _localized_specs(BATTLE_RUNTIME_OPTION_SPECS, zh, false)
	for i in range(items.size()):
		var item: Dictionary = items[i]
		if String(item.get("key", "")) == "dummy_state":
			var state_label: String = String({
				"idle_brake": "静止待机",
				"free_physics": "自由物理",
				"fixed": "固定位置",
				"sparring": "电脑陪练",
			}.get(dummy_state, dummy_state))
			var state_label_en: String = String({
				"idle_brake": "IDLE",
				"free_physics": "FREE",
				"fixed": "FIXED",
				"sparring": "SPARRING",
			}.get(dummy_state, dummy_state.to_upper()))
			item["label"] = ("靶机：%s" % state_label) if zh else ("DUMMY: %s" % state_label_en)
		if bool(item.get("training_only", false)):
			item["disabled"] = not is_training
		if bool(item.get("game_over_only", false)):
			item["disabled"] = not game_over
		items[i] = item
	return {
		"title": ("训练选项" if zh else "TRAINING OPTIONS") if is_training else ("战斗选项" if zh else "BATTLE OPTIONS"),
		"items": items,
	}


func post_battle_review_model(language: String, winner_id: int, victory_points: Dictionary, match_time_remaining: float, battle_mode: String, command_log_text: String = "") -> Dictionary:
	var zh := language == "zh"
	var p1_points := int(victory_points.get(1, 0))
	var p2_points := int(victory_points.get(2, 0))
	var minutes := int(floorf(maxf(0.0, match_time_remaining) / 60.0))
	var seconds := int(floorf(fmod(maxf(0.0, match_time_remaining), 60.0)))
	var mode_label := String({
		"training": "训练" if zh else "TRAINING",
		"ai": "电脑对战" if zh else "COMPUTER BATTLE",
		"pvp": "本地双人" if zh else "LOCAL VERSUS",
	}.get(battle_mode, battle_mode.to_upper()))
	return {
		"title": "战斗复盘" if zh else "POST-BATTLE REVIEW",
		"summary": ("P%d 胜利  |  VP %d:%d  |  剩余 %02d:%02d  |  %s" if zh else "P%d wins  |  VP %d:%d  |  %02d:%02d left  |  %s") % [winner_id, p1_points, p2_points, minutes, seconds, mode_label],
		"hint": "复盘和改构筑是玩家自主选择：可以先留在战场观察，也可以回到出战配置或单位编辑后再战。" if zh else "Review and build changes are player-chosen: inspect the frozen field, adjust sortie, edit units, or rematch.",
		"command_log": command_log_text,
		"items": _localized_specs(POST_BATTLE_REVIEW_SPECS, zh, false),
	}


func _localized_specs(specs: Array, zh: bool, include_description: bool) -> Array:
	var items: Array = []
	for raw in specs:
		var spec: Dictionary = raw
		var item := spec.duplicate(true)
		item["label"] = String(spec.get("zh" if zh else "en", spec.get("key", "")))
		if include_description:
			item["description"] = String(spec.get("description_zh" if zh else "description_en", ""))
		items.append(item)
	return items
