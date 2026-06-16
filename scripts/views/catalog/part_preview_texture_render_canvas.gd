class_name PartPreviewTextureRenderCanvas
extends Control

const AssemblyBoardRenderer = preload("res://scripts/assembly_board_renderer.gd")

var slot_key := ""
var part := {}
var selected := false
var pulse := 0.0

func configure(next_slot: String, next_part: Dictionary, next_selected: bool, next_pulse: float, next_size: Vector2) -> void:
	slot_key = next_slot
	part = next_part
	selected = next_selected
	pulse = next_pulse
	size = next_size
	queue_redraw()

func _draw() -> void:
	if slot_key == "" or part.is_empty():
		return
	if not AssemblyBoardRenderer.draw_part_preview(self, Rect2(Vector2.ZERO, size), slot_key, part, selected, pulse):
		draw_rect(Rect2(Vector2.ZERO, size).grow(-4.0), Color(0.08, 0.12, 0.16, 0.8), true)
		draw_rect(Rect2(Vector2.ZERO, size).grow(-4.0), Color(0.48, 0.66, 0.78, 0.45), false, 1.2)
