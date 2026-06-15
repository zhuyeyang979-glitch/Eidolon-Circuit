extends Control
class_name BattleAttackFeedbackView

const SLOT_COUNT := 6

var model: Dictionary = {}
var last_signature := ""
var flash_present := false


func _ready() -> void:
	set_process(true)


func set_model(next_model: Dictionary) -> void:
	var signature := str(next_model)
	if signature == last_signature:
		return
	last_signature = signature
	model = next_model.duplicate(true)
	flash_present = _has_flash()
	queue_redraw()


func clear_model() -> void:
	last_signature = ""
	model = {}
	flash_present = false
	queue_redraw()


func slot_count() -> int:
	return Array(model.get("slots", [])).size()


func debug_snapshot() -> Dictionary:
	return model.duplicate(true)


func _process(_delta: float) -> void:
	if visible and flash_present:
		queue_redraw()


func _draw() -> void:
	if not visible or model.is_empty():
		return
	var slots := Array(model.get("slots", []))
	if slots.is_empty():
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.006, 0.012, 0.018, 0.50), true)
	draw_rect(rect, Color(0.32, 0.92, 1.0, 0.28), false, 1.1)
	var font := ThemeDB.get_fallback_font()
	var title := String(model.get("title", "ATTACK GROUPS"))
	draw_string(font, Vector2(10.0, 13.0), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20.0, 10, Color(0.78, 0.94, 1.0, 0.78))
	var usable_rect := Rect2(Vector2(8.0, 20.0), Vector2(size.x - 16.0, size.y - 28.0))
	var slot_w := usable_rect.size.x / float(SLOT_COUNT)
	for i in range(SLOT_COUNT):
		var raw_slot = slots[i] if i < slots.size() else {}
		var slot: Dictionary = raw_slot if raw_slot is Dictionary else {}
		_draw_slot(font, Rect2(usable_rect.position + Vector2(float(i) * slot_w, 0.0), Vector2(slot_w - 4.0, usable_rect.size.y)), slot, i)


func _draw_slot(font: Font, rect: Rect2, slot: Dictionary, fallback_index: int) -> void:
	var status := String(slot.get("status", "empty")).to_lower()
	var color := _status_color(status, float(slot.get("severity", 0.0)))
	var flash := clampf(float(slot.get("flash_ratio", 0.0)), 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.018 + float(fallback_index) * 0.7)
	var panel_alpha := 0.24 + flash * (0.16 + pulse * 0.12)
	draw_rect(rect, Color(0.02, 0.03, 0.04, panel_alpha), true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.28 + flash * 0.45), false, 1.2 + flash * 1.4)
	if flash > 0.01:
		var glow_rect := rect.grow(2.0 + flash * 2.0)
		draw_rect(glow_rect, Color(color.r, color.g, color.b, flash * 0.08), true)

	var key_text := String(slot.get("key_label", "?"))
	var number_text := "#%d" % int(slot.get("group", fallback_index + 1))
	var name_text := _compact_label(String(slot.get("name", "-")), 9)
	var state_text := _compact_label(String(slot.get("status_label", status.to_upper())), 5)
	draw_string(font, rect.position + Vector2(6.0, 13.0), key_text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.45, 15, Color(0.95, 1.0, 1.0, 0.96))
	draw_string(font, rect.position + Vector2(rect.size.x - 32.0, 12.0), number_text, HORIZONTAL_ALIGNMENT_RIGHT, 28.0, 9, Color(0.78, 0.9, 0.96, 0.82))
	draw_string(font, rect.position + Vector2(6.0, 30.0), name_text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12.0, 9, Color(0.74, 0.84, 0.9, 0.88))
	draw_string(font, rect.position + Vector2(6.0, 43.0), state_text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12.0, 10, Color(color.r, color.g, color.b, 0.95))

	var bar_y := rect.end.y - 9.0
	var heat_ratio := clampf(float(slot.get("heat_ratio", 0.0)), 0.0, 1.0)
	var cooldown_ratio := clampf(float(slot.get("cooldown_ratio", 0.0)), 0.0, 1.0)
	var readiness_ratio := clampf(1.0 - cooldown_ratio, 0.0, 1.0)
	var bar_rect := Rect2(Vector2(rect.position.x + 6.0, bar_y), Vector2(rect.size.x - 12.0, 3.0))
	draw_rect(bar_rect, Color(0.64, 0.78, 0.86, 0.16), true)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * readiness_ratio, bar_rect.size.y)), Color(color.r, color.g, color.b, 0.56), true)
	if heat_ratio > 0.01:
		draw_rect(Rect2(Vector2(bar_rect.position.x, bar_rect.position.y + 4.0), Vector2(bar_rect.size.x * heat_ratio, 2.0)), Color(1.0, 0.24, 0.14, 0.64), true)
	var ammo_capacity := int(slot.get("ammo_capacity", 0))
	if ammo_capacity > 0:
		var ammo_current := int(slot.get("ammo_current", 0))
		var ammo_ratio := clampf(float(ammo_current) / float(maxi(1, ammo_capacity)), 0.0, 1.0)
		var ammo_rect := Rect2(Vector2(bar_rect.position.x, bar_rect.position.y - 4.0), Vector2(bar_rect.size.x * ammo_ratio, 2.0))
		draw_rect(ammo_rect, _ammo_color(String(slot.get("ammo_kind", "")), 0.72), true)


func _status_color(status: String, severity: float = 0.0) -> Color:
	match status:
		"fire":
			return Color(1.0, 0.78, 0.22, 1.0)
		"aim":
			return Color(0.28, 0.92, 1.0, 1.0)
		"lock":
			return Color(1.0, 0.92, 0.34, 1.0)
		"window":
			return Color(0.72, 0.62, 1.0, 1.0)
		"cool":
			return Color(1.0, 0.46, 0.22, 1.0)
		"heat":
			return Color(1.0, 0.22, 0.12, 1.0)
		"block", "empty", "sever":
			return Color(1.0, 0.22, 0.34, 1.0)
	var ready := Color(0.42, 1.0, 0.62, 1.0)
	if severity > 0.01:
		return ready.lerp(Color(1.0, 0.72, 0.22, 1.0), clampf(severity, 0.0, 1.0))
	return ready


func _ammo_color(ammo_kind: String, alpha: float) -> Color:
	match ammo_kind:
		"bullet":
			return Color(1.0, 0.72, 0.28, alpha)
		"laser":
			return Color(0.18, 0.92, 1.0, alpha)
		"chemical":
			return Color(0.34, 1.0, 0.42, alpha)
		"explosive":
			return Color(1.0, 0.34, 0.16, alpha)
		"web":
			return Color(0.9, 0.95, 1.0, alpha)
	return Color(0.86, 0.92, 1.0, alpha)


func _compact_label(value: String, max_chars: int) -> String:
	var cleaned := value.strip_edges()
	if cleaned.length() <= max_chars:
		return cleaned
	return cleaned.substr(0, maxi(1, max_chars - 1)) + "."


func _has_flash() -> bool:
	for raw_slot in Array(model.get("slots", [])):
		if raw_slot is Dictionary and float(Dictionary(raw_slot).get("flash_ratio", 0.0)) > 0.01:
			return true
	return false
