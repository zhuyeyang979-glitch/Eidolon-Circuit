class_name PartCatalogCardButton
extends Button

const PartArt = preload("res://scripts/part_art.gd")
const PartDragGhostView = preload("res://scripts/views/part_drag_ghost_view.gd")
const CatalogCardTextLayer = preload("res://scripts/views/catalog/catalog_card_text_layer.gd")
const CatalogCardRetainedItem = preload("res://scripts/views/catalog/catalog_card_retained_item.gd")
const PartPreviewIconView = preload("res://scripts/views/catalog/part_preview_icon_view.gd")

signal page_scroll(direction: int)

var slot_key := ""
var part := {}
var selected := false
var ui_language := "zh"
var part_index := 0
var display_name := ""
var data_line_a := ""
var data_line_b := ""
var asset_sheet: Texture2D
var joint_sheet: Texture2D
var limb_muscle_sheet: Texture2D
var blade_weapon_sheet: Texture2D
var blunt_weapon_sheet: Texture2D
var pierce_weapon_sheet: Texture2D
var torso_sheet: Texture2D
var booster_sheet: Texture2D
var engine_sheet: Texture2D
var last_component_signature := ""
var projectile_sheet: Texture2D
var last_card_signature := ""
var set_card_call_count := 0
var set_card_apply_count := 0
var set_card_noop_count := 0
var text_layer: CatalogCardTextLayer
var preview_icon: PartPreviewIconView
var retained_item: CatalogCardRetainedItem

func _ready() -> void:
	flat = true
	_ensure_card_nodes()
	if DisplayServer.get_name().to_lower() == "headless":
		_ensure_preview_icon()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_card_nodes()
		if preview_icon != null:
			_sync_preview_icon()

func _get_drag_data(_at_position: Vector2):
	if part.is_empty() or slot_key == "":
		return null
	var preview := PartDragGhostView.new()
	preview.set_card(slot_key, part, false, ui_language, part_index, display_name, "", "")
	preview.set_art_sheets(asset_sheet, joint_sheet, limb_muscle_sheet, blade_weapon_sheet, blunt_weapon_sheet, pierce_weapon_sheet, torso_sheet, booster_sheet, engine_sheet, projectile_sheet)
	set_drag_preview(preview)
	return {"kind": "editor_catalog_part", "slot": slot_key, "index": part_index}

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		var direction := -1 if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
		page_scroll.emit(direction)
		accept_event()

func set_card(next_slot: String, next_part: Dictionary, next_selected: bool, next_language: String, next_index: int, next_display_name: String, next_line_a: String, next_line_b: String) -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		_ensure_preview_icon()
	set_card_call_count += 1
	var signature := _card_signature(next_slot, next_part, next_selected, next_language, next_index, next_display_name, next_line_a, next_line_b)
	_apply_card(signature, next_slot, next_part, next_selected, next_language, next_index, next_display_name, next_line_a, next_line_b)

func set_card_with_signature(signature: String, next_slot: String, next_part: Dictionary, next_selected: bool, next_language: String, next_index: int, next_display_name: String, next_line_a: String, next_line_b: String) -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		_ensure_preview_icon()
	set_card_call_count += 1
	_apply_card(signature, next_slot, next_part, next_selected, next_language, next_index, next_display_name, next_line_a, next_line_b)

func _apply_card(signature: String, next_slot: String, next_part: Dictionary, next_selected: bool, next_language: String, next_index: int, next_display_name: String, next_line_a: String, next_line_b: String) -> void:
	_ensure_card_nodes()
	if signature == last_card_signature:
		set_card_noop_count += 1
		return
	last_card_signature = signature
	set_card_apply_count += 1
	slot_key = next_slot
	part = next_part
	selected = next_selected
	ui_language = next_language
	part_index = next_index
	display_name = next_display_name
	data_line_a = next_line_a
	data_line_b = next_line_b
	if text != "":
		text = ""
	_apply_card_texts()
	_layout_card_nodes()
	if preview_icon != null:
		_sync_preview_icon(false)

func set_art_sheets(next_asset: Texture2D, next_joint: Texture2D, next_limb: Texture2D, next_blade: Texture2D, next_blunt: Texture2D, next_pierce: Texture2D, next_torso: Texture2D, next_booster: Texture2D, next_engine: Texture2D, next_projectile: Texture2D) -> void:
	# Thumbnail art is now renderer-driven; sheet arguments stay only for old call-site compatibility.
	if asset_sheet == null and joint_sheet == null and limb_muscle_sheet == null and blade_weapon_sheet == null and blunt_weapon_sheet == null and pierce_weapon_sheet == null and torso_sheet == null and booster_sheet == null and engine_sheet == null and projectile_sheet == null:
		return
	asset_sheet = null
	joint_sheet = null
	limb_muscle_sheet = null
	blade_weapon_sheet = null
	blunt_weapon_sheet = null
	pierce_weapon_sheet = null
	torso_sheet = null
	booster_sheet = null
	engine_sheet = null
	projectile_sheet = null
	queue_redraw()

func _card_signature(next_slot: String, next_part: Dictionary, next_selected: bool, next_language: String, next_index: int, next_display_name: String, next_line_a: String, next_line_b: String) -> String:
	return "%s|%d|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		next_slot,
		next_index,
		str(next_selected),
		next_language,
		next_display_name,
		next_line_a,
		next_line_b,
		String(next_part.get("name", "")),
		PartArt.normalized_size_tier(next_part),
		String(next_part.get("shape", "")),
		String(next_part.get("material_visual", next_part.get("material_class", ""))),
		String(next_part.get("damage_type", next_part.get("projectile_damage_type", ""))),
		String(next_part.get("weapon_family", "")),
		String(next_part.get("gun_kind", "")),
		str(bool(next_part.get("is_torso", false))),
		str(bool(next_part.get("terminal_weapon", false))),
	]

func _art_rect() -> Rect2:
	var simple_card := data_line_a == "" and data_line_b == ""
	return Rect2(Vector2(8.0, 6.0), Vector2(size.x - 16.0, maxf(26.0, size.y * (0.56 if simple_card else 0.46))))

func _ensure_card_nodes() -> void:
	if retained_item == null:
		retained_item = CatalogCardRetainedItem.new()
		retained_item.name = "CatalogCardRetainedItem"
		add_child(retained_item)
	_layout_card_nodes()

func _layout_card_nodes() -> void:
	if retained_item != null:
		retained_item.position = Vector2.ZERO
		retained_item.size = size
	if text_layer == null:
		return
	var art_rect := _art_rect()
	var data_y := art_rect.position.y + art_rect.size.y + 3.0
	var data_rect := Rect2(Vector2(4.0, data_y), Vector2(size.x - 8.0, size.y - data_y - 4.0))
	text_layer.position = data_rect.position + Vector2(3.0, 0.0)
	text_layer.size = data_rect.size - Vector2(6.0, 0.0)

func _apply_card_texts() -> void:
	if retained_item != null:
		retained_item.configure(slot_key, part, display_name, data_line_a, data_line_b, selected)
	if text_layer != null:
		text_layer.configure(slot_key, part, display_name, data_line_a, data_line_b, selected)

func _ensure_preview_icon() -> void:
	if preview_icon != null:
		return
	preview_icon = PartPreviewIconView.new()
	preview_icon.name = "PartPreviewIcon"
	add_child(preview_icon)
	_sync_preview_icon(true)

func _preview_signature() -> String:
	return "%s|%d|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		slot_key,
		part_index,
		String(part.get("name", "")),
		String(part.get("size_tier", part.get("size_class", part.get("slot_volume_tier", "")))),
		String(part.get("shape", "")),
		String(part.get("material_visual", part.get("material_class", ""))),
		String(part.get("damage_type", part.get("projectile_damage_type", ""))),
		String(part.get("weapon_family", "")),
		String(part.get("gun_kind", "")),
		str(bool(part.get("terminal_weapon", false))),
		str(bool(part.get("is_torso", false))),
		str(selected),
	]

func _sync_preview_icon(force_redraw: bool = false) -> void:
	if preview_icon == null:
		return
	if DisplayServer.get_name().to_lower() != "headless":
		if preview_icon.visible:
			preview_icon.visible = false
		preview_icon.clear_preview()
		return
	var art_rect := _art_rect()
	if preview_icon.position != art_rect.position:
		preview_icon.position = art_rect.position
	if preview_icon.size != art_rect.size:
		preview_icon.size = art_rect.size
	var next_visible := visible and not part.is_empty() and slot_key != ""
	if preview_icon.visible:
		preview_icon.visible = false
	if next_visible:
		preview_icon.set_preview(slot_key, part, false, 0.0, _preview_signature())
	else:
		preview_icon.clear_preview()

func _draw() -> void:
	return

func _draw_art(rect: Rect2) -> void:
	_draw_size_ruler(rect, _thumbnail_size_scale())
	draw_rect(rect.grow(-4.0), _slot_color().darkened(0.25), true)
	draw_rect(rect.grow(-4.0), _slot_color().lerp(Color.WHITE, 0.28), false, 1.2)

func _slot_color() -> Color:
	match slot_key:
		"special":
			return Color(1.0, 0.82, 0.22, 1.0)
		"joint":
			return Color(0.24, 0.82, 1.0, 1.0)
		"limb_muscle":
			return Color(0.76, 0.9, 1.0, 1.0)
		"booster":
			return Color(1.0, 0.42, 0.12, 1.0)
		"engine":
			return Color(0.58, 0.42, 1.0, 1.0)
		"cooling":
			return Color(0.28, 0.96, 0.72, 1.0)
		"module":
			return Color(0.92, 0.94, 1.0, 1.0)
	return _damage_color(String(part.get("projectile_damage_type", part.get("damage_type", ""))))

func _damage_color(damage_type: String) -> Color:
	match damage_type:
		"bullet":
			return Color(1.0, 0.16, 0.1, 1.0)
		"chemical":
			return Color(0.95, 0.92, 0.18, 1.0)
		"laser":
			return Color(0.18, 0.84, 1.0, 1.0)
		"pierce":
			return Color(0.88, 0.24, 1.0, 1.0)
		"tear":
			return Color(1.0, 0.38, 0.18, 1.0)
		"impact":
			return Color(1.0, 0.66, 0.18, 1.0)
		"explosive":
			return Color(1.0, 0.32, 0.08, 1.0)
		"web":
			return Color(0.78, 0.9, 1.0, 1.0)
	return Color(0.72, 0.82, 0.9, 1.0)

func _card_material_style() -> String:
	return String(part.get("material_visual", part.get("material_class", "metal")))

func _card_material_color() -> Color:
	return PartArt.material_color_for(_card_material_style(), slot_key)

func _draw_card_material_marks(center: Vector2, axis: Vector2, length: float, width: float, material_style: String, alpha: float = 1.0) -> void:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	match material_style:
		"metal":
			draw_line(center - forward * length * 0.42 - right * width * 0.22, center + forward * length * 0.42 - right * width * 0.12, Color(1.0, 1.0, 1.0, 0.44 * alpha), maxf(1.0, width * 0.14))
			draw_line(center - forward * length * 0.46 + right * width * 0.42, center + forward * length * 0.46 + right * width * 0.42, Color(0.02, 0.05, 0.07, 0.5 * alpha), maxf(1.0, width * 0.08))
		"wood":
			for i in range(4):
				var offset := right * width * (-0.35 + float(i) * 0.23)
				draw_line(center - forward * length * 0.42 + offset, center + forward * length * 0.42 + offset + right * width * 0.04 * sin(float(i)), Color(0.18, 0.09, 0.04, 0.56 * alpha), maxf(1.0, width * 0.06))
			draw_circle(center + forward * length * 0.08 + right * width * 0.14, maxf(1.1, width * 0.09), Color(0.11, 0.05, 0.02, 0.42 * alpha))
		"ceramic":
			for i in range(3):
				var p0 := center - forward * length * (0.34 - float(i) * 0.2) + right * width * (0.18 - float(i) * 0.12)
				draw_line(p0, p0 + forward * length * 0.17 + right * width * (0.16 if i % 2 == 0 else -0.14), Color(0.18, 0.17, 0.14, 0.42 * alpha), maxf(1.0, width * 0.05))
			for i in range(6):
				draw_circle(center + forward * length * (-0.4 + float(i) * 0.16) + right * width * (0.26 * sin(float(i) * 1.9)), maxf(0.7, width * 0.025), Color(1.0, 1.0, 1.0, 0.28 * alpha))
		"fur":
			for i in range(10):
				var t := -0.46 + float(i) / 9.0 * 0.92
				for side in [-1.0, 1.0]:
					var base: Vector2 = center + forward * length * t + right * width * 0.5 * float(side)
					draw_line(base, base + right * side * width * 0.22 + forward * width * 0.05 * sin(float(i)), Color(0.92, 0.74, 0.46, 0.52 * alpha), maxf(1.0, width * 0.05))

func _booster_flame_color() -> Color:
	var flame := String(part.get("flame_color", "")).to_lower()
	var style := String(part.get("thruster_family", "")).to_lower()
	if flame.contains("red") or style.contains("burst") or style.contains("overburn"):
		return Color(1.0, 0.16, 0.08, 0.92)
	if flame.contains("yellow") or style.contains("sustain"):
		return Color(1.0, 0.86, 0.18, 0.92)
	return Color(0.24, 0.72, 1.0, 0.92)

func _draw_shared_card_asset(rect: Rect2, size_scale: float) -> bool:
	return false

func _card_asset_region() -> Rect2:
	var cell := asset_sheet.get_size() / 4.0
	var index := _card_asset_index()
	return Rect2(Vector2(float(index % 4) * cell.x, float(index / 4) * cell.y), cell)

func _card_joint_region() -> Rect2:
	var cell := joint_sheet.get_size() / Vector2(4.0, 7.0)
	return Rect2(Vector2(float(_card_material_column()) * cell.x, float(_card_joint_row()) * cell.y), cell)

func _card_limb_muscle_region() -> Rect2:
	var cell := limb_muscle_sheet.get_size() / Vector2(4.0, 3.0)
	return Rect2(Vector2(float(_card_material_column()) * cell.x, float(_card_length_row()) * cell.y), cell)

func _card_blade_region() -> Rect2:
	var cell := blade_weapon_sheet.get_size() / Vector2(3.0, 3.0)
	return Rect2(Vector2(float(_card_blade_column()) * cell.x, float(_card_weapon_row()) * cell.y), cell)

func _card_blunt_region() -> Rect2:
	var cell := blunt_weapon_sheet.get_size() / Vector2(3.0, 3.0)
	return Rect2(Vector2(float(_card_blunt_column()) * cell.x, float(_card_weapon_row()) * cell.y), cell)

func _card_pierce_region() -> Rect2:
	var cell := pierce_weapon_sheet.get_size() / Vector2(3.0, 3.0)
	return Rect2(Vector2(float(_card_pierce_column()) * cell.x, float(_card_weapon_row()) * cell.y), cell)

func _card_projectile_region() -> Rect2:
	var cell := projectile_sheet.get_size() / Vector2(4.0, 2.0)
	var column := 0
	var damage_type := String(part.get("projectile_damage_type", part.get("damage_type", "bullet"))).to_lower()
	var behavior := String(part.get("projectile_behavior", part.get("projectile_style", ""))).to_lower()
	var name := String(part.get("name", "")).to_upper()
	if damage_type == "laser" or name.contains("LASER"):
		column = 0
	elif behavior.contains("true") or name.contains("RAIL") or name.contains("SNIPER"):
		column = 1
	elif damage_type == "chemical" or name.contains("CHEM") or name.contains("ACID"):
		column = 3
	else:
		column = 2
	var row := 1 if float(part.get("mass", 0.0)) >= 18.0 or float(part.get("range", 0.0)) >= 5.0 else 0
	return Rect2(Vector2(float(column) * cell.x, float(row) * cell.y), cell)

func _card_torso_region() -> Rect2:
	var cell := torso_sheet.get_size() / Vector2(8.0, 4.0)
	return Rect2(Vector2(float(_card_torso_column()) * cell.x, float(_card_torso_row()) * cell.y), cell)

func _card_booster_region() -> Rect2:
	var cell := booster_sheet.get_size() / Vector2(3.0, 4.0)
	return Rect2(Vector2(float(_card_booster_column()) * cell.x, float(_card_booster_row()) * cell.y), cell)

func _card_engine_region() -> Rect2:
	var cell := engine_sheet.get_size() / Vector2(3.0, 3.0)
	return Rect2(Vector2(float(_card_engine_column()) * cell.x, float(_card_engine_row()) * cell.y), cell)

func _card_material_column() -> int:
	var key := "%s %s %s" % [String(part.get("name", "")).to_lower(), String(part.get("shape", "")).to_lower(), String(part.get("material_class", "")).to_lower()]
	if key.contains("ceramic") or key.contains("stone"):
		return 1
	if key.contains("wood") or key.contains("timber") or key.contains("stake"):
		return 2
	if key.contains("fur") or key.contains("padded") or key.contains("sleeve"):
		return 3
	return 0

func _card_joint_row() -> int:
	var key := "%s %s %s" % [String(part.get("name", "")).to_lower(), String(part.get("shape", "")).to_lower(), String(part.get("motion", "")).to_lower()]
	var length := float(part.get("length", 0.18))
	var joint_range := float(part.get("range", part.get("max_extension_m", 0.0)))
	if bool(part.get("fixed_corner_joint", false)) or key.contains("corner"):
		return 5
	if key.contains("90") or key.contains("ball_90") or key.contains("socket_90"):
		return 0
	if key.contains("180") or key.contains("gimbal") or key.contains("yoke") or String(part.get("cancel_profile", "")).to_lower() == "bidirectional":
		return 1
	if key.contains("curved") or key.contains("arc"):
		return 5 if length <= 0.34 else 6
	if key.contains("linear") or key.contains("telescopic") or joint_range > 0.08:
		if length <= 0.12:
			return 2
		if length <= 0.32:
			return 3
		return 4
	return 0

func _card_length_row() -> int:
	var length := float(part.get("length", 0.48))
	if length <= 0.4:
		return 0
	if length <= 0.7:
		return 1
	return 2

func _card_weapon_row() -> int:
	var name := String(part.get("name", "")).to_upper()
	var length := float(part.get("length", 0.62))
	var mass := float(part.get("mass", 8.0))
	var size_class := String(part.get("size_class", "")).to_lower()
	if size_class in ["nano", "micro", "xs", "small", "s"] or name.contains("SHORT") or name.contains("LIGHT") or length <= 0.52 or mass <= 5.0:
		return 0
	if size_class in ["monster", "xl", "kaiju", "colossus", "leviathan"] or name.contains("LONG") or name.contains("HEAVY") or length >= 1.0 or mass >= 28.0:
		return 2
	return 1

func _card_blade_column() -> int:
	var key := "%s %s" % [String(part.get("name", "")).to_lower(), String(part.get("shape", "")).to_lower()]
	if key.contains("scythe") or key.contains("crescent"):
		return 0
	if key.contains("katana") or key.contains("odachi") or key.contains("saber"):
		return 1
	return 2

func _card_blunt_column() -> int:
	var key := "%s %s" % [String(part.get("name", "")).to_lower(), String(part.get("shape", "")).to_lower()]
	if key.contains("shield") or key.contains("buckler"):
		return 0
	if key.contains("hammer") or key.contains("mace") or key.contains("jack"):
		return 1
	return 2

func _card_pierce_column() -> int:
	var key := "%s %s" % [String(part.get("name", "")).to_lower(), String(part.get("shape", "")).to_lower()]
	if key.contains("drill") or key.contains("auger") or key.contains("borer"):
		return 2
	if key.contains("rapier") or key.contains("foil") or key.contains("epee") or key.contains("needle") or key.contains("stiletto") or key.contains("rod"):
		return 1
	return 0

func _card_torso_column() -> int:
	var key := "%s %s %s" % [String(part.get("name", "")).to_lower(), String(part.get("shape", "")).to_lower(), String(part.get("archetype", "")).to_lower()]
	if key.contains("shrimp") or key.contains("prawn") or key.contains("lobster"):
		return 1
	if key.contains("octopus") or key.contains("mantle") or key.contains("tentacle"):
		return 2
	if key.contains("snake") or key.contains("serpent"):
		return 3
	if key.contains("centipede") or key.contains("leviathan"):
		return 4
	if key.contains("tank") or key.contains("arsenal"):
		return 5
	if key.contains("hound") or key.contains("dog"):
		return 6
	if key.contains("human") or key.contains("pilot") or key.contains("humanoid") or key.contains("head") or key.contains("chest") or key.contains("scout_core"):
		return 7
	return 0

func _card_torso_row() -> int:
	var key := "%s %s" % [String(part.get("name", "")).to_lower(), String(part.get("torso_material", part.get("material_visual", ""))).to_lower()]
	if key.contains("ceramic") or key.contains("stone"):
		return 1
	if key.contains("wood") or key.contains("timber"):
		return 2
	if key.contains("fur") or key.contains("padded") or key.contains("sleeve"):
		return 3
	return 0

func _card_booster_column() -> int:
	var key := "%s %s %s" % [String(part.get("name", "")).to_lower(), String(part.get("flame_color", "")).to_lower(), String(part.get("thruster_family", "")).to_lower()]
	if key.contains("yellow") or key.contains("sustain"):
		return 1
	if key.contains("red") or key.contains("overburn") or key.contains("burst"):
		return 2
	return 0

func _card_booster_row() -> int:
	var name := String(part.get("name", "")).to_upper()
	var mass := float(part.get("mass", 0.0))
	var momentum := float(part.get("boost_momentum", 0.0)) + float(part.get("drive_demand", part.get("momentum_min", part.get("allocated_momentum", 0.0))))
	if name.contains("NANO") or name.contains("MICRO") or mass <= 2.5 or momentum <= 70.0:
		return 0
	if name.contains("COLOSSUS") or name.contains("TITAN") or name.contains("SIEGE") or mass >= 34.0 or momentum >= 360.0:
		return 3
	if name.contains("HEAVY") or mass >= 10.0 or momentum >= 170.0:
		return 2
	return 1

func _card_engine_column() -> int:
	var key := "%s %s" % [String(part.get("name", "")).to_lower(), String(part.get("engine_family", "")).to_lower()]
	if key.contains("furnace") or key.contains("titan") or key.contains("colossus"):
		return 2
	if key.contains("mobility") or key.contains("light") or key.contains("turbine") or key.contains("compact"):
		return 1
	return 0

func _card_engine_row() -> int:
	var tier := String(part.get("slot_volume_tier", "")).to_upper()
	var power := float(part.get("power", 0.0))
	var mass := float(part.get("mass", 0.0))
	if tier in ["XS", "S"] or power <= 28.0 or mass <= 3.0:
		return 0
	if tier == "XL" or power >= 140.0 or mass >= 70.0:
		return 2
	return 1

func _card_is_projectile_weapon() -> bool:
	var explicit_kind := String(part.get("terminal_weapon_kind", "")).to_lower()
	if explicit_kind == "melee":
		return false
	if explicit_kind == "ranged":
		return true
	var material_class := String(part.get("material_class", "")).to_lower()
	var shape := String(part.get("shape", "")).to_lower()
	return bool(part.get("projectile", false)) or material_class in ["gun", "missile_launcher", "web_gun"] or shape.contains("gun") or shape.contains("rifle") or shape.contains("cannon") or shape.contains("launcher")

func _card_is_torso() -> bool:
	var material_class := String(part.get("material_class", "")).to_lower()
	return bool(part.get("is_torso", false)) or material_class == "torso"

func _card_is_blade_weapon() -> bool:
	var damage_type := String(part.get("damage_type", "")).to_lower()
	var material_class := String(part.get("material_class", "")).to_lower()
	var terminal_like := bool(part.get("terminal_weapon", false)) or int(part.get("connection_ends", 2)) <= 1 or material_class in ["weapon", "racket"]
	var key := "%s %s" % [String(part.get("name", "")).to_lower(), String(part.get("shape", "")).to_lower()]
	return damage_type == "tear" and (terminal_like or key.contains("scythe") or key.contains("katana") or key.contains("greatsword") or key.contains("machete") or key.contains("blade") or key.contains("razor") or key.contains("saber") or key.contains("wing") or key.contains("tail"))

func _card_is_blunt_weapon() -> bool:
	var damage_type := String(part.get("damage_type", "")).to_lower()
	var material_class := String(part.get("material_class", "")).to_lower()
	var terminal_like := bool(part.get("terminal_weapon", false)) or int(part.get("connection_ends", 2)) <= 1 or material_class in ["weapon", "racket"]
	var key := "%s %s" % [String(part.get("name", "")).to_lower(), String(part.get("shape", "")).to_lower()]
	return damage_type == "blunt" and (terminal_like or key.contains("shield") or key.contains("hammer") or key.contains("mace") or key.contains("glove") or key.contains("gauntlet") or key.contains("fist") or key.contains("jack"))

func _card_is_pierce_weapon() -> bool:
	var damage_type := String(part.get("damage_type", "")).to_lower()
	var material_class := String(part.get("material_class", "")).to_lower()
	var terminal_like := bool(part.get("terminal_weapon", false)) or int(part.get("connection_ends", 2)) <= 1 or material_class in ["weapon", "racket"]
	var key := "%s %s" % [String(part.get("name", "")).to_lower(), String(part.get("shape", "")).to_lower()]
	return damage_type == "pierce" and (terminal_like or key.contains("lance") or key.contains("spear") or key.contains("pike") or key.contains("rapier") or key.contains("needle") or key.contains("drill") or key.contains("spike") or key.contains("talon"))

func _card_asset_index() -> int:
	var damage_type := String(part.get("damage_type", part.get("projectile_damage_type", "blunt"))).to_lower()
	if slot_key == "special":
		return 0
	if slot_key == "joint":
		return 4
	if slot_key == "limb_muscle":
		return 6
	if slot_key == "booster":
		return 15
	if slot_key in ["engine", "cooling", "module"]:
		return 6
	if _card_is_projectile_weapon():
		return 9 if damage_type == "laser" else (10 if damage_type == "chemical" else 8)
	if damage_type == "tear":
		return 12
	if damage_type == "pierce":
		return 13
	return 14

func _normalized_size_tier_local(raw_value: String) -> String:
	var value := raw_value.strip_edges().to_upper()
	if value == "":
		return ""
	if value in ["XS", "S", "M", "L", "XL"]:
		return value
	match value.to_lower():
		"nano", "micro", "tiny", "starter":
			return "XS"
		"small":
			return "S"
		"medium", "standard":
			return "M"
		"long", "heavy", "siege", "titan":
			return "L"
		"monster", "kaiju", "colossus", "leviathan":
			return "XL"
	return "M"

func _footprint_size_tier_local() -> String:
	var length := float(part.get("length", 0.0))
	var radius := float(part.get("radius", 0.0))
	var mass := float(part.get("mass", 0.0))
	var footprint := maxf(length, radius * 2.7) + mass * 0.002
	if footprint <= 0.18:
		return "XS"
	if footprint <= 0.48:
		return "S"
	if footprint <= 1.15:
		return "M"
	if footprint <= 2.35:
		return "L"
	return "XL"

func _card_size_tier() -> String:
	return PartArt.normalized_size_tier(part)

func _card_size_rank() -> int:
	match _card_size_tier():
		"XS":
			return 1
		"S":
			return 2
		"M":
			return 3
		"L":
			return 4
		"XL":
			return 5
	return 3

func _thumbnail_size_scale() -> float:
	return PartArt.size_scale_for(part)

func _size_badge_text() -> String:
	return _card_size_tier()

func _draw_size_badge(rect: Rect2) -> void:
	var badge := _size_badge_text()
	var font := ThemeDB.get_fallback_font()
	var badge_rect := Rect2(rect.end - Vector2(44.0, 20.0), Vector2(40.0, 17.0))
	draw_rect(badge_rect, Color(0.0, 0.0, 0.0, 0.58), true)
	draw_rect(badge_rect, Color(1.0, 0.86, 0.25, 0.82), false, 1.4)
	draw_string(font, badge_rect.position + Vector2(3.0, 12.5), badge, HORIZONTAL_ALIGNMENT_CENTER, badge_rect.size.x - 6.0, 10, Color(1.0, 0.92, 0.35, 1.0))

func _draw_size_ruler(rect: Rect2, size_scale: float) -> void:
	var normalized := clampf((size_scale - 0.42) / maxf(0.001, 2.05 - 0.42), 0.0, 1.0)
	var width := lerpf(rect.size.x * 0.24, rect.size.x * 0.92, normalized)
	var y := rect.end.y - 5.0
	var x0 := rect.position.x + (rect.size.x - width) * 0.5
	draw_line(Vector2(x0, y), Vector2(x0 + width, y), Color(1.0, 0.86, 0.24, 0.7), 1.6)
	for i in range(5):
		var x := lerpf(x0, x0 + width, float(i) / 4.0)
		draw_line(Vector2(x, y - 3.0), Vector2(x, y + 2.0), Color(1.0, 0.86, 0.24, 0.48), 1.0)

func _trim(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, maxi(1, max_chars - 1)) + "."

func _draw_triangle(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(3):
		var angle := rotation + TAU * float(i) / 3.0
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(pts, color)

func _saddle_polygon(center: Vector2, axis: Vector2, length: float, front_width: float, rear_width: float) -> PackedVector2Array:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	var pts := PackedVector2Array()
	for local in PartArt.torso_hull_local_points(part, length, front_width, rear_width):
		var p: Vector2 = local
		pts.append(center + forward * p.x + right * p.y)
	return pts

func _saddle_port_positions(center: Vector2, axis: Vector2, port_count: int, length: float, front_width: float, rear_width: float) -> Array:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	var positions: Array = []
	for local in PartArt.torso_hull_port_local_offsets(part, port_count, length, front_width, rear_width):
		var p: Vector2 = local
		positions.append(center + forward * p.x + right * p.y)
	return positions

func _regular_polygon(center: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(maxi(3, sides)):
		var angle := -PI * 0.5 + TAU * float(i) / float(maxi(3, sides))
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts
