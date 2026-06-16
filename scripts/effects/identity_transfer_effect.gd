class_name IdentityTransferEffect
extends Node2D

var source_unit
var target_unit
var payloads: Array = []
var progress := 0.0
var duration := 0.86
var finished := false
var callback: Callable

func setup(source, target, payload_list: Array, finish_callback: Callable) -> void:
	source_unit = source
	target_unit = target
	payloads = payload_list.duplicate(true)
	callback = finish_callback
	progress = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if finished:
		return
	progress += delta / duration
	if progress >= 1.0:
		finished = true
		if callback.is_valid():
			callback.call()
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if source_unit == null or target_unit == null or not is_instance_valid(source_unit) or not is_instance_valid(target_unit):
		return
	var start := to_local(source_unit.global_position)
	var finish := to_local(target_unit.global_position)
	var dir := finish - start
	var normal := Vector2(-dir.y, dir.x).normalized() if dir.length() > 0.01 else Vector2.UP
	for i in range(payloads.size()):
		var payload: String = String(payloads[i])
		var t := clampf(progress - float(i) * 0.08, 0.0, 1.0)
		var arc := sin(t * PI) * (56.0 + float(i) * 18.0)
		var pos := start.lerp(finish, t) + normal * arc
		var color := _payload_color(payload)
		draw_line(start.lerp(finish, maxf(0.0, t - 0.16)), pos, Color(color.r, color.g, color.b, 0.26), 2.0)
		_draw_payload(payload, pos, color, 1.0 + sin(progress * TAU * 3.0 + float(i)) * 0.12)

func _payload_color(payload: String) -> Color:
	match payload:
		"soul":
			return Color(1.0, 0.86, 0.24, 1.0)
		"code":
			return Color(0.34, 0.9, 1.0, 1.0)
		"ether":
			return Color(0.78, 0.42, 1.0, 1.0)
	return Color.WHITE

func _draw_payload(payload: String, pos: Vector2, color: Color, scale: float) -> void:
	if payload == "soul":
		draw_circle(pos, 12.0 * scale, Color(color.r, color.g, color.b, 0.28))
		draw_circle(pos + Vector2(0.0, -4.0) * scale, 7.0 * scale, color)
		draw_circle(pos + Vector2(-5.0, -9.0) * scale, 4.0 * scale, color.lerp(Color.WHITE, 0.35))
		draw_line(pos + Vector2(0.0, 4.0) * scale, pos + Vector2(0.0, 17.0) * scale, color, 3.0 * scale)
	elif payload == "code":
		var pts := PackedVector2Array()
		for i in range(10):
			var radius := 15.0 if i % 2 == 0 else 6.5
			var angle := -PI * 0.5 + TAU * float(i) / 10.0
			pts.append(pos + Vector2(cos(angle), sin(angle)) * radius * scale)
		draw_colored_polygon(pts, color)
		draw_circle(pos, 4.0 * scale, Color.WHITE)
	elif payload == "ether":
		draw_arc(pos, 18.0 * scale, 0.0, TAU, 36, color, 3.0 * scale)
		draw_arc(pos, 10.0 * scale, PI * 0.2, PI * 1.7, 26, color.lerp(Color.WHITE, 0.3), 2.0 * scale)
		draw_line(pos + Vector2(-18.0, 0.0) * scale, pos + Vector2(18.0, 0.0) * scale, color, 2.0 * scale)
