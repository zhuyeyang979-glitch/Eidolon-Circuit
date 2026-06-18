class_name PartPreviewIconView
extends Control

const PartArt = preload("res://scripts/part_art.gd")
const PartPreviewTextureCache = preload("res://scripts/views/catalog/part_preview_texture_cache.gd")

var slot_key := ""
var part := {}
var selected := false
var pulse := 0.0
var last_preview_signature := ""
var last_preview_semantic_signature := ""
var last_preview_identity_signature := ""
var set_preview_call_count := 0
var set_preview_apply_count := 0
var set_preview_noop_count := 0
var renderer_draw_count := 0
var texture_cache_hit_count := 0
var texture_cache_miss_count := 0
var preview_texture: Texture2D

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = true

func set_preview(next_slot: String, next_part: Dictionary, next_selected: bool, next_pulse: float = 0.0, explicit_signature: String = "") -> void:
	set_preview_call_count += 1
	var size_key := "%dx%d" % [maxi(1, int(round(size.x))), maxi(1, int(round(size.y)))]
	var semantic_signature := "%s|%s" % [_preview_signature(next_slot, next_part, next_selected, next_pulse), size_key]
	# Selection is rendered by the card frame; ignoring it here keeps catalog
	# paging/selection refreshes from invalidating the expensive preview art.
	var identity_signature := "%s|%s|%s" % [next_slot, String(next_part.get("name", "")), PartArt.normalized_size_tier(next_part)]
	var signature := explicit_signature if explicit_signature != "" else semantic_signature
	if signature == last_preview_signature or semantic_signature == last_preview_semantic_signature or identity_signature == last_preview_identity_signature:
		set_preview_noop_count += 1
		last_preview_signature = signature
		last_preview_semantic_signature = semantic_signature
		last_preview_identity_signature = identity_signature
		return
	last_preview_signature = signature
	last_preview_semantic_signature = semantic_signature
	last_preview_identity_signature = identity_signature
	set_preview_apply_count += 1
	slot_key = next_slot
	part = next_part
	selected = next_selected
	pulse = next_pulse
	preview_texture = PartPreviewTextureCache.get_or_create(self, slot_key, part, selected, pulse, size)
	texture_cache_hit_count = PartPreviewTextureCache.hit_count
	texture_cache_miss_count = PartPreviewTextureCache.miss_count
	queue_redraw()

func clear_preview() -> void:
	if last_preview_signature == "" and part.is_empty():
		return
	last_preview_signature = ""
	last_preview_semantic_signature = ""
	last_preview_identity_signature = ""
	part = {}
	slot_key = ""
	preview_texture = null
	queue_redraw()

func _draw() -> void:
	if not visible or part.is_empty() or slot_key == "":
		return
	if preview_texture == null:
		preview_texture = PartPreviewTextureCache.peek_preview(slot_key, part, selected, pulse, size)
	if preview_texture != null:
		draw_texture_rect(preview_texture, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size).grow(-4.0), Color(0.08, 0.12, 0.16, 0.8), true)
		draw_rect(Rect2(Vector2.ZERO, size).grow(-4.0), Color(0.48, 0.66, 0.78, 0.45), false, 1.2)
	_draw_size_badge(Rect2(Vector2.ZERO, size))

func _draw_size_badge(rect: Rect2) -> void:
	var tier := PartArt.normalized_size_tier(part)
	if tier == "":
		return
	var font := ThemeDB.get_fallback_font()
	var badge_rect := Rect2(rect.position + Vector2(rect.size.x - 34.0, 6.0), Vector2(28.0, 14.0))
	draw_rect(badge_rect, Color(0.0, 0.0, 0.0, 0.52), true)
	draw_rect(badge_rect, Color(0.86, 0.96, 1.0, 0.3), false, 1.0)
	draw_string(font, badge_rect.position + Vector2(4.0, 10.0), tier.substr(0, 2), HORIZONTAL_ALIGNMENT_LEFT, badge_rect.size.x, 9, Color(0.9, 0.98, 1.0, 0.92))

func _preview_signature(next_slot: String, next_part: Dictionary, next_selected: bool, next_pulse: float) -> String:
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		next_slot,
		String(next_part.get("name", "")),
		PartArt.normalized_size_tier(next_part),
		String(next_part.get("shape", "")),
		String(next_part.get("material_visual", next_part.get("material_class", ""))),
		String(next_part.get("damage_type", next_part.get("projectile_damage_type", ""))),
		String(next_part.get("weapon_family", "")),
		String(next_part.get("gun_kind", "")),
		str(bool(next_part.get("terminal_weapon", false))),
		str(bool(next_part.get("is_torso", false))),
		str(next_selected),
		str(snappedf(next_pulse, 0.02)),
	]
