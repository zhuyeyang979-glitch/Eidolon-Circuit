extends CanvasLayer
class_name StarSoulBPView

signal star_soul_selected(player: int, star_soul_id: String)
signal player_confirmed(player: int)
signal cancel_requested

const BG_COLOR := Color(0.025, 0.035, 0.055, 0.98)
const PANEL_COLOR := Color(0.055, 0.075, 0.105, 0.98)
const PANEL_BORDER := Color(0.22, 0.3, 0.4, 0.9)
const TEXT_COLOR := Color(0.9, 0.94, 0.98, 1.0)
const MUTED_COLOR := Color(0.56, 0.64, 0.73, 1.0)
const P1_COLOR := Color(0.26, 0.84, 0.98, 1.0)
const P2_COLOR := Color(1.0, 0.42, 0.32, 1.0)
const VP_COLOR := Color(1.0, 0.79, 0.24, 1.0)

var model := {}
var language := "zh"
var root_control: Control
var turn_label: Label
var progress_label: Label
var pool_grid: GridContainer
var p1_picks_label: Label
var p2_picks_label: Label
var confirm_buttons := {}


func _ready() -> void:
	layer = 70
	_build_view()
	visible = false


func set_model(next_model: Dictionary, next_language: String = "zh") -> void:
	if root_control == null:
		_build_view()
	model = next_model.duplicate(true)
	language = "zh" if next_language == "zh" else "en"
	_refresh()
	visible = true


func close() -> void:
	visible = false


func _build_view() -> void:
	if root_control != null:
		return
	root_control = Control.new()
	root_control.name = "StarSoulBPRoot"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)
	var background := ColorRect.new()
	background.color = BG_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 20)
	root_control.add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 58.0
	page.add_child(header)
	var title := Label.new()
	title.name = "Title"
	title.text = "星魂 BP" if language == "zh" else "STAR SOUL BP"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var cancel := Button.new()
	cancel.name = "Cancel"
	cancel.text = "返回" if language == "zh" else "BACK"
	cancel.custom_minimum_size = Vector2(96.0, 42.0)
	_style_command_button(cancel, MUTED_COLOR)
	cancel.pressed.connect(func() -> void: cancel_requested.emit())
	header.add_child(cancel)
	var status_band := VBoxContainer.new()
	status_band.add_theme_constant_override("separation", 2)
	page.add_child(status_band)
	turn_label = Label.new()
	turn_label.name = "TurnStatus"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.add_theme_font_size_override("font_size", 20)
	turn_label.add_theme_color_override("font_color", P1_COLOR)
	status_band.add_child(turn_label)
	progress_label = Label.new()
	progress_label.name = "DraftProgress"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", MUTED_COLOR)
	status_band.add_child(progress_label)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	page.add_child(body)
	var p1_panel := _build_player_panel(1)
	body.add_child(p1_panel)
	var pool_panel := VBoxContainer.new()
	pool_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool_panel.add_theme_constant_override("separation", 8)
	body.add_child(pool_panel)
	var pool_title := Label.new()
	pool_title.text = "公用星魂池" if language == "zh" else "SHARED STAR SOUL POOL"
	pool_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pool_title.add_theme_font_size_override("font_size", 17)
	pool_title.add_theme_color_override("font_color", TEXT_COLOR)
	pool_panel.add_child(pool_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pool_panel.add_child(scroll)
	pool_grid = GridContainer.new()
	pool_grid.name = "SharedPool"
	pool_grid.columns = 4
	pool_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool_grid.add_theme_constant_override("h_separation", 8)
	pool_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(pool_grid)
	var p2_panel := _build_player_panel(2)
	body.add_child(p2_panel)


func _build_player_panel(player: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 218.0
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_COLOR, P1_COLOR if player == 1 else P2_COLOR))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var heading := Label.new()
	heading.text = "P%d 阵容" % player if language == "zh" else "P%d PICKS" % player
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", P1_COLOR if player == 1 else P2_COLOR)
	column.add_child(heading)
	var picks := Label.new()
	picks.name = "P%dPicks" % player
	picks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	picks.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	picks.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picks.add_theme_font_size_override("font_size", 14)
	picks.add_theme_color_override("font_color", TEXT_COLOR)
	column.add_child(picks)
	if player == 1:
		p1_picks_label = picks
	else:
		p2_picks_label = picks
	var confirm := Button.new()
	confirm.name = "ConfirmP%d" % player
	confirm.text = "确认 P%d" % player if language == "zh" else "CONFIRM P%d" % player
	confirm.custom_minimum_size.y = 42.0
	_style_command_button(confirm, P1_COLOR if player == 1 else P2_COLOR)
	confirm.pressed.connect(func() -> void: player_confirmed.emit(player))
	column.add_child(confirm)
	confirm_buttons[player] = confirm
	return panel


func _refresh() -> void:
	if turn_label == null:
		return
	var current_turn: Dictionary = Dictionary(model.get("current_turn", {}))
	var current_player := int(current_turn.get("player", 0))
	var status := String(model.get("status", "drafting"))
	if status == "ready_to_confirm":
		turn_label.text = "选择完成，请双方确认" if language == "zh" else "DRAFT COMPLETE - BOTH PLAYERS CONFIRM"
		turn_label.add_theme_color_override("font_color", VP_COLOR)
	elif status == "complete":
		turn_label.text = "BP 完成" if language == "zh" else "BP COMPLETE"
		turn_label.add_theme_color_override("font_color", VP_COLOR)
	else:
		turn_label.text = "P%d 选择星魂" % current_player if language == "zh" else "P%d PICK A STAR SOUL" % current_player
		turn_label.add_theme_color_override("font_color", P1_COLOR if current_player == 1 else P2_COLOR)
	var picks: Array = Array(model.get("draft_picks", []))
	var turns: Array = Array(model.get("turns", []))
	progress_label.text = "%d / %d" % [picks.size(), turns.size()]
	_refresh_pool(current_player)
	_refresh_player_panel(1, p1_picks_label)
	_refresh_player_panel(2, p2_picks_label)


func _refresh_pool(current_player: int) -> void:
	for child in pool_grid.get_children():
		child.queue_free()
	for raw_entry in Array(model.get("shared_pool", [])):
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var id := String(entry.get("id", ""))
		var available := bool(entry.get("available", false))
		var button := Button.new()
		button.name = "Soul_%s" % id
		button.text = _entry_button_text(entry)
		button.tooltip_text = _entry_tooltip(entry)
		button.custom_minimum_size = Vector2(148.0, 68.0)
		button.disabled = not available or current_player == 0
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 13)
		_style_pool_button(button, P1_COLOR if current_player == 1 else P2_COLOR, available)
		button.pressed.connect(_on_pool_pressed.bind(current_player, id))
		pool_grid.add_child(button)


func _refresh_player_panel(player: int, label: Label) -> void:
	if label == null:
		return
	var picked_entries: Dictionary = Dictionary(model.get("picked_entries_by_player", {}))
	var entries: Array = Array(picked_entries.get(player, picked_entries.get(str(player), [])))
	var lines: Array[String] = []
	for index in range(entries.size()):
		var entry: Dictionary = Dictionary(entries[index])
		lines.append("%02d  %s  %dVP" % [index + 1, _entry_name(entry), int(entry.get("vp", 0))])
	label.text = "\n".join(lines) if not lines.is_empty() else ("尚未选择" if language == "zh" else "NO PICKS YET")
	var ready: Dictionary = Dictionary(model.get("confirm_ready_by_player", {}))
	var confirmed: Dictionary = Dictionary(model.get("confirmed_by_player", {}))
	var button: Button = confirm_buttons.get(player)
	button.disabled = not bool(ready.get(player, ready.get(str(player), false))) or bool(confirmed.get(player, confirmed.get(str(player), false)))
	if bool(confirmed.get(player, confirmed.get(str(player), false))):
		button.text = "P%d 已确认" % player if language == "zh" else "P%d CONFIRMED" % player
	else:
		button.text = "确认 P%d" % player if language == "zh" else "CONFIRM P%d" % player


func _on_pool_pressed(player: int, star_soul_id: String) -> void:
	if player not in [1, 2] or star_soul_id == "":
		return
	star_soul_selected.emit(player, star_soul_id)


func _entry_button_text(entry: Dictionary) -> String:
	return "%s\n%d VP · %ds" % [_entry_name(entry), int(entry.get("vp", 0)), int(entry.get("duration", 0))]


func _entry_tooltip(entry: Dictionary) -> String:
	return "%s | %s | %s" % [String(entry.get("behavior", "")), String(entry.get("spawn_relation", "")), String(entry.get("movement", ""))]


func _entry_name(entry: Dictionary) -> String:
	var family := String(entry.get("family", "star_soul"))
	var tier := String(entry.get("tier", ""))
	if language != "zh":
		return "%s %s" % [family.replace("_", " ").to_upper(), tier]
	var names := {
		"defense_tower": "防御塔",
		"punishment_tower": "惩戒塔",
		"cart": "小推车",
		"wandering_giant": "游荡巨人",
		"traitor": "内奸",
		"loyalist": "忠臣",
		"rebel": "反贼",
		"lord": "主公",
		"tyrant": "昏君",
		"coward": "胆小鬼",
	}
	return "%s%s" % [String(names.get(family, family)), tier]


func _style_pool_button(button: Button, accent: Color, available: bool) -> void:
	var border := accent if available else PANEL_BORDER
	button.add_theme_stylebox_override("normal", _panel_style(PANEL_COLOR, border))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.09, 0.13, 0.17, 1.0), accent))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.12, 0.17, 0.21, 1.0), VP_COLOR))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.035, 0.045, 0.06, 0.9), Color(0.13, 0.16, 0.2, 0.8)))
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", Color(0.32, 0.37, 0.43, 1.0))


func _style_command_button(button: Button, accent: Color) -> void:
	button.add_theme_stylebox_override("normal", _panel_style(PANEL_COLOR, accent))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.09, 0.13, 0.17, 1.0), accent.lightened(0.18)))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.12, 0.17, 0.21, 1.0), VP_COLOR))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.04, 0.05, 0.07, 0.9), PANEL_BORDER))
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", MUTED_COLOR.darkened(0.35))


func _panel_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8.0
	style.content_margin_top = 7.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 7.0
	return style
