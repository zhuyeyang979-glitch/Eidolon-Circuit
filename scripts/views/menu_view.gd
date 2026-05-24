extends RefCounted
class_name MenuView

signal main_menu_hovered(index: int)
signal main_menu_pressed(index: int)
signal main_menu_gui_input(event: InputEvent, index: int)
signal ai_seat_pressed(seat: int)
signal page_option_pressed(action_key: String)
signal battle_runtime_pressed(action_key: String)

const MenuControllerModel = preload("res://scripts/controllers/menu_controller.gd")
const UILayoutTokens = preload("res://scripts/ui_layout_tokens.gd")

var main_ref: Object
var menu_layer: CanvasLayer
var menu_backdrop: Control
var menu_description_label: Label
var menu_status_label: Label
var menu_ai_seat_panel: ColorRect
var menu_ai_seat_label: Label
var menu_buttons: Array = []
var menu_ai_seat_buttons: Array = []
var page_options_layer: CanvasLayer
var page_options_panel: Control
var page_options_buttons := {}
var page_options_context := ""
var battle_runtime_menu_panel: Control
var battle_runtime_menu_buttons := {}


func bind(main: Object) -> void:
	main_ref = main


func build_main_menu(parent: Node, background_texture: Texture2D, backdrop_script) -> CanvasLayer:
	menu_layer = CanvasLayer.new()
	parent.add_child(menu_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(root)
	menu_backdrop = backdrop_script.new()
	menu_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_backdrop.set_mode("menu")
	menu_backdrop.set_background_texture(background_texture)
	root.add_child(menu_backdrop)
	_add_rect(root, "MenuHeaderBand", UILayoutTokens.main_menu_header_rect(), Color(0.012, 0.022, 0.032, 0.72))
	_add_label(root, "GameTitle", "", UILayoutTokens.main_menu_title_rect(), 40, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(root, "Subtitle", "", UILayoutTokens.main_menu_subtitle_rect(), 18, Color(0.26, 0.88, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	_add_rect(root, "Accent", UILayoutTokens.main_menu_accent_rect(), Color(1.0, 0.88, 0.22, 1.0))
	_add_label(root, "MenuCallsign", "", UILayoutTokens.main_menu_callsign_rect(), 15, Color(1.0, 0.86, 0.38, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	_add_rect(root, "MenuListPanel", UILayoutTokens.main_menu_list_panel_rect(), Color(0.01, 0.018, 0.026, 0.72))
	_add_rect(root, "MenuInfoPanel", UILayoutTokens.main_menu_info_panel_rect(), Color(0.014, 0.024, 0.034, 0.82))
	menu_description_label = _add_label(root, "MenuDescription", "", UILayoutTokens.main_menu_description_rect(), 23, Color(0.9, 0.94, 0.98, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	menu_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_status_label = _add_label(root, "MenuStatus", "", UILayoutTokens.main_menu_status_rect(), 14, Color(0.32, 0.94, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	menu_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_label(root, "MenuTelemetry", "", UILayoutTokens.main_menu_telemetry_rect(), 16, Color(1.0, 0.88, 0.32, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(root, "MenuHelp", "", UILayoutTokens.main_menu_help_rect(), 17, Color(0.78, 0.84, 0.9, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	for i in range(MenuControllerModel.MAIN_MENU_SPECS.size()):
		var button := Button.new()
		_apply_rect(button, UILayoutTokens.main_menu_button_rect(i))
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.mouse_entered.connect(_emit_main_menu_hovered.bind(i))
		button.pressed.connect(_emit_main_menu_pressed.bind(i))
		button.gui_input.connect(_emit_main_menu_gui_input.bind(i))
		root.add_child(button)
		menu_buttons.append(button)
	menu_ai_seat_panel = _add_rect(root, "MenuAISeatPanel", UILayoutTokens.main_menu_ai_seat_panel_rect(), Color(0.012, 0.028, 0.038, 0.86))
	menu_ai_seat_label = _add_label(root, "MenuAISeatLabel", "", UILayoutTokens.main_menu_ai_seat_label_rect(), 16, Color(1.0, 0.88, 0.32, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	for i in range(MenuControllerModel.AI_SEAT_SPECS.size()):
		var spec: Dictionary = MenuControllerModel.AI_SEAT_SPECS[i]
		var seat_button := Button.new()
		_apply_rect(seat_button, UILayoutTokens.main_menu_ai_seat_button_rect(i))
		seat_button.focus_mode = Control.FOCUS_NONE
		seat_button.mouse_filter = Control.MOUSE_FILTER_STOP
		seat_button.pressed.connect(_emit_ai_seat_pressed.bind(int(spec.get("seat", i + 1))))
		root.add_child(seat_button)
		menu_ai_seat_buttons.append(seat_button)
	return menu_layer


func update_main_menu(model: Dictionary) -> void:
	var items: Array = model.get("items", [])
	var selected := int(model.get("selected_index", 0))
	_set_named_label(menu_layer, "GameTitle", String(model.get("title", "")))
	_set_named_label(menu_layer, "Subtitle", String(model.get("subtitle", "")))
	_set_named_label(menu_layer, "MenuCallsign", String(model.get("callsign", "")))
	_set_named_label(menu_layer, "MenuTelemetry", String(model.get("telemetry", "")))
	_set_named_label(menu_layer, "MenuHelp", String(model.get("help", "")))
	_set_named_label(menu_layer, "MenuAISeatLabel", String(model.get("ai_seat_title", "")))
	for i in range(menu_buttons.size()):
		var item: Dictionary = items[i] if i < items.size() and items[i] is Dictionary else {}
		var button: Button = menu_buttons[i]
		button.text = "%s%02d  %s" % ["> " if i == selected else "  ", i + 1, String(item.get("label", ""))]
		button.modulate = Color(0.35, 0.95, 1.0, 1.0) if i == selected else Color(0.86, 0.9, 0.94, 1.0)
	var desc := ""
	if selected >= 0 and selected < items.size() and items[selected] is Dictionary:
		desc = String(Dictionary(items[selected]).get("description", ""))
	if bool(model.get("ai_seat_visible", false)):
		desc = "%s\n\n%s" % [desc, String(model.get("ai_seat_hint", ""))]
	menu_description_label.text = desc
	if menu_status_label != null:
		menu_status_label.text = String(model.get("team_status", ""))
	var ai_visible := bool(model.get("ai_seat_visible", false))
	if menu_ai_seat_panel != null:
		menu_ai_seat_panel.visible = ai_visible
	if menu_ai_seat_label != null:
		menu_ai_seat_label.visible = ai_visible
	var seats: Array = model.get("ai_seats", [])
	var active_seat := int(model.get("ai_battle_seat", 1))
	for i in range(menu_ai_seat_buttons.size()):
		var seat_button: Button = menu_ai_seat_buttons[i]
		var seat: Dictionary = seats[i] if i < seats.size() and seats[i] is Dictionary else {}
		seat_button.text = "%s\n%s" % [String(seat.get("label", "")), String(seat.get("description", ""))]
		seat_button.visible = ai_visible
		seat_button.disabled = not ai_visible
		var seat_index := int(seat.get("seat", i + 1))
		seat_button.modulate = Color(0.35, 0.95, 1.0, 1.0) if ai_visible and active_seat == seat_index else Color(0.86, 0.9, 0.94, 1.0)


func build_page_options(parent: Node) -> CanvasLayer:
	page_options_layer = CanvasLayer.new()
	page_options_layer.name = "PageOptionsLayer"
	page_options_layer.layer = 90
	page_options_layer.visible = false
	parent.add_child(page_options_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_options_layer.add_child(root)
	page_options_panel = Control.new()
	page_options_panel.name = "PageOptionsPanel"
	_apply_rect(page_options_panel, UILayoutTokens.page_options_rect())
	page_options_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(page_options_panel)
	_add_rect(page_options_panel, "PageOptionsBack", UILayoutTokens.local_rect(UILayoutTokens.page_options_rect().size), Color(0.01, 0.018, 0.026, 0.94))
	_add_rect(page_options_panel, "PageOptionsAccent", UILayoutTokens.page_options_accent_rect(), Color(0.24, 0.9, 1.0, 0.85))
	_add_label(page_options_panel, "PageOptionsTitle", "", UILayoutTokens.page_options_title_rect(), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(MenuControllerModel.PAGE_OPTION_SPECS.size()):
		var spec: Dictionary = MenuControllerModel.PAGE_OPTION_SPECS[i]
		var key := String(spec.get("key", ""))
		var button := Button.new()
		button.name = "PageOptions%s" % key
		_apply_local_rect(button, UILayoutTokens.page_options_button_rect(i))
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_emit_page_option_pressed.bind(key))
		page_options_panel.add_child(button)
		page_options_buttons[key] = button
	return page_options_layer


func show_page_options(context: String) -> void:
	page_options_context = context
	if page_options_layer != null:
		page_options_layer.visible = true


func hide_page_options() -> void:
	if page_options_layer != null:
		page_options_layer.visible = false
	page_options_context = ""


func update_page_options(model: Dictionary) -> void:
	if page_options_layer == null or page_options_panel == null:
		return
	_set_named_label(page_options_panel, "PageOptionsTitle", String(model.get("title", "")))
	var items: Array = model.get("items", [])
	for raw_item in items:
		if not (raw_item is Dictionary):
			continue
		var item: Dictionary = raw_item
		var key := String(item.get("key", ""))
		var button: Button = page_options_buttons.get(key, null)
		if button == null:
			continue
		button.text = String(item.get("label", ""))
		button.disabled = bool(item.get("disabled", false))


func build_battle_runtime_menu(root: Control) -> Control:
	battle_runtime_menu_panel = Control.new()
	battle_runtime_menu_panel.name = "BattleRuntimeOptions"
	_apply_rect(battle_runtime_menu_panel, UILayoutTokens.battle_runtime_options_rect())
	battle_runtime_menu_panel.visible = false
	root.add_child(battle_runtime_menu_panel)
	_add_rect(battle_runtime_menu_panel, "BattleRuntimeOptionsBack", UILayoutTokens.local_rect(UILayoutTokens.battle_runtime_options_rect().size), Color(0.01, 0.018, 0.026, 0.9))
	_add_label(battle_runtime_menu_panel, "BattleRuntimeOptionsTitle", "", UILayoutTokens.battle_runtime_title_rect(), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(MenuControllerModel.BATTLE_RUNTIME_OPTION_SPECS.size()):
		var spec: Dictionary = MenuControllerModel.BATTLE_RUNTIME_OPTION_SPECS[i]
		var key := String(spec.get("key", ""))
		var button := Button.new()
		button.name = "BattleRuntimeOption%s" % key
		_apply_local_rect(button, UILayoutTokens.battle_runtime_button_rect(i))
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_emit_battle_runtime_pressed.bind(key))
		battle_runtime_menu_panel.add_child(button)
		battle_runtime_menu_buttons[key] = button
	return battle_runtime_menu_panel


func toggle_battle_runtime() -> bool:
	if battle_runtime_menu_panel == null:
		return false
	battle_runtime_menu_panel.visible = not battle_runtime_menu_panel.visible
	return battle_runtime_menu_panel.visible


func hide_battle_runtime() -> void:
	if battle_runtime_menu_panel != null:
		battle_runtime_menu_panel.visible = false


func update_battle_runtime(model: Dictionary) -> void:
	if battle_runtime_menu_panel == null:
		return
	_set_named_label(battle_runtime_menu_panel, "BattleRuntimeOptionsTitle", String(model.get("title", "")))
	var items: Array = model.get("items", [])
	for raw_item in items:
		if not (raw_item is Dictionary):
			continue
		var item: Dictionary = raw_item
		var key := String(item.get("key", ""))
		var button: Button = battle_runtime_menu_buttons.get(key, null)
		if button == null:
			continue
		button.text = String(item.get("label", ""))
		button.disabled = bool(item.get("disabled", false))


func _add_rect(parent: Node, node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = node_name
	_apply_parent_rect(color_rect, rect, parent)
	color_rect.color = color
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(color_rect)
	return color_rect


func _add_label(parent: Node, node_name: String, text: String, rect: Rect2, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	_apply_parent_rect(label, rect, parent)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.76))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _apply_rect(control: Control, rect: Rect2) -> void:
	var screen_rect := _screen_rect(rect)
	control.position = screen_rect.position
	control.size = screen_rect.size


func _apply_local_rect(control: Control, rect: Rect2) -> void:
	var viewport_size := UILayoutTokens.DESIGN_SIZE
	if main_ref != null and main_ref.has_method("_ui_viewport_size"):
		viewport_size = main_ref._ui_viewport_size()
	var local_rect := UILayoutTokens.to_local_rect(rect, viewport_size)
	control.position = local_rect.position
	control.size = local_rect.size


func _apply_parent_rect(control: Control, rect: Rect2, parent: Node) -> void:
	if parent == page_options_panel or parent == battle_runtime_menu_panel:
		_apply_local_rect(control, rect)
	else:
		_apply_rect(control, rect)


func _set_named_label(root: Node, target_name: String, value: String) -> void:
	if root == null:
		return
	var found := root.find_child(target_name, true, false)
	if found is Label:
		(found as Label).text = value


func _screen_rect(rect: Rect2) -> Rect2:
	var viewport_size := UILayoutTokens.DESIGN_SIZE
	if main_ref != null and main_ref.has_method("_ui_viewport_size"):
		viewport_size = main_ref._ui_viewport_size()
	return UILayoutTokens.to_screen_rect(rect, viewport_size)


func _emit_main_menu_hovered(index: int) -> void:
	main_menu_hovered.emit(index)


func _emit_main_menu_pressed(index: int) -> void:
	main_menu_pressed.emit(index)


func _emit_main_menu_gui_input(event: InputEvent, index: int) -> void:
	main_menu_gui_input.emit(event, index)


func _emit_ai_seat_pressed(seat: int) -> void:
	ai_seat_pressed.emit(seat)


func _emit_page_option_pressed(action_key: String) -> void:
	page_option_pressed.emit(action_key)


func _emit_battle_runtime_pressed(action_key: String) -> void:
	battle_runtime_pressed.emit(action_key)
