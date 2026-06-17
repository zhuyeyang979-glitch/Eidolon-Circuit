class_name CatalogCardTextLayer
extends Control

const CatalogCardBodyTextureCache = preload("res://scripts/views/catalog/catalog_card_body_texture_cache.gd")
const CATALOG_CARD_TITLE_FONT_SIZE := 10
const CATALOG_CARD_SIMPLE_TITLE_FONT_SIZE := 11
const CATALOG_CARD_LINE_FONT_SIZE := 8
const CATALOG_CARD_TEXT_PLATE_ALPHA := 0.62

const CACHE_MAX_ENTRIES := 192

var display_name := ""
var data_line_a := ""
var data_line_b := ""
var slot_key := ""
var part := {}
var selected := false
var last_text_signature := ""
var body_texture: Texture2D

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE

func configure(next_slot: String, next_part: Dictionary, next_display_name: String, next_line_a: String, next_line_b: String, next_selected: bool) -> void:
	var size_key := "%dx%d" % [maxi(1, int(round(size.x))), maxi(1, int(round(size.y)))]
	var signature := "%s|%s|%s|%s|%s|%s|%s" % [
		next_slot,
		String(next_part.get("stable_key", next_part.get("name", ""))),
		next_display_name,
		next_line_a,
		next_line_b,
		str(next_selected),
		size_key,
	]
	if signature == last_text_signature:
		return
	last_text_signature = signature
	slot_key = next_slot
	part = next_part
	display_name = next_display_name
	data_line_a = next_line_a
	data_line_b = next_line_b
	selected = next_selected
	body_texture = CatalogCardBodyTextureCache.request_preview(self, slot_key, part, display_name, data_line_a, data_line_b, selected, size)
	queue_redraw()

func _draw() -> void:
	if body_texture == null:
		body_texture = CatalogCardBodyTextureCache.peek_preview(slot_key, part, display_name, data_line_a, data_line_b, selected, size)
	if body_texture != null:
		draw_texture_rect(body_texture, Rect2(Vector2.ZERO, size), false)
		return
	var font := ThemeDB.get_fallback_font()
	var simple_card := data_line_a == "" and data_line_b == ""
	var title_color := Color(1.0, 0.92, 0.36, 1.0) if selected else Color(0.9, 0.96, 1.0, 0.98)
	var compact := size.y < 30.0 and not simple_card
	var title_size := CATALOG_CARD_SIMPLE_TITLE_FONT_SIZE if simple_card else CATALOG_CARD_TITLE_FONT_SIZE
	var line_size := 7 if compact else CATALOG_CARD_LINE_FONT_SIZE
	var title_pos := Vector2(2.0, 15.0 if simple_card else (8.8 if compact else 11.0))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, CATALOG_CARD_TEXT_PLATE_ALPHA), true)
	draw_string(font, title_pos + Vector2(1.0, 1.0), _card_trim(display_name, 17 if simple_card else (15 if compact else 14)), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, title_size, Color(0.0, 0.0, 0.0, 0.82))
	draw_string(font, title_pos, _card_trim(display_name, 17 if simple_card else (15 if compact else 14)), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, title_size, title_color)
	if not simple_card:
		var line_a_pos := Vector2(2.0, 16.4 if compact else 21.0)
		var line_b_pos := Vector2(2.0, minf(23.4 if compact else 32.0, size.y - 3.0))
		draw_string(font, line_a_pos + Vector2(1.0, 1.0), _card_trim(data_line_a, 16 if compact else 15), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, line_size, Color(0.0, 0.0, 0.0, 0.78))
		draw_string(font, line_a_pos, _card_trim(data_line_a, 16 if compact else 15), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, line_size, Color(0.82, 0.94, 1.0, 1.0))
		draw_string(font, line_b_pos + Vector2(1.0, 1.0), _card_trim(data_line_b, 16 if compact else 15), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, line_size, Color(0.0, 0.0, 0.0, 0.76))
		draw_string(font, line_b_pos, _card_trim(data_line_b, 16 if compact else 15), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, line_size, Color(0.78, 0.86, 0.94, 1.0))

func _card_trim(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, max(0, max_chars - 1)) + "."
