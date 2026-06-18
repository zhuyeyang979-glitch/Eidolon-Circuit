class_name CatalogCardRetainedItem
extends Control

const PartArt = preload("res://scripts/part_art.gd")
const PartIdentity = preload("res://scripts/part_identity.gd")
const PartPreviewTextureCache = preload("res://scripts/views/catalog/part_preview_texture_cache.gd")
const CATALOG_CARD_TITLE_FONT_SIZE := 10
const CATALOG_CARD_SIMPLE_TITLE_FONT_SIZE := 11
const CATALOG_CARD_LINE_FONT_SIZE := 8
const CATALOG_CARD_TEXT_PLATE_ALPHA := 0.62

static var defer_texture_requests := false

var slot_key := ""
var part := {}
var display_name := ""
var data_line_a := ""
var data_line_b := ""
var ui_language := "zh"
var selected := false
var content_signature := ""
var textures_requested_signature := ""
var preview_texture: Texture2D
var body_texture: Texture2D
var preview_request_count := 0
var body_request_count := 0
var redraw_count := 0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE

func configure(next_slot: String, next_part: Dictionary, next_display_name: String, next_line_a: String, next_line_b: String, next_selected: bool, next_language: String = "zh") -> void:
	var next_signature := _content_signature(next_slot, next_part, next_display_name, next_line_a, next_line_b, next_language)
	var selected_changed := selected != next_selected
	selected = next_selected
	if next_signature == content_signature:
		if selected_changed:
			queue_redraw()
		return
	content_signature = next_signature
	slot_key = next_slot
	part = next_part
	display_name = next_display_name
	data_line_a = next_line_a
	data_line_b = next_line_b
	ui_language = next_language
	preview_texture = PartPreviewTextureCache.peek_preview(slot_key, part, false, 0.0, _art_rect().size)
	body_texture = null
	if not defer_texture_requests:
		_request_textures()
	queue_redraw()

func _content_signature(next_slot: String, next_part: Dictionary, next_display_name: String, next_line_a: String, next_line_b: String, next_language: String = "zh") -> String:
	var size_key := "%dx%d" % [maxi(1, int(round(size.x))), maxi(1, int(round(size.y)))]
	return "%s|%s|%s|%s|%s|%s" % [
		next_slot,
		String(next_part.get("stable_key", next_part.get("name", ""))),
		next_display_name,
		next_line_a,
		next_line_b,
		size_key + "|" + next_language + "|" + PartIdentity.signature_for(next_slot, next_part, next_language),
	]

func _request_textures() -> void:
	textures_requested_signature = content_signature
	if slot_key == "" or part.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var art_rect := _art_rect()
	var next_preview := PartPreviewTextureCache.request_preview(self, slot_key, part, false, 0.0, art_rect.size)
	if next_preview != null:
		preview_texture = next_preview
	preview_request_count += 1

func ensure_textures_requested() -> bool:
	if slot_key == "" or part.is_empty():
		return false
	if textures_requested_signature == content_signature:
		return false
	_request_textures()
	queue_redraw()
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		var next_signature := _content_signature(slot_key, part, display_name, data_line_a, data_line_b, ui_language)
		if next_signature != content_signature:
			content_signature = next_signature
			_request_textures()
		queue_redraw()

func preview_cache_key() -> String:
	if slot_key == "" or part.is_empty():
		return ""
	return PartPreviewTextureCache.key_for(slot_key, part, false, 0.0, _art_rect().size)

func body_cache_key() -> String:
	return ""

func refresh_preview_texture() -> bool:
	if slot_key == "" or part.is_empty():
		return false
	var next_texture := PartPreviewTextureCache.peek_preview(slot_key, part, false, 0.0, _art_rect().size)
	if next_texture == null or next_texture == preview_texture:
		return false
	preview_texture = next_texture
	queue_redraw()
	return true

func refresh_body_texture() -> bool:
	return false

func _draw() -> void:
	redraw_count += 1
	if not visible:
		return
	var card_rect := Rect2(Vector2.ZERO, size)
	var base := Color(0.024, 0.036, 0.047, 0.96)
	if selected:
		base = Color(0.07, 0.075, 0.044, 0.98)
	draw_rect(card_rect, base, true)
	draw_rect(Rect2(Vector2(1.0, 1.0), size - Vector2(2.0, 2.0)), _slot_color().lerp(Color.WHITE, 0.28 if selected else 0.0), false, 2.0 if selected else 1.0)
	var art_rect := _art_rect()
	draw_rect(art_rect, Color(0.006, 0.012, 0.018, 0.78), true)
	if preview_texture == null:
		refresh_preview_texture()
	if preview_texture != null:
		draw_texture_rect(preview_texture, art_rect, false)
	else:
		draw_rect(art_rect.grow(-4.0), _slot_color().darkened(0.35), true)
		draw_rect(art_rect.grow(-4.0), _slot_color().lerp(Color.WHITE, 0.22), false, 1.0)
	draw_rect(art_rect, Color(0.26, 0.36, 0.46, 0.5), false, 1.0)
	_draw_size_ruler(art_rect, _thumbnail_size_scale())
	_draw_size_badge(art_rect)
	_draw_identity_overlay(art_rect)
	var data_rect := _data_rect()
	draw_rect(data_rect, Color(0.0, 0.0, 0.0, 0.58), true)
	_draw_body_fallback(_body_texture_rect())
	if selected:
		draw_circle(Vector2(size.x - 10.0, 10.0), 4.0, Color(1.0, 0.86, 0.24, 1.0))

func _art_rect() -> Rect2:
	var simple_card := data_line_a == "" and data_line_b == ""
	return Rect2(Vector2(8.0, 6.0), Vector2(size.x - 16.0, maxf(26.0, size.y * (0.56 if simple_card else 0.46))))

func _data_rect() -> Rect2:
	var art_rect := _art_rect()
	var data_y := art_rect.position.y + art_rect.size.y + 3.0
	return Rect2(Vector2(4.0, data_y), Vector2(size.x - 8.0, size.y - data_y - 4.0))

func _body_texture_rect() -> Rect2:
	var data_rect := _data_rect()
	return Rect2(data_rect.position + Vector2(3.0, 0.0), data_rect.size - Vector2(6.0, 0.0))

func _draw_body_fallback(rect: Rect2) -> void:
	var font := ThemeDB.get_fallback_font()
	var simple_card := data_line_a == "" and data_line_b == ""
	var compact := rect.size.y < 30.0 and not simple_card
	var title_size := CATALOG_CARD_SIMPLE_TITLE_FONT_SIZE if simple_card else CATALOG_CARD_TITLE_FONT_SIZE
	var line_size := 7 if compact else CATALOG_CARD_LINE_FONT_SIZE
	var title_pos := rect.position + Vector2(2.0, 15.0 if simple_card else (8.8 if compact else 11.0))
	draw_rect(rect, Color(0.0, 0.0, 0.0, CATALOG_CARD_TEXT_PLATE_ALPHA), true)
	draw_string(font, title_pos + Vector2(1.0, 1.0), _card_trim(display_name, 17 if simple_card else (15 if compact else 14)), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 4.0, title_size, Color(0.0, 0.0, 0.0, 0.82))
	draw_string(font, title_pos, _card_trim(display_name, 17 if simple_card else (15 if compact else 14)), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 4.0, title_size, Color(0.9, 0.96, 1.0, 1.0))
	if not simple_card:
		var line_a_pos := rect.position + Vector2(2.0, 16.4 if compact else 21.0)
		var line_b_pos := rect.position + Vector2(2.0, minf(23.4 if compact else 32.0, rect.size.y - 3.0))
		draw_string(font, line_a_pos + Vector2(1.0, 1.0), _card_trim(data_line_a, 16 if compact else 15), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 4.0, line_size, Color(0.0, 0.0, 0.0, 0.78))
		draw_string(font, line_a_pos, _card_trim(data_line_a, 16 if compact else 15), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 4.0, line_size, Color(0.82, 0.94, 1.0, 1.0))
		draw_string(font, line_b_pos + Vector2(1.0, 1.0), _card_trim(data_line_b, 16 if compact else 15), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 4.0, line_size, Color(0.0, 0.0, 0.0, 0.76))
		draw_string(font, line_b_pos, _card_trim(data_line_b, 16 if compact else 15), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 4.0, line_size, Color(0.78, 0.86, 0.94, 1.0))

func _card_trim(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	return value.substr(0, max(0, max_chars - 1)) + "."

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

func _thumbnail_size_scale() -> float:
	var scale := PartArt.size_scale_for(part)
	return clampf(scale / 1.82, 0.32, 1.0)

func _draw_size_ruler(rect: Rect2, scale_value: float) -> void:
	var y := rect.position.y + rect.size.y - 3.0
	var width := maxf(10.0, rect.size.x * clampf(scale_value, 0.25, 1.0))
	var start := Vector2(rect.position.x + 5.0, y)
	var end := start + Vector2(width, 0.0)
	draw_line(start, end, Color(0.86, 0.96, 1.0, 0.22), 1.0)
	draw_line(start + Vector2(0.0, -2.0), start + Vector2(0.0, 2.0), Color(0.86, 0.96, 1.0, 0.18), 1.0)
	draw_line(end + Vector2(0.0, -2.0), end + Vector2(0.0, 2.0), Color(0.86, 0.96, 1.0, 0.18), 1.0)

func _draw_size_badge(rect: Rect2) -> void:
	var tier := PartArt.normalized_size_tier(part)
	if tier == "":
		return
	var font := ThemeDB.get_fallback_font()
	var badge_rect := Rect2(rect.position + Vector2(rect.size.x - 24.0, 3.0), Vector2(20.0, 10.0))
	draw_rect(badge_rect, Color(0.0, 0.0, 0.0, 0.34), true)
	draw_rect(badge_rect, Color(0.86, 0.96, 1.0, 0.2), false, 1.0)
	draw_string(font, badge_rect.position + Vector2(3.0, 8.0), tier.substr(0, 2), HORIZONTAL_ALIGNMENT_LEFT, badge_rect.size.x, 7, Color(0.9, 0.98, 1.0, 0.82))

func _draw_identity_overlay(rect: Rect2) -> void:
	if part.is_empty():
		return
	var font := ThemeDB.get_fallback_font()
	var identity := PartIdentity.identity_for(slot_key, part, ui_language)
	var accent: Color = identity.get("color", _slot_color())
	var code := String(identity.get("code", ""))
	var glyph := String(identity.get("glyph", ""))
	var tags: Array = identity.get("tags", [])
	var chip_rect := Rect2(rect.position + Vector2(3.0, 3.0), Vector2(minf(rect.size.x - 31.0, 69.0), 12.0))
	_draw_identity_chip(font, chip_rect, code, accent, 7, 0.92)
	if glyph != "":
		var glyph_rect := Rect2(rect.position + Vector2(rect.size.x - 25.0, rect.size.y - 18.0), Vector2(21.0, 13.0))
		draw_rect(glyph_rect, Color(0.0, 0.0, 0.0, 0.42), true)
		draw_rect(glyph_rect, accent.lerp(Color.WHITE, 0.18), false, 1.0)
		draw_string(font, glyph_rect.position + Vector2(2.0, 10.0), _card_trim(glyph, 4), HORIZONTAL_ALIGNMENT_CENTER, glyph_rect.size.x - 4.0, 7, Color(0.92, 0.98, 1.0, 0.9))
	var tag_y := rect.position.y + rect.size.y - 17.0
	var x := rect.position.x + 3.0
	for i in range(mini(tags.size(), 2)):
		var tag := _card_trim(String(tags[i]), 5)
		var tag_w := clampf(float(tag.length()) * 6.0 + 10.0, 22.0, rect.size.x * 0.44)
		var tag_rect := Rect2(Vector2(x, tag_y), Vector2(tag_w, 11.0))
		_draw_identity_chip(font, tag_rect, tag, accent, 7, 0.72)
		x += tag_w + 3.0

func _draw_identity_chip(font: Font, rect: Rect2, text_value: String, accent: Color, font_size: int, alpha: float) -> void:
	if rect.size.x <= 4.0 or text_value == "":
		return
	var bg := accent.darkened(0.58)
	bg.a = 0.72 * alpha
	var border := accent.lerp(Color.WHITE, 0.28)
	border.a = 0.58 * alpha
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.5 * alpha), true)
	draw_rect(rect.grow(-1.0), bg, true)
	draw_rect(rect, border, false, 1.0)
	draw_string(font, rect.position + Vector2(4.0, rect.size.y - 3.0), _card_trim(text_value, maxi(3, int(rect.size.x / 5.8))), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 7.0, font_size, Color(0.93, 0.99, 1.0, 0.96 * alpha))
