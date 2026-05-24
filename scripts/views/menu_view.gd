extends RefCounted
class_name MenuView

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
	main_ref._add_ui_rect(root, "MenuHeaderBand", Vector2(42.0, 34.0), Vector2(1136.0, 130.0), Color(0.012, 0.022, 0.032, 0.72))
	main_ref._make_label(root, "GameTitle", "", Vector2(64.0, 40.0), Vector2(690.0, 56.0), 40, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	main_ref._make_label(root, "Subtitle", "", Vector2(68.0, 112.0), Vector2(520.0, 28.0), 18, Color(0.26, 0.88, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	main_ref._add_ui_rect(root, "Accent", Vector2(68.0, 148.0), Vector2(346.0, 4.0), Color(1.0, 0.88, 0.22, 1.0))
	main_ref._make_label(root, "MenuCallsign", "", Vector2(656.0, 112.0), Vector2(480.0, 28.0), 15, Color(1.0, 0.86, 0.38, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	main_ref._add_ui_rect(root, "MenuListPanel", Vector2(54.0, 184.0), Vector2(438.0, 430.0), Color(0.01, 0.018, 0.026, 0.72))
	main_ref._add_ui_rect(root, "MenuInfoPanel", Vector2(536.0, 184.0), Vector2(620.0, 226.0), Color(0.014, 0.024, 0.034, 0.82))
	menu_description_label = main_ref._make_label(root, "MenuDescription", "", Vector2(570.0, 212.0), Vector2(552.0, 138.0), 23, Color(0.9, 0.94, 0.98, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	menu_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_status_label = main_ref._make_label(root, "MenuStatus", "", Vector2(570.0, 354.0), Vector2(552.0, 42.0), 14, Color(0.32, 0.94, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	menu_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_ref._make_label(root, "MenuTelemetry", "", Vector2(540.0, 438.0), Vector2(604.0, 26.0), 16, Color(1.0, 0.88, 0.32, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	main_ref._make_label(root, "MenuHelp", "", Vector2(64.0, 656.0), Vector2(980.0, 28.0), 17, Color(0.78, 0.84, 0.9, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	for i in range(MenuController.MAIN_MENU_SPECS.size()):
		var button := Button.new()
		button.position = Vector2(82.0, 204.0 + float(i) * 56.0)
		button.size = Vector2(382.0, 44.0)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.mouse_entered.connect(main_ref._hover_menu_item.bind(i))
		button.pressed.connect(main_ref._activate_menu_item.bind(i))
		button.gui_input.connect(main_ref._handle_menu_button_gui_input.bind(i))
		root.add_child(button)
		menu_buttons.append(button)
	menu_ai_seat_panel = main_ref._add_ui_rect(root, "MenuAISeatPanel", Vector2(536.0, 466.0), Vector2(620.0, 114.0), Color(0.012, 0.028, 0.038, 0.86))
	menu_ai_seat_label = main_ref._make_label(root, "MenuAISeatLabel", "", Vector2(566.0, 476.0), Vector2(560.0, 24.0), 16, Color(1.0, 0.88, 0.32, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	for i in range(MenuController.AI_SEAT_SPECS.size()):
		var spec: Dictionary = MenuController.AI_SEAT_SPECS[i]
		var seat_button := Button.new()
		seat_button.position = Vector2(566.0 + float(i) * 190.0, 512.0)
		seat_button.size = Vector2(170.0, 48.0)
		seat_button.focus_mode = Control.FOCUS_NONE
		seat_button.mouse_filter = Control.MOUSE_FILTER_STOP
		seat_button.pressed.connect(main_ref._start_ai_battle_from_menu.bind(int(spec.get("seat", i + 1))))
		root.add_child(seat_button)
		menu_ai_seat_buttons.append(seat_button)
	return menu_layer


func update_main_menu(model: Dictionary) -> void:
	var items: Array = model.get("items", [])
	var selected := int(model.get("selected_index", 0))
	main_ref._set_named_label(menu_layer, "GameTitle", String(model.get("title", "")))
	main_ref._set_named_label(menu_layer, "Subtitle", String(model.get("subtitle", "")))
	main_ref._set_named_label(menu_layer, "MenuCallsign", String(model.get("callsign", "")))
	main_ref._set_named_label(menu_layer, "MenuTelemetry", String(model.get("telemetry", "")))
	main_ref._set_named_label(menu_layer, "MenuHelp", String(model.get("help", "")))
	main_ref._set_named_label(menu_layer, "MenuAISeatLabel", String(model.get("ai_seat_title", "")))
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
	page_options_panel.position = Vector2(952.0, 72.0)
	page_options_panel.size = Vector2(246.0, 228.0)
	page_options_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(page_options_panel)
	main_ref._add_ui_rect(page_options_panel, "PageOptionsBack", Vector2.ZERO, page_options_panel.size, Color(0.01, 0.018, 0.026, 0.94))
	main_ref._add_ui_rect(page_options_panel, "PageOptionsAccent", Vector2(16.0, 42.0), Vector2(214.0, 2.0), Color(0.24, 0.9, 1.0, 0.85))
	main_ref._make_label(page_options_panel, "PageOptionsTitle", "", Vector2(16.0, 12.0), Vector2(214.0, 26.0), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(MenuController.PAGE_OPTION_SPECS.size()):
		var spec: Dictionary = MenuController.PAGE_OPTION_SPECS[i]
		var key := String(spec.get("key", ""))
		var button := Button.new()
		button.name = "PageOptions%s" % key
		button.position = Vector2(18.0, 56.0 + float(i) * 32.0)
		button.size = Vector2(210.0, 28.0)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(main_ref._page_options_action.bind(key))
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
	main_ref._set_named_label(page_options_panel, "PageOptionsTitle", String(model.get("title", "")))
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
	battle_runtime_menu_panel.position = Vector2(856.0, 252.0)
	battle_runtime_menu_panel.size = Vector2(330.0, 340.0)
	battle_runtime_menu_panel.visible = false
	root.add_child(battle_runtime_menu_panel)
	main_ref._add_ui_rect(battle_runtime_menu_panel, "BattleRuntimeOptionsBack", Vector2.ZERO, battle_runtime_menu_panel.size, Color(0.01, 0.018, 0.026, 0.9))
	main_ref._make_label(battle_runtime_menu_panel, "BattleRuntimeOptionsTitle", "", Vector2(18.0, 12.0), Vector2(294.0, 28.0), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(MenuController.BATTLE_RUNTIME_OPTION_SPECS.size()):
		var spec: Dictionary = MenuController.BATTLE_RUNTIME_OPTION_SPECS[i]
		var key := String(spec.get("key", ""))
		var button := Button.new()
		button.name = "BattleRuntimeOption%s" % key
		button.position = Vector2(24.0, 52.0 + float(i) * 34.0)
		button.size = Vector2(282.0, 28.0)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(main_ref._battle_runtime_menu_action.bind(key))
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
	main_ref._set_named_label(battle_runtime_menu_panel, "BattleRuntimeOptionsTitle", String(model.get("title", "")))
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
