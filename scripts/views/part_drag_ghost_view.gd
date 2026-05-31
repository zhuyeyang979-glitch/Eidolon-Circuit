extends Control
class_name PartDragGhostView

const PartArt = preload("res://scripts/part_art.gd")
const AssemblyBoardRenderer = preload("res://scripts/assembly_board_renderer.gd")


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
var projectile_sheet: Texture2D


func _init() -> void:
	size = Vector2(118.0, 82.0)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color(1.0, 1.0, 1.0, 0.55)
	focus_mode = Control.FOCUS_NONE


func set_card(next_slot: String, next_part: Dictionary, next_selected: bool, next_language: String, next_index: int, next_display_name: String, next_line_a: String, next_line_b: String) -> void:
	slot_key = next_slot
	part = next_part
	selected = next_selected
	ui_language = next_language
	part_index = next_index
	display_name = next_display_name
	data_line_a = next_line_a
	data_line_b = next_line_b
	var rank := clampi(_card_size_rank(), 1, 5)
	var size_scale := lerpf(0.78, 1.22, float(rank - 1) / 4.0)
	size = Vector2(112.0, 78.0) * size_scale
	size.x = clampf(size.x, 88.0, 142.0)
	size.y = clampf(size.y, 62.0, 100.0)
	custom_minimum_size = size
	queue_redraw()


func set_art_sheets(next_asset: Texture2D, next_joint: Texture2D, next_limb: Texture2D, next_blade: Texture2D, next_blunt: Texture2D, next_pierce: Texture2D, next_torso: Texture2D, next_booster: Texture2D, next_engine: Texture2D, next_projectile: Texture2D) -> void:
	# Thumbnail art is renderer-driven; sheet arguments stay only for old drag-preview call-site compatibility.
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


func _draw() -> void:
	if not visible or part.is_empty() or slot_key == "":
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect.grow(2.0), Color(0.0, 0.0, 0.0, 0.22), true)
	draw_rect(rect, Color(0.02, 0.04, 0.052, 0.58), true)
	draw_rect(rect, _slot_color().lerp(Color.WHITE, 0.18), false, 1.6)
	var art_rect := Rect2(Vector2(7.0, 7.0), size - Vector2(14.0, 14.0))
	draw_rect(art_rect, Color(0.0, 0.0, 0.0, 0.22), true)
	AssemblyBoardRenderer.draw_part_preview(self, art_rect, slot_key, part, false, 0.0)
	_draw_size_ruler(art_rect, _thumbnail_size_scale())
	_draw_size_badge(art_rect)


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


func _card_size_rank() -> int:
	match PartArt.normalized_size_tier(part):
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


func _draw_size_badge(rect: Rect2) -> void:
	var badge := PartArt.normalized_size_tier(part)
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
