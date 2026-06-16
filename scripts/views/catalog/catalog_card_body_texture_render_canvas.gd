class_name CatalogCardBodyTextureRenderCanvas
extends Control

const CATALOG_CARD_TITLE_FONT_SIZE := 11
const CATALOG_CARD_SIMPLE_TITLE_FONT_SIZE := 12
const CATALOG_CARD_LINE_FONT_SIZE := 9
const CATALOG_CARD_TEXT_PLATE_ALPHA := 0.62

var display_name := ""
var data_line_a := ""
var data_line_b := ""
var selected := false

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(next_display_name: String, next_line_a: String, next_line_b: String, next_selected: bool, next_size: Vector2) -> void:
	display_name = next_display_name
	data_line_a = next_line_a
	data_line_b = next_line_b
	selected = next_selected
	size = next_size
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.get_fallback_font()
	var simple_card := data_line_a == "" and data_line_b == ""
	var title_color := Color(1.0, 0.92, 0.36, 1.0) if selected else Color(0.9, 0.96, 1.0, 0.98)
	var title_size := CATALOG_CARD_SIMPLE_TITLE_FONT_SIZE if simple_card else CATALOG_CARD_TITLE_FONT_SIZE
	var title_pos := Vector2(2.0, 15.0 if simple_card else 11.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, CATALOG_CARD_TEXT_PLATE_ALPHA), true)
	draw_string(font, title_pos + Vector2(1.0, 1.0), _card_trim(display_name, 17 if simple_card else 14), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, title_size, Color(0.0, 0.0, 0.0, 0.82))
	draw_string(font, title_pos, _card_trim(display_name, 17 if simple_card else 14), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, title_size, title_color)
	if not simple_card:
		var line_a_pos := Vector2(2.0, 21.0)
		var line_b_pos := Vector2(2.0, minf(32.0, size.y - 3.0))
		draw_string(font, line_a_pos + Vector2(1.0, 1.0), _card_trim(data_line_a, 15), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, CATALOG_CARD_LINE_FONT_SIZE, Color(0.0, 0.0, 0.0, 0.78))
		draw_string(font, line_a_pos, _card_trim(data_line_a, 15), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, CATALOG_CARD_LINE_FONT_SIZE, Color(0.82, 0.94, 1.0, 1.0))
		draw_string(font, line_b_pos + Vector2(1.0, 1.0), _card_trim(data_line_b, 15), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, CATALOG_CARD_LINE_FONT_SIZE, Color(0.0, 0.0, 0.0, 0.76))
		draw_string(font, line_b_pos, _card_trim(data_line_b, 15), HORIZONTAL_ALIGNMENT_LEFT, size.x - 4.0, CATALOG_CARD_LINE_FONT_SIZE, Color(0.78, 0.86, 0.94, 1.0))

func _card_trim(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, max(0, max_chars - 1)) + "."
