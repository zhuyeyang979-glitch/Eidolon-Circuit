class_name AssemblyBoardView
extends Control

const PartArt = preload("res://scripts/part_art.gd")
const AssemblyBoardRenderer = preload("res://scripts/assembly_board_renderer.gd")
const AssemblyTemplateOverlayRenderer = preload("res://scripts/views/editor/assembly_template_overlay_renderer.gd")

const TOPOLOGY_BOARD_PHYSICAL_UNITS = 2.0
const EDITOR_BOARD_ZOOM_MIN = 0.35
const EDITOR_BOARD_ZOOM_MAX = 3.0
const BARRIER_BLUEPRINT_WIDTH = 7.2
const BARRIER_BLUEPRINT_HEIGHT = 5.2

class AssemblyBoardRenderLayer:
	extends Control

	var view
	var layer_kind := ""
	var layer_signature := ""
	var redraw_count := 0

	func configure(next_view, next_kind: String) -> void:
		view = next_view
		layer_kind = next_kind
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func submit(next_signature: String) -> bool:
		if next_signature == layer_signature:
			return false
		layer_signature = next_signature
		queue_redraw()
		return true

	func _draw() -> void:
		redraw_count += 1
		if view == null:
			return
		match layer_kind:
			"selection":
				view._retained_draw_custom_selection(self)
			"hint":
				view._retained_draw_custom_hint(self)


class AssemblyBoardRenderComponentItem:
	extends Control

	var view
	var node_index := -1
	var item_signature := ""
	var placeholder_mode := false
	var redraw_count := 0

	func configure(next_view, next_node_index: int) -> void:
		view = next_view
		node_index = next_node_index
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func submit(next_signature: String) -> bool:
		if next_signature == item_signature:
			return false
		item_signature = next_signature
		placeholder_mode = false
		queue_redraw()
		return true

	func submit_placeholder(next_signature: String) -> bool:
		if next_signature == item_signature and placeholder_mode:
			return false
		item_signature = next_signature
		placeholder_mode = true
		queue_redraw()
		return true

	func _draw() -> void:
		redraw_count += 1
		if view == null:
			return
		if placeholder_mode:
			view._retained_draw_custom_component_placeholder(self, node_index)
			return
		view._retained_draw_custom_component(self, node_index)


class AssemblyBoardRenderItem:
	extends Control

	var view
	var item_kind := ""
	var item_key := ""
	var payload := {}
	var item_signature := ""
	var redraw_count := 0

	func configure(next_view, next_kind: String, next_key: String) -> void:
		view = next_view
		item_kind = next_kind
		item_key = next_key
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func submit(next_payload: Dictionary, next_signature: String) -> bool:
		if next_signature == item_signature:
			return false
		payload = next_payload.duplicate(false)
		item_signature = next_signature
		queue_redraw()
		return true

	func _draw() -> void:
		redraw_count += 1
		if view == null:
			return
		view._retained_draw_custom_item(self, item_kind, payload)


signal part_dropped(slot_key: String, part_index: int, local_position: Vector2)

const CUSTOM_BOARD_MARGIN = 54.0
const BARRIER_BOARD_COLUMNS = 10
const BARRIER_BOARD_ROWS = 5

var board_mode := "hero"
var selected_part := "left_claw"
var board_snapshot := {}
var illegal_parts := {}
var snap_part := ""
var snap_amount := 0.0
var ui_language := "zh"
var motion_phase := 0.0
var last_board_signature := ""
var assembly_template_overlay_renderer := AssemblyTemplateOverlayRenderer.new()
var set_board_call_count := 0
var set_board_apply_count := 0
var set_board_noop_count := 0
var set_board_shallow_copy_count := 0
var retained_render_layer: Control
var retained_edge_layer: AssemblyBoardRenderLayer
var retained_component_layer: Control
var retained_socket_layer: AssemblyBoardRenderLayer
var retained_overlay_layer: AssemblyBoardRenderLayer
var retained_selection_layer: AssemblyBoardRenderLayer
var retained_hint_layer: AssemblyBoardRenderLayer
var retained_component_items := {}
var retained_edge_items := {}
var retained_socket_items := {}
var retained_candidate_socket_items := {}
var retained_material_overlay_items := {}
var retained_binding_group_items := {}
var retained_warning_items := {}
var retained_sweep_arc_items := {}
var retained_render_submit_count := 0
var retained_layer_noop_count := 0
var retained_component_update_count := 0
var retained_component_noop_count := 0
var retained_component_remove_count := 0
var retained_component_defer_count := 0
var retained_component_deferred_flush_count := 0
var retained_component_placeholder_count := 0
var retained_component_body_submit_count := 0
var retained_deferred_component_indices: Array = []
var retained_edge_update_count := 0
var retained_edge_noop_count := 0
var retained_edge_remove_count := 0
var retained_socket_update_count := 0
var retained_socket_noop_count := 0
var retained_socket_remove_count := 0
var retained_overlay_update_count := 0
var retained_overlay_noop_count := 0
var retained_overlay_remove_count := 0
var retained_full_draw_fallback_count := 0
var root_redraw_request_count := 0
var root_draw_count := 0
var custom_retained_root_redraw_skip_count := 0
var retained_last_size := Vector2.ZERO
var retained_view_signature := ""
var retained_view_invalidation_count := 0

func set_board(next_snapshot: Dictionary, next_selected: String, next_illegal: Dictionary, next_snap_part: String, next_snap_amount: float, next_mode: String = "hero", next_language: String = "zh", next_motion_phase: float = 0.0, next_revision_key: String = "") -> void:
	set_board_call_count += 1
	var signature := _board_signature(next_snapshot, next_selected, next_illegal, next_snap_part, next_snap_amount, next_mode, next_language, next_motion_phase, next_revision_key)
	if signature == last_board_signature:
		set_board_noop_count += 1
		return
	last_board_signature = signature
	set_board_apply_count += 1
	board_mode = next_mode
	board_snapshot = next_snapshot.duplicate(false)
	set_board_shallow_copy_count += 1
	selected_part = next_selected
	illegal_parts = next_illegal.duplicate(false)
	snap_part = next_snap_part
	snap_amount = next_snap_amount
	ui_language = next_language
	motion_phase = next_motion_phase
	if board_mode == "custom":
		_ensure_retained_render_layer()
		if retained_render_layer != null:
			retained_render_layer.visible = true
		_submit_custom_board_to_retained_layers()
	else:
		_set_retained_render_visible(false)
	if board_mode == "custom" and retained_render_layer != null:
		custom_retained_root_redraw_skip_count += 1
	else:
		root_redraw_request_count += 1
		queue_redraw()

func apply_board_diff(diff: Dictionary, revision_key: String) -> void:
	var next_snapshot: Dictionary = board_snapshot
	if diff.has("snapshot"):
		next_snapshot = Dictionary(diff.get("snapshot", {}))
	if diff.has("nodes"):
		next_snapshot["nodes"] = diff.get("nodes", [])
	if diff.has("edges"):
		next_snapshot["edges"] = diff.get("edges", [])
	if diff.has("edge_states"):
		next_snapshot["edge_states"] = diff.get("edge_states", {})
	if diff.has("socket_markers"):
		next_snapshot["socket_markers"] = diff.get("socket_markers", [])
	if diff.has("material_highlights"):
		next_snapshot["material_highlights"] = diff.get("material_highlights", {})
	var next_selected := String(diff.get("selected_part", selected_part))
	var next_illegal: Dictionary = diff.get("illegal_parts", illegal_parts)
	var next_snap_part := String(diff.get("snap_part", snap_part))
	var next_snap_amount := float(diff.get("snap_amount", snap_amount))
	var next_mode := String(diff.get("mode", board_mode))
	var next_language := String(diff.get("language", ui_language))
	var next_motion_phase := float(diff.get("motion_phase", motion_phase))
	if next_mode == "custom" and bool(diff.get("component_only", false)) and diff.has("changed_nodes"):
		_ensure_retained_render_layer()
	if next_mode == "custom" and retained_render_layer != null and bool(diff.get("component_only", false)) and diff.has("changed_nodes"):
		last_board_signature = revision_key
		board_snapshot = next_snapshot.duplicate(false)
		selected_part = next_selected
		illegal_parts = next_illegal.duplicate(false)
		snap_part = next_snap_part
		snap_amount = next_snap_amount
		board_mode = next_mode
		ui_language = next_language
		motion_phase = next_motion_phase
		var changed := Array(diff.get("changed_nodes", []))
		if bool(diff.get("defer_component_draw", false)):
			_defer_retained_components(changed)
		else:
			_submit_retained_components_for_indices(changed)
			if bool(diff.get("update_edge_socket_items", false)):
				_submit_retained_edge_items(false)
				_submit_retained_socket_items(false)
				_submit_retained_overlay_items(false)
			_submit_retained_layer(retained_selection_layer, "selection|" + _retained_selection_signature())
			_submit_retained_layer(retained_hint_layer, "hint|" + revision_key + "|" + ui_language + "|tpl:" + _assembly_template_signature())
		custom_retained_root_redraw_skip_count += 1
		return
	set_board(next_snapshot, next_selected, next_illegal, next_snap_part, next_snap_amount, next_mode, next_language, next_motion_phase, revision_key)

func apply_component_node_diff(node_index: int, node: Dictionary, revision_key: String, defer_draw: bool = true) -> void:
	if node_index < 0 or node.is_empty():
		return
	_ensure_retained_render_layer()
	board_mode = "custom"
	if retained_render_layer != null:
		retained_render_layer.visible = true
	var nodes: Array = Array(board_snapshot.get("nodes", [])).duplicate(false)
	if nodes.size() <= node_index:
		nodes.resize(node_index + 1)
	nodes[node_index] = node
	board_snapshot["nodes"] = nodes
	board_snapshot["revision_key"] = revision_key
	last_board_signature = revision_key
	if defer_draw:
		append_component_placeholder(node_index, revision_key)
	else:
		_submit_retained_components_for_indices([node_index])
	custom_retained_root_redraw_skip_count += 1

func append_component_placeholder(node_index: int, revision_key: String = "") -> void:
	_ensure_retained_render_layer()
	var nodes: Array = board_snapshot.get("nodes", [])
	if node_index < 0 or node_index >= nodes.size():
		return
	var item: AssemblyBoardRenderComponentItem = retained_component_items.get(node_index, null)
	if item == null:
		item = AssemblyBoardRenderComponentItem.new()
		item.name = "Component_%d" % node_index
		item.configure(self, node_index)
		retained_component_items[node_index] = item
		if retained_component_layer != null:
			retained_component_layer.add_child(item)
	item.position = Vector2.ZERO
	item.size = size
	var signature := "placeholder|%s|%d|%s" % [revision_key, node_index, _retained_component_signature(node_index)]
	if item.submit_placeholder(signature):
		retained_component_placeholder_count += 1
	else:
		retained_component_noop_count += 1
	_defer_retained_components([node_index])

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_resize_retained_render_layer()
		if board_mode == "custom":
			_submit_custom_board_to_retained_layers(true)

func _board_signature(next_snapshot: Dictionary, next_selected: String, next_illegal: Dictionary, next_snap_part: String, next_snap_amount: float, next_mode: String, next_language: String, next_motion_phase: float, next_revision_key: String = "") -> String:
	var snap_key := snappedf(next_snap_amount, 0.01)
	var phase_key := snappedf(next_motion_phase, 0.02) if snap_key > 0.0 else 0.0
	var revision_key := next_revision_key
	if revision_key == "":
		revision_key = String(next_snapshot.get("revision_key", ""))
	if revision_key == "":
		var nodes: Array = Array(next_snapshot.get("nodes", []))
		var edges: Array = Array(next_snapshot.get("edges", []))
		revision_key = "%d:%d:%s:%s:%s" % [
			nodes.size(),
			edges.size(),
			str(next_snapshot.get("selected", "")),
			str(next_snapshot.get("view_zoom", "")),
			str(next_snapshot.get("view_offset", "")),
		]
	return "%s|%s|%s|%s|%s|%s|%s|%s" % [next_mode, next_language, next_selected, next_snap_part, str(snap_key), str(phase_key), _illegal_signature(next_illegal), revision_key]

func _illegal_signature(next_illegal: Dictionary) -> String:
	if next_illegal.is_empty():
		return ""
	var keys := next_illegal.keys()
	keys.sort()
	var bits: Array = []
	for i in range(mini(keys.size(), 24)):
		var key: Variant = keys[i]
		bits.append("%s=%s" % [String(key), str(next_illegal.get(key))])
	return "|".join(bits)

func _can_drop_data(_at_position: Vector2, data) -> bool:
	return data is Dictionary and String(Dictionary(data).get("kind", "")) == "editor_catalog_part"

func _drop_data(at_position: Vector2, data) -> void:
	if not (data is Dictionary):
		return
	var payload := Dictionary(data)
	part_dropped.emit(String(payload.get("slot", "")), int(payload.get("index", -1)), at_position)

func _board_is_zh() -> bool:
	return ui_language == "zh"

func _ensure_retained_render_layer() -> void:
	if retained_render_layer == null:
		retained_render_layer = Control.new()
		retained_render_layer.name = "AssemblyBoardRenderLayer"
		retained_render_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(retained_render_layer)
		retained_edge_layer = _make_retained_layer("Edges", "edges")
		retained_component_layer = Control.new()
		retained_component_layer.name = "Components"
		retained_component_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		retained_render_layer.add_child(retained_component_layer)
		retained_socket_layer = _make_retained_layer("Sockets", "sockets")
		retained_overlay_layer = _make_retained_layer("Overlays", "overlays")
		retained_selection_layer = _make_retained_layer("Selection", "selection")
		retained_hint_layer = _make_retained_layer("Hint", "hint")
	_resize_retained_render_layer()

func _make_retained_layer(node_name: String, kind: String) -> AssemblyBoardRenderLayer:
	var layer := AssemblyBoardRenderLayer.new()
	layer.name = node_name
	layer.configure(self, kind)
	retained_render_layer.add_child(layer)
	return layer

func _resize_retained_render_layer() -> void:
	if retained_render_layer == null:
		return
	retained_last_size = size
	retained_render_layer.position = Vector2.ZERO
	retained_render_layer.size = size
	for child in retained_render_layer.get_children():
		if child is Control:
			var control: Control = child
			control.position = Vector2.ZERO
			control.size = size

func _retained_view_signature_for(snapshot: Dictionary, mode: String) -> String:
	var offset_value = snapshot.get("view_offset", Vector2.ZERO)
	var offset: Vector2 = offset_value if offset_value is Vector2 else Vector2.ZERO
	return "%s|z:%s|o:%s|s:%s" % [
		mode,
		str(snappedf(float(snapshot.get("view_zoom", 1.0)), 0.001)),
		_retained_vec_key(offset),
		_retained_vec_key(size),
	]

func _retained_view_signature_current() -> String:
	return _retained_view_signature_for(board_snapshot, board_mode)

func _invalidate_retained_item_pool(pool: Dictionary) -> void:
	for raw_item in pool.values():
		if raw_item is AssemblyBoardRenderItem:
			var item: AssemblyBoardRenderItem = raw_item
			item.item_signature = ""

func _invalidate_retained_view_transform() -> void:
	retained_view_invalidation_count += 1
	for layer in [retained_edge_layer, retained_socket_layer, retained_overlay_layer, retained_selection_layer, retained_hint_layer]:
		if layer is AssemblyBoardRenderLayer:
			var render_layer: AssemblyBoardRenderLayer = layer
			render_layer.layer_signature = ""
	for raw_item in retained_component_items.values():
		if raw_item is AssemblyBoardRenderComponentItem:
			var component_item: AssemblyBoardRenderComponentItem = raw_item
			component_item.item_signature = ""
	_invalidate_retained_item_pool(retained_edge_items)
	_invalidate_retained_item_pool(retained_socket_items)
	_invalidate_retained_item_pool(retained_candidate_socket_items)
	_invalidate_retained_item_pool(retained_material_overlay_items)
	_invalidate_retained_item_pool(retained_binding_group_items)
	_invalidate_retained_item_pool(retained_warning_items)
	_invalidate_retained_item_pool(retained_sweep_arc_items)

func _sync_retained_view_signature() -> bool:
	var next_signature := _retained_view_signature_current()
	if next_signature == retained_view_signature:
		return false
	retained_view_signature = next_signature
	_invalidate_retained_view_transform()
	return true

func _set_retained_render_visible(next_visible: bool) -> void:
	if retained_render_layer != null:
		retained_render_layer.visible = next_visible

func _submit_retained_layer(layer: AssemblyBoardRenderLayer, signature: String) -> void:
	if layer == null:
		return
	if layer.submit(signature):
		retained_render_submit_count += 1
	else:
		retained_layer_noop_count += 1

func _submit_custom_board_to_retained_layers(force_layers: bool = false) -> void:
	if board_mode != "custom":
		return
	_ensure_retained_render_layer()
	if retained_render_layer == null:
		return
	retained_render_layer.visible = true
	_resize_retained_render_layer()
	var view_changed := _sync_retained_view_signature()
	if view_changed:
		force_layers = true
	var base := "%s|%s|%s|%s" % [last_board_signature, _retained_view_signature_current(), _retained_vec_key(size), "force" if force_layers else ""]
	_submit_retained_edge_items(force_layers)
	_submit_retained_socket_items(force_layers)
	_submit_retained_overlay_items(force_layers)
	_submit_retained_layer(retained_selection_layer, "selection|" + _retained_selection_signature())
	_submit_retained_layer(retained_hint_layer, "hint|" + base + "|" + ui_language + "|tpl:" + _assembly_template_signature())
	_submit_retained_components(force_layers)

func _retained_item_parent_for_kind(kind: String) -> Control:
	match kind:
		"edge":
			return retained_edge_layer
		"socket":
			return retained_socket_layer
		"candidate", "material_overlay", "binding_group", "warning", "sweep":
			return retained_overlay_layer
	return retained_render_layer

func _submit_retained_item(pool: Dictionary, kind: String, key: String, payload: Dictionary, signature: String, force_item: bool = false) -> bool:
	var item: AssemblyBoardRenderItem = pool.get(key, null)
	if item == null:
		item = AssemblyBoardRenderItem.new()
		item.name = "%s_%s" % [kind.capitalize(), key.replace(":", "_").replace("/", "_")]
		item.configure(self, kind, key)
		pool[key] = item
		var parent := _retained_item_parent_for_kind(kind)
		if parent != null:
			parent.add_child(item)
		force_item = true
	item.position = Vector2.ZERO
	item.size = size
	if force_item:
		item.item_signature = ""
	return item.submit(payload, signature)

func _prune_retained_item_pool(pool: Dictionary, live: Dictionary) -> int:
	var removed := 0
	for raw_key in pool.keys():
		var key := String(raw_key)
		if live.has(key):
			continue
		var item: AssemblyBoardRenderItem = pool[key]
		if item != null:
			item.queue_free()
		pool.erase(key)
		removed += 1
	return removed

func _submit_retained_edge_items(force_items: bool = false) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var edges: Array = board_snapshot.get("edges", [])
	var edge_states: Dictionary = board_snapshot.get("edge_states", {})
	var live := {}
	for i in range(edges.size()):
		var edge = edges[i]
		var a := _edge_node_a(edge)
		var b := _edge_node_b(edge)
		if a < 0 or b < 0 or a >= nodes.size() or b >= nodes.size():
			continue
		var key := _edge_key(a, b) + ":" + _edge_socket_for_node(edge, a) + ":" + _edge_socket_for_node(edge, b)
		live[key] = true
		var state: Dictionary = edge_states.get(_edge_key(a, b), {})
		var signature := "|".join([
			key,
			_retained_view_signature_current(),
			_retained_vec_key(size),
			_retained_vec_key(_custom_node_pos(nodes[a])),
			_retained_vec_key(_custom_node_pos(nodes[b])),
			"!" if bool(state.get("invalid", false)) else ".",
			str(snappedf(snap_amount, 0.01)),
		])
		if _submit_retained_item(retained_edge_items, "edge", key, {"edge": edge, "a": a, "b": b}, signature, force_items):
			retained_edge_update_count += 1
		else:
			retained_edge_noop_count += 1
	retained_edge_remove_count += _prune_retained_item_pool(retained_edge_items, live)

func _submit_retained_socket_items(force_items: bool = false) -> void:
	var socket_markers: Array = board_snapshot.get("socket_markers", [])
	var material_highlights: Dictionary = board_snapshot.get("material_highlights", {})
	var live := {}
	for i in range(socket_markers.size()):
		var marker = socket_markers[i]
		if not (marker is Dictionary):
			continue
		var marker_dict: Dictionary = marker
		var marker_pos = marker_dict.get("pos", Vector2.ZERO)
		if not (marker_pos is Vector2):
			continue
		var node_key := str(int(marker_dict.get("node", -1)))
		var key := "%s:%s:%d" % [node_key, String(marker_dict.get("slot", "")), i]
		live[key] = true
		var highlight_state := String(Dictionary(material_highlights.get(node_key, {})).get("state", ""))
		var signature := "|".join([
			key,
			_retained_view_signature_current(),
			_retained_vec_key(size),
			_retained_vec_key(marker_pos),
			"o" if bool(marker_dict.get("occupied", false)) else ".",
			"s" if bool(marker_dict.get("selected", false)) else ".",
			highlight_state,
			str(snappedf(snap_amount, 0.01)),
		])
		if _submit_retained_item(retained_socket_items, "socket", key, {"marker": marker_dict}, signature, force_items):
			retained_socket_update_count += 1
		else:
			retained_socket_noop_count += 1
	retained_socket_remove_count += _prune_retained_item_pool(retained_socket_items, live)

func _submit_retained_overlay_items(force_items: bool = false) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var material_highlights: Dictionary = board_snapshot.get("material_highlights", {})
	var live_material := {}
	for raw_key in material_highlights.keys():
		var node_index := int(raw_key)
		if node_index < 0 or node_index >= nodes.size():
			continue
		var state := String(Dictionary(material_highlights[raw_key]).get("state", ""))
		if state == "":
			continue
		var key := "material:%d" % node_index
		live_material[key] = true
		var signature := "%s|%s|%s|%s|%s|%s" % [key, _retained_view_signature_current(), state, _retained_vec_key(size), _retained_vec_key(_custom_node_pos(nodes[node_index])), str(snappedf(snap_amount, 0.01))]
		if _submit_retained_item(retained_material_overlay_items, "material_overlay", key, {"node": node_index, "state": state}, signature, force_items):
			retained_overlay_update_count += 1
		else:
			retained_overlay_noop_count += 1
	retained_overlay_remove_count += _prune_retained_item_pool(retained_material_overlay_items, live_material)
	_submit_retained_binding_group_items(force_items)
	_submit_retained_warning_items(force_items)
	_submit_retained_sweep_items(force_items)
	_submit_retained_candidate_items(force_items)

func _binding_group_payloads() -> Array:
	var nodes: Array = board_snapshot.get("nodes", [])
	var binding_highlights: Dictionary = board_snapshot.get("binding_highlights", {})
	var groups := {}
	for raw_key in binding_highlights.keys():
		var node_index := int(raw_key)
		if node_index < 0 or node_index >= nodes.size():
			continue
		var info: Dictionary = Dictionary(binding_highlights[raw_key])
		var candidate_id := String(info.get("candidate_id", "node:%d" % node_index))
		if candidate_id == "":
			candidate_id = "node:%d" % node_index
		var group: Dictionary = groups.get(candidate_id, {
			"candidate_id": candidate_id,
			"nodes": [],
			"state": String(info.get("state", "")),
			"selected": bool(info.get("selected", false)),
			"reason": String(info.get("reason", "")),
			"required_drive": float(info.get("required_drive", 0.0)),
		})
		var group_nodes: Array = Array(group.get("nodes", []))
		for raw_node in Array(info.get("target_nodes", [])):
			var target_node := int(raw_node)
			if target_node >= 0 and target_node < nodes.size() and not group_nodes.has(target_node):
				group_nodes.append(target_node)
		if not group_nodes.has(node_index):
			group_nodes.append(node_index)
		group["nodes"] = group_nodes
		if bool(info.get("selected", false)):
			group["selected"] = true
		if String(group.get("state", "")) == "" and String(info.get("state", "")) != "":
			group["state"] = String(info.get("state", ""))
		groups[candidate_id] = group
	var result: Array = []
	for raw_group in groups.values():
		if raw_group is Dictionary and not Array(Dictionary(raw_group).get("nodes", [])).is_empty():
			result.append(raw_group)
	return result

func _submit_retained_binding_group_items(force_items: bool) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var live := {}
	for raw_group in _binding_group_payloads():
		if not (raw_group is Dictionary):
			continue
		var group: Dictionary = raw_group
		var candidate_id := String(group.get("candidate_id", ""))
		if candidate_id == "":
			continue
		var key := "binding:%s" % candidate_id
		live[key] = true
		var bits: Array = [key, _retained_view_signature_current(), String(group.get("state", "")), str(bool(group.get("selected", false))), str(snappedf(snap_amount, 0.01)), _retained_vec_key(size)]
		for raw_node in Array(group.get("nodes", [])):
			var node_index := int(raw_node)
			if node_index < 0 or node_index >= nodes.size():
				continue
			bits.append("%d:%s:%s" % [
				node_index,
				_retained_vec_key(_custom_node_pos(nodes[node_index])),
				str(snappedf(_node_visual_radius(nodes[node_index]), 0.1)),
			])
		if _submit_retained_item(retained_binding_group_items, "binding_group", key, group, "|".join(bits), force_items):
			retained_overlay_update_count += 1
		else:
			retained_overlay_noop_count += 1
	retained_overlay_remove_count += _prune_retained_item_pool(retained_binding_group_items, live)

func _submit_retained_warning_items(force_items: bool) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var live := {}
	for raw_warning in Array(board_snapshot.get("material_warning_nodes", [])):
		var node_index := int(raw_warning)
		if node_index < 0 or node_index >= nodes.size():
			continue
		var key := "warning:%d" % node_index
		live[key] = true
		var signature := "%s|%s|%s|%s|%s" % [key, _retained_view_signature_current(), _retained_vec_key(size), _retained_vec_key(_custom_node_pos(nodes[node_index])), str(snappedf(snap_amount, 0.01))]
		if _submit_retained_item(retained_warning_items, "warning", key, {"node": node_index}, signature, force_items):
			retained_overlay_update_count += 1
		else:
			retained_overlay_noop_count += 1
	retained_overlay_remove_count += _prune_retained_item_pool(retained_warning_items, live)

func _submit_retained_sweep_items(force_items: bool) -> void:
	var live := {}
	var profiles := Array(board_snapshot.get("joint_slot_profiles", []))
	for i in range(profiles.size()):
		if not (profiles[i] is Dictionary):
			continue
		var key := "sweep:%d" % i
		live[key] = true
		var profile: Dictionary = profiles[i]
		var pivot_value = profile.get("pivot", Vector2.ZERO)
		var pivot_key := _retained_vec_key(pivot_value if pivot_value is Vector2 else Vector2.ZERO)
		var signature := "|".join([
			key,
			_retained_view_signature_current(),
			_retained_vec_key(size),
			pivot_key,
			str(snappedf(float(profile.get("world_center_angle", 0.0)), 0.01)),
			str(snappedf(float(profile.get("half_width", 0.0)), 0.01)),
			str(int(board_snapshot.get("swept_collision_count", 0))),
			str(snappedf(snap_amount, 0.01)),
		])
		if _submit_retained_item(retained_sweep_arc_items, "sweep", key, {"profile": profile}, signature, force_items):
			retained_overlay_update_count += 1
		else:
			retained_overlay_noop_count += 1
	retained_overlay_remove_count += _prune_retained_item_pool(retained_sweep_arc_items, live)

func _submit_retained_candidate_items(force_items: bool) -> void:
	var live := {}
	var candidate: Dictionary = board_snapshot.get("candidate_socket_pair", {})
	if not candidate.is_empty() and candidate.get("a") is Vector2 and candidate.get("b") is Vector2:
		var key := "candidate:socket_pair"
		live[key] = true
		var signature := "%s|%s|%s|%s|%s|%s" % [key, _retained_view_signature_current(), _retained_vec_key(size), _retained_vec_key(candidate.get("a")), _retained_vec_key(candidate.get("b")), str(snappedf(snap_amount, 0.01))]
		if _submit_retained_item(retained_candidate_socket_items, "candidate", key, {"candidate": candidate}, signature, force_items):
			retained_overlay_update_count += 1
		else:
			retained_overlay_noop_count += 1
	retained_overlay_remove_count += _prune_retained_item_pool(retained_candidate_socket_items, live)

func _submit_retained_components(force_items: bool = false) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var live := {}
	for i in range(nodes.size()):
		live[i] = true
		var item: AssemblyBoardRenderComponentItem = retained_component_items.get(i, null)
		if item == null:
			item = AssemblyBoardRenderComponentItem.new()
			item.name = "Component_%d" % i
			item.configure(self, i)
			retained_component_items[i] = item
			if retained_component_layer != null:
				retained_component_layer.add_child(item)
			force_items = true
		item.position = Vector2.ZERO
		item.size = size
		if item.placeholder_mode and retained_deferred_component_indices.has(i):
			retained_component_noop_count += 1
			continue
		var signature := _retained_component_signature(i)
		if force_items:
			item.item_signature = ""
		if item.submit(signature):
			retained_component_update_count += 1
		else:
			retained_component_noop_count += 1
	for key in retained_component_items.keys():
		var index := int(key)
		if live.has(index):
			continue
		var old_item: AssemblyBoardRenderComponentItem = retained_component_items[index]
		if old_item != null:
			old_item.queue_free()
		retained_component_items.erase(index)
		retained_component_remove_count += 1

func _submit_retained_components_for_indices(indices: Array) -> void:
	_ensure_retained_render_layer()
	var nodes: Array = board_snapshot.get("nodes", [])
	for raw_index in indices:
		var i := int(raw_index)
		if i < 0 or i >= nodes.size():
			continue
		var item: AssemblyBoardRenderComponentItem = retained_component_items.get(i, null)
		if item == null:
			item = AssemblyBoardRenderComponentItem.new()
			item.name = "Component_%d" % i
			item.configure(self, i)
			retained_component_items[i] = item
			if retained_component_layer != null:
				retained_component_layer.add_child(item)
		item.position = Vector2.ZERO
		item.size = size
		var signature := _retained_component_signature(i)
		if item.submit(signature):
			retained_component_update_count += 1
			retained_component_body_submit_count += 1
		else:
			retained_component_noop_count += 1

func _defer_retained_components(indices: Array) -> void:
	for raw_index in indices:
		var i := int(raw_index)
		if i < 0:
			continue
		if not retained_deferred_component_indices.has(i):
			retained_deferred_component_indices.append(i)
			retained_component_defer_count += 1

func queue_retained_component_body_submit(node_index: int) -> void:
	_defer_retained_components([node_index])

func flush_deferred_retained_components(max_items: int = 2) -> int:
	if retained_deferred_component_indices.is_empty():
		return 0
	var batch: Array = []
	while not retained_deferred_component_indices.is_empty() and batch.size() < maxi(1, max_items):
		batch.append(retained_deferred_component_indices.pop_front())
	_submit_retained_components_for_indices(batch)
	_submit_retained_layer(retained_selection_layer, "selection|" + _retained_selection_signature())
	_submit_retained_layer(retained_hint_layer, "hint|" + last_board_signature + "|" + ui_language + "|tpl:" + _assembly_template_signature())
	retained_component_deferred_flush_count += batch.size()
	return batch.size()

func _retained_vec_key(value: Vector2, scale: float = 10.0) -> String:
	return "%d,%d" % [roundi(value.x * scale), roundi(value.y * scale)]

func _retained_edges_signature() -> String:
	var nodes: Array = board_snapshot.get("nodes", [])
	var edges: Array = board_snapshot.get("edges", [])
	var edge_states: Dictionary = board_snapshot.get("edge_states", {})
	var bits: Array = [_retained_view_signature_current(), _retained_vec_key(size), str(edges.size()), str(nodes.size())]
	for edge in edges:
		var a := _edge_node_a(edge)
		var b := _edge_node_b(edge)
		if a < 0 or b < 0 or a >= nodes.size() or b >= nodes.size():
			continue
		var state: Dictionary = edge_states.get(_edge_key(a, b), {})
		bits.append("%d:%d:%s:%s:%s" % [
			a,
			b,
			_retained_vec_key(_custom_node_pos(nodes[a])),
			_retained_vec_key(_custom_node_pos(nodes[b])),
			"!" if bool(state.get("invalid", false)) else ".",
		])
	return "|".join(bits)

func _retained_socket_signature() -> String:
	var socket_markers: Array = board_snapshot.get("socket_markers", [])
	var material_highlights: Dictionary = board_snapshot.get("material_highlights", {})
	var bits: Array = [_retained_view_signature_current(), _retained_vec_key(size), str(socket_markers.size()), str(snappedf(snap_amount, 0.01))]
	for marker in socket_markers:
		if not (marker is Dictionary):
			continue
		var marker_pos = Dictionary(marker).get("pos", Vector2.ZERO)
		var pos_key := _retained_vec_key(marker_pos if marker_pos is Vector2 else Vector2.ZERO)
		var node_key := str(int(Dictionary(marker).get("node", -1)))
		var highlight_state := String(Dictionary(material_highlights.get(node_key, {})).get("state", ""))
		bits.append("%s:%s:%s:%s:%s" % [
			node_key,
			String(Dictionary(marker).get("slot", "")),
			pos_key,
			"o" if bool(Dictionary(marker).get("occupied", false)) else ".",
			highlight_state,
		])
	return "|".join(bits)

func _retained_overlay_signature() -> String:
	var nodes: Array = board_snapshot.get("nodes", [])
	var material_highlights: Dictionary = board_snapshot.get("material_highlights", {})
	var warning_nodes: Array = board_snapshot.get("material_warning_nodes", [])
	var profiles: Array = board_snapshot.get("joint_slot_profiles", [])
	var candidate: Dictionary = board_snapshot.get("candidate_socket_pair", {})
	var tryout: Dictionary = board_snapshot.get("tryout_preview", {})
	var bits: Array = [
		_retained_view_signature_current(),
		_retained_vec_key(size),
		str(nodes.size()),
		str(material_highlights.size()),
		str(warning_nodes.size()),
		str(profiles.size()),
		str(int(board_snapshot.get("swept_collision_count", 0))),
		str(snappedf(snap_amount, 0.01)),
		str(board_snapshot.get("board_tool", "")),
		str(board_snapshot.get("pose_root_node", -1)),
		String(tryout.get("profile", "")),
		str(snappedf(float(tryout.get("timer", 0.0)), 0.02)),
	]
	for key in material_highlights.keys():
		bits.append("%s:%s" % [str(key), String(Dictionary(material_highlights[key]).get("state", ""))])
	for raw_warning in warning_nodes:
		bits.append("w%d" % int(raw_warning))
	if candidate.get("a") is Vector2:
		bits.append("ca" + _retained_vec_key(candidate.get("a")))
	if candidate.get("b") is Vector2:
		bits.append("cb" + _retained_vec_key(candidate.get("b")))
	for raw_try_node in Array(tryout.get("target_nodes", [])):
		bits.append("tn%d" % int(raw_try_node))
	return "|".join(bits)

func _retained_selection_signature() -> String:
	return "%s|%s|%s|%s|%s" % [
		_retained_view_signature_current(),
		_retained_vec_key(size),
		"1" if bool(board_snapshot.get("selection_box_active", false)) else "0",
		_retained_vec_key(board_snapshot.get("selection_box_start", Vector2.ZERO) if board_snapshot.get("selection_box_start", Vector2.ZERO) is Vector2 else Vector2.ZERO),
		_retained_vec_key(board_snapshot.get("selection_box_current", Vector2.ZERO) if board_snapshot.get("selection_box_current", Vector2.ZERO) is Vector2 else Vector2.ZERO),
	]

func _retained_component_signature(node_index: int) -> String:
	var nodes: Array = board_snapshot.get("nodes", [])
	var edges: Array = board_snapshot.get("edges", [])
	if node_index < 0 or node_index >= nodes.size():
		return "missing:%d" % node_index
	var node: Dictionary = nodes[node_index]
	var selected_nodes: Array = board_snapshot.get("selected_nodes", [])
	var pose_downstream: Array = board_snapshot.get("pose_downstream_nodes", [])
	var binding_highlights: Dictionary = board_snapshot.get("binding_highlights", {})
	var binding_info: Dictionary = Dictionary(binding_highlights.get(str(node_index), {}))
	var tryout: Dictionary = board_snapshot.get("tryout_preview", {})
	var tryout_nodes: Array = Array(tryout.get("target_nodes", []))
	var center := _custom_node_pos(node)
	var axis := _custom_node_axis(node_index, nodes, edges)
	return "%d|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%d|%s|%s|%s|%s|%s|%s" % [
		node_index,
		_retained_view_signature_current(),
		_retained_vec_key(size),
		_retained_vec_key(center),
		_retained_vec_key(axis, 100.0),
		String(node.get("label", "")),
		String(node.get("slot", "")),
		String(node.get("material_class", "")),
		String(node.get("component_name", "")),
		str(int(board_snapshot.get("selected", 0)) == node_index or selected_nodes.has(node_index)),
		str(pose_downstream.has(node_index)),
		str(bool(node.get("illegal", false))),
		int(node.get("module_count", 1)),
		str(snappedf(snap_amount, 0.01)),
		str(board_snapshot.get("show_node_numbers", false)),
		String(binding_info.get("state", "")),
		str(bool(binding_info.get("selected", false))),
		String(tryout.get("profile", "")),
		str(tryout_nodes.has(node_index)),
	]

func _draw() -> void:
	root_draw_count += 1
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.018, 0.022, 0.96), true)
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(float(x), 0.0), Vector2(float(x), size.y), Color(0.3, 0.92, 1.0, 0.045), 1.0)
	for y in range(0, int(size.y), 32):
		draw_line(Vector2(0.0, float(y)), Vector2(size.x, float(y)), Color(0.3, 0.92, 1.0, 0.045), 1.0)
	if board_mode == "barrier":
		_set_retained_render_visible(false)
		_draw_barrier_board()
		return
	if board_mode == "custom":
		_ensure_retained_render_layer()
		_set_retained_render_visible(true)
		return
	_set_retained_render_visible(false)
	var body := Rect2(size * 0.5 - Vector2(56.0, 40.0), Vector2(112.0, 80.0))
	draw_rect(body, Color(0.13, 0.18, 0.2, 0.98), true)
	draw_rect(body.grow(5.0), Color(0.55, 0.8, 0.9, 0.28), false, 2.0)
	for part_key in board_snapshot.keys():
		var slot := _slot_position(String(part_key))
		var pulse := snap_amount if String(part_key) == snap_part else 0.0
		var selected := String(part_key) == selected_part
		var illegal := illegal_parts.has(part_key)
		var line_color := Color(0.3, 0.92, 1.0, 0.38 + pulse * 0.44)
		if illegal:
			line_color = Color(1.0, 0.26, 0.18, 0.75)
		draw_line(body.get_center(), slot, line_color, 3.0 + pulse * 4.0)
		_draw_socket(slot, selected, illegal, pulse)
		var item: Dictionary = board_snapshot[part_key]
		_draw_mini_component(slot, item, pulse)

func _draw_barrier_board() -> void:
	var screen_rect := _barrier_board_rect()
	var columns := _barrier_columns()
	var rows := _barrier_rows()
	var show_grid_guides := bool(board_snapshot.get("show_grid_guides", true))
	draw_rect(screen_rect.grow(10.0), Color(0.08, 0.14, 0.18, 0.72), true)
	draw_rect(screen_rect.grow(10.0), Color(0.34, 0.9, 1.0, 0.2), false, 2.0)
	draw_rect(screen_rect, Color(0.01, 0.02, 0.028, 0.82), true)
	draw_rect(screen_rect, Color(0.72, 0.9, 1.0, 0.5), false, 2.0)
	draw_line(Vector2(screen_rect.get_center().x, screen_rect.position.y), Vector2(screen_rect.get_center().x, screen_rect.end.y), Color(0.34, 0.92, 1.0, 0.18), 1.0)
	draw_line(Vector2(screen_rect.position.x, screen_rect.get_center().y), Vector2(screen_rect.end.x, screen_rect.get_center().y), Color(1.0, 0.86, 0.24, 0.16), 1.0)
	if show_grid_guides:
		for x in range(1, columns):
			var px := screen_rect.position.x + screen_rect.size.x * float(x) / float(columns)
			_draw_dashed_line(Vector2(px, screen_rect.position.y), Vector2(px, screen_rect.end.y), Color(0.58, 0.95, 1.0, 0.26), 1.0, 7.0, 5.0)
		for y in range(1, rows):
			var py := screen_rect.position.y + screen_rect.size.y * float(y) / float(rows)
			_draw_dashed_line(Vector2(screen_rect.position.x, py), Vector2(screen_rect.end.x, py), Color(1.0, 0.86, 0.32, 0.22), 1.0, 7.0, 5.0)
	var ether_color := Color(0.76, 0.42, 1.0, 0.92)
	for key in board_snapshot.keys():
		if not String(key).begins_with("tile_") or not (board_snapshot[key] is Dictionary):
			continue
		var item: Dictionary = Dictionary(board_snapshot[key])
		var index := int(item.get("index", 0))
		var tile_pos: Vector2 = item.get("pos", Vector2(-1.0, -1.0)) if item.get("pos", null) is Vector2 else Vector2(-1.0, -1.0)
		var cell_rect := _barrier_cell_rect(index)
		var center := cell_rect.get_center()
		if tile_pos.x >= 0.0:
			center = screen_rect.position + Vector2(clampf(tile_pos.x, 0.0, 1.0) * screen_rect.size.x, clampf(tile_pos.y, 0.0, 1.0) * screen_rect.size.y)
		var pulse := snap_amount if String(key) == snap_part else 0.0
		var kind := String(item.get("kind", "ether_pin"))
		if kind == "question_block":
			var block_size := minf(cell_rect.size.x, cell_rect.size.y) * 0.62
			var rect := Rect2(center - Vector2.ONE * block_size * 0.5 - Vector2.ONE * pulse * 4.0, Vector2.ONE * block_size + Vector2.ONE * pulse * 8.0)
			draw_rect(rect, Color(0.96, 0.72, 0.18, 0.98), true)
			draw_rect(rect, Color(0.18, 0.09, 0.02, 0.9), false, 2.0)
			draw_string(ThemeDB.get_fallback_font(), center + Vector2(-5.0, 7.0), "?", HORIZONTAL_ALIGNMENT_CENTER, 10.0, 24, Color(0.16, 0.08, 0.02, 1.0))
			draw_circle(center + Vector2(12.0, -12.0), 3.0 + pulse * 2.0, Color.WHITE)
		else:
			var radius := minf(cell_rect.size.x, cell_rect.size.y) * 0.28
			draw_arc(center, radius + pulse * 6.0, 0.0, TAU, 32, ether_color, 3.0)
			draw_circle(center, radius * 0.42, ether_color.lerp(Color.WHITE, 0.35))
			for i in range(4):
				var angle := TAU * float(i) / 4.0 + 0.4
				draw_line(center, center + Vector2(cos(angle), sin(angle)) * (radius * 1.34 + pulse * 7.0), Color(0.34, 0.92, 1.0, 0.44), 2.0)
	var barrier_hint := "结界屏幕蓝图 / 最大一屏 / 以太固定不相连组件" if _board_is_zh() else "BARRIER SCREEN BLUEPRINT / max one viewport; ether binds disconnected tiles"
	draw_string(ThemeDB.get_fallback_font(), Vector2(38.0, size.y - 22.0), barrier_hint, HORIZONTAL_ALIGNMENT_LEFT, size.x - 76.0, 13, Color(0.78, 0.9, 1.0, 0.72))

func _edge_node_a(edge) -> int:
	if edge is Dictionary:
		return int(Dictionary(edge).get("a_node", Dictionary(edge).get("a", -1)))
	if edge is Array and edge.size() >= 2:
		return int(edge[0])
	return -1

func _edge_node_b(edge) -> int:
	if edge is Dictionary:
		return int(Dictionary(edge).get("b_node", Dictionary(edge).get("b", -1)))
	if edge is Array and edge.size() >= 2:
		return int(edge[1])
	return -1

func _edge_socket_for_node(edge, node_index: int) -> String:
	if edge is Dictionary:
		var dict: Dictionary = edge
		if int(dict.get("a_node", dict.get("a", -1))) == node_index:
			return String(dict.get("a_socket", ""))
		if int(dict.get("b_node", dict.get("b", -1))) == node_index:
			return String(dict.get("b_socket", ""))
	return ""

func _retained_draw_custom_item(canvas: CanvasItem, kind: String, payload: Dictionary) -> void:
	match kind:
		"edge":
			_retained_draw_custom_edge_item(canvas, payload)
		"socket":
			_retained_draw_custom_socket_item(canvas, payload)
		"candidate":
			_retained_draw_custom_candidate_item(canvas, payload)
		"material_overlay":
			_retained_draw_custom_material_overlay_item(canvas, payload)
		"binding_group":
			_retained_draw_custom_binding_group_item(canvas, payload)
		"warning":
			_retained_draw_custom_warning_item(canvas, payload)
		"sweep":
			_retained_draw_custom_sweep_item(canvas, payload)

func _retained_draw_custom_edge_item(canvas: CanvasItem, payload: Dictionary) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var edge = payload.get("edge", {})
	var a := int(payload.get("a", _edge_node_a(edge)))
	var b := int(payload.get("b", _edge_node_b(edge)))
	if a < 0 or b < 0 or a >= nodes.size() or b >= nodes.size():
		return
	var edge_states: Dictionary = board_snapshot.get("edge_states", {})
	var pa_center: Vector2 = _custom_node_pos(nodes[a])
	var pb_center: Vector2 = _custom_node_pos(nodes[b])
	var axis_a := _custom_node_axis(a, nodes, board_snapshot.get("edges", []))
	var axis_b := _custom_node_axis(b, nodes, board_snapshot.get("edges", []))
	var pa: Vector2 = _node_connection_anchor(nodes[a], axis_a, pa_center, pb_center, _node_visual_radius(nodes[a]))
	var pb: Vector2 = _node_connection_anchor(nodes[b], axis_b, pb_center, pa_center, _node_visual_radius(nodes[b]))
	var edge_state: Dictionary = edge_states.get(_edge_key(a, b), {})
	if edge_state.has("pa") and edge_state.get("pa") is Vector2:
		pa = edge_state.get("pa")
	if edge_state.has("pb") and edge_state.get("pb") is Vector2:
		pb = edge_state.get("pb")
	var edge_length := maxf(_node_physical_length(nodes[a]), _node_physical_length(nodes[b]))
	var edge_width := maxf(1.0, (2.0 + clampf(edge_length * 9.0, 1.0, 9.0)) * _custom_view_zoom())
	var edge_invalid := bool(edge_state.get("invalid", false))
	var edge_color := Color(1.0, 0.18, 0.12, 0.76) if edge_invalid else Color(0.3, 0.92, 1.0, 0.36)
	canvas.draw_line(pa, pb, edge_color, edge_width)
	canvas.draw_line(pa, pb, Color(0.04, 0.08, 0.1, 0.76), maxf(1.0, edge_width * 0.36))
	canvas.draw_circle(pa, maxf(2.5, edge_width * 0.8), Color(1.0, 0.18, 0.12, 0.82) if edge_invalid else Color(1.0, 0.88, 0.24, 0.68))
	canvas.draw_circle(pb, maxf(2.5, edge_width * 0.8), Color(1.0, 0.18, 0.12, 0.82) if edge_invalid else Color(1.0, 0.88, 0.24, 0.68))
	canvas.draw_line(pa.lerp(pb, 0.44), pa.lerp(pb, 0.56), Color(1.0, 0.88, 0.24, 0.72) if not edge_invalid else Color(1.0, 0.18, 0.12, 0.9), edge_width + 1.4)
	if edge_invalid:
		canvas.draw_string(ThemeDB.get_fallback_font(), pa.lerp(pb, 0.5) + Vector2(-22.0, -8.0), "SNAP", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 10, Color(1.0, 0.28, 0.18, 0.95))

func _retained_draw_custom_socket_item(canvas: CanvasItem, payload: Dictionary) -> void:
	var marker: Dictionary = payload.get("marker", {})
	var marker_pos = marker.get("pos", Vector2.ZERO)
	if not (marker_pos is Vector2):
		return
	var socket_pos: Vector2 = marker_pos
	var occupied := bool(marker.get("occupied", false))
	var selected_socket := bool(marker.get("selected", false))
	var slot_key := String(marker.get("slot", ""))
	var node_key := str(int(marker.get("node", -1)))
	var material_highlights: Dictionary = board_snapshot.get("material_highlights", {})
	var highlight_state := String(Dictionary(material_highlights.get(node_key, {})).get("state", ""))
	var radius := clampf(4.0 * _custom_view_zoom(), 3.2, 7.5)
	var fill := Color(0.22, 0.98, 1.0, 0.42)
	var ring := Color(0.36, 1.0, 0.92, 0.82)
	if occupied:
		fill = Color(0.18, 1.0, 0.45, 0.62)
		ring = Color(0.84, 1.0, 0.46, 0.88)
	if selected_socket:
		radius += 1.8 + snap_amount * 2.5
		ring = Color(1.0, 0.88, 0.24, 0.96)
	if highlight_state == "legal_joint" or highlight_state == "legal_socket":
		radius += 2.0 + snap_amount * 2.0
		fill = Color(0.1, 1.0, 0.76, 0.52)
		ring = Color(0.36, 1.0, 0.78, 0.96)
	elif highlight_state == "illegal_material" or highlight_state == "illegal_group":
		radius += 2.6 + snap_amount * 3.2
		fill = Color(1.0, 0.12, 0.06, 0.38)
		ring = Color(1.0, 0.24, 0.12, 0.98)
	if slot_key == "joint":
		canvas.draw_arc(socket_pos, radius + 2.2, 0.0, TAU, 18, ring, 1.5)
		canvas.draw_line(socket_pos - Vector2(radius, 0.0), socket_pos + Vector2(radius, 0.0), ring, 1.2)
		canvas.draw_line(socket_pos - Vector2(0.0, radius), socket_pos + Vector2(0.0, radius), ring, 1.2)
	else:
		canvas.draw_circle(socket_pos, radius, fill)
		canvas.draw_arc(socket_pos, radius + 1.6, 0.0, TAU, 22, ring, 1.4)
	if occupied:
		canvas.draw_line(socket_pos - Vector2(radius * 0.48, 0.0), socket_pos + Vector2(radius * 0.48, 0.0), Color(0.9, 1.0, 0.78, 0.82), 1.2)

func _retained_draw_custom_candidate_item(canvas: CanvasItem, payload: Dictionary) -> void:
	var candidate: Dictionary = payload.get("candidate", {})
	if candidate.get("a") is Vector2 and candidate.get("b") is Vector2:
		var ca: Vector2 = candidate.get("a")
		var cb: Vector2 = candidate.get("b")
		canvas.draw_line(ca, cb, Color(1.0, 0.86, 0.18, 0.58), 2.4 + snap_amount * 2.0)
		canvas.draw_circle(ca, 8.0 + snap_amount * 5.0, Color(1.0, 0.86, 0.18, 0.25))
		canvas.draw_circle(cb, 8.0 + snap_amount * 5.0, Color(1.0, 0.86, 0.18, 0.25))
		canvas.draw_arc(ca, 10.0 + snap_amount * 6.0, 0.0, TAU, 24, Color(1.0, 0.86, 0.18, 0.9), 2.0)
		canvas.draw_arc(cb, 10.0 + snap_amount * 6.0, 0.0, TAU, 24, Color(1.0, 0.86, 0.18, 0.9), 2.0)

func _retained_draw_custom_material_overlay_item(canvas: CanvasItem, payload: Dictionary) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var node_index := int(payload.get("node", -1))
	if node_index < 0 or node_index >= nodes.size():
		return
	var state := String(payload.get("state", ""))
	var center := _custom_node_pos(nodes[node_index])
	var radius := _node_visual_radius(nodes[node_index])
	var color := Color(0.25, 0.95, 1.0, 0.34)
	var width := 2.0
	if state == "legal_joint" or state == "legal_socket":
		color = Color(0.28, 1.0, 0.72, 0.56)
		width = 2.4
	elif state == "same_limb":
		color = Color(0.28, 0.88, 1.0, 0.34)
		width = 1.8
	elif state == "illegal_material" or state == "illegal_group":
		color = Color(1.0, 0.16, 0.08, 0.58)
		width = 2.8 + snap_amount * 2.0
	canvas.draw_arc(center, radius + 8.0 + snap_amount * 5.0, 0.0, TAU, 34, color, width)

func _retained_draw_custom_binding_group_item(canvas: CanvasItem, payload: Dictionary) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var group_nodes: Array = Array(payload.get("nodes", []))
	if group_nodes.is_empty():
		return
	var first := true
	var bounds := Rect2(Vector2.ZERO, Vector2.ZERO)
	var centers: Array = []
	for raw_node in group_nodes:
		var node_index := int(raw_node)
		if node_index < 0 or node_index >= nodes.size():
			continue
		var center := _custom_node_pos(nodes[node_index])
		var radius := _node_visual_radius(nodes[node_index]) + 22.0 + snap_amount * 7.0
		var node_rect := Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))
		bounds = node_rect if first else bounds.merge(node_rect)
		first = false
		centers.append(center)
	if first:
		return
	bounds = bounds.grow(8.0)
	var state := String(payload.get("state", "binding_valid"))
	var selected := bool(payload.get("selected", false))
	var color := Color(0.18, 1.0, 0.76, 0.88)
	var fill := Color(0.12, 1.0, 0.72, 0.10)
	var label := "点击绑定" if _board_is_zh() else "CLICK"
	if state == "binding_invalid":
		color = Color(1.0, 0.28, 0.1, 0.9)
		fill = Color(1.0, 0.12, 0.06, 0.10)
		label = "不可绑定" if _board_is_zh() else "NO"
	elif state == "allocation_bound":
		color = Color(0.78, 0.52, 1.0, 0.88)
		fill = Color(0.52, 0.32, 1.0, 0.10)
		label = "动力" if _board_is_zh() else "POWER"
	if selected:
		color = Color(1.0, 0.9, 0.28, 0.96)
		fill = Color(1.0, 0.82, 0.18, 0.12)
	canvas.draw_rect(bounds, fill, true)
	canvas.draw_rect(bounds, Color(color.r, color.g, color.b, 0.42), false, 6.0)
	canvas.draw_rect(bounds.grow(-4.0), color, false, 2.4)
	for i in range(centers.size() - 1):
		canvas.draw_line(centers[i], centers[i + 1], Color(color.r, color.g, color.b, 0.36), 2.0)
	for center_value in centers:
		if center_value is Vector2:
			var c: Vector2 = center_value
			canvas.draw_arc(c, 11.0 + snap_amount * 4.0, 0.0, TAU, 24, color, 2.0)
	var font := ThemeDB.get_fallback_font()
	var label_rect := Rect2(bounds.position + Vector2(8.0, -24.0), Vector2(maxf(74.0, bounds.size.x - 16.0), 20.0))
	if label_rect.position.y < 2.0:
		label_rect.position.y = bounds.end.y + 4.0
	canvas.draw_rect(label_rect, Color(0.0, 0.0, 0.0, 0.68), true)
	canvas.draw_rect(label_rect, color, false, 1.0)
	canvas.draw_string(font, label_rect.position + Vector2(4.0, 14.0), label, HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x - 8.0, 11, color)

func _retained_draw_custom_warning_item(canvas: CanvasItem, payload: Dictionary) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var node_index := int(payload.get("node", -1))
	if node_index < 0 or node_index >= nodes.size():
		return
	var center := _custom_node_pos(nodes[node_index])
	var radius := _node_visual_radius(nodes[node_index])
	canvas.draw_arc(center, radius + 14.0 + snap_amount * 10.0, 0.0, TAU, 42, Color(1.0, 0.08, 0.02, 0.9), 4.0)
	canvas.draw_string(ThemeDB.get_fallback_font(), center + Vector2(-28.0, -radius - 18.0), "材料!" if _board_is_zh() else "MAT!", HORIZONTAL_ALIGNMENT_CENTER, 56.0, 12, Color(1.0, 0.2, 0.1, 0.95))

func _retained_draw_custom_sweep_item(canvas: CanvasItem, payload: Dictionary) -> void:
	var profile: Dictionary = payload.get("profile", {})
	var pivot_value = profile.get("pivot", Vector2.ZERO)
	if not (pivot_value is Vector2):
		return
	var pivot_topology: Vector2 = pivot_value
	var pivot: Vector2 = size * 0.5 + _custom_view_offset() + (pivot_topology - Vector2(0.5, 0.5)) * _custom_board_uniform_scale()
	var center_angle := float(profile.get("world_center_angle", 0.0))
	var half_width := float(profile.get("half_width", 0.0))
	var sweep_radius := clampf(44.0 * _custom_view_zoom(), 18.0, 92.0)
	var sweep_bad := int(board_snapshot.get("swept_collision_count", 0)) > 0
	var sweep_color := Color(1.0, 0.18, 0.08, 0.46) if sweep_bad else Color(0.24, 0.88, 1.0, 0.28)
	canvas.draw_arc(pivot, sweep_radius, center_angle - half_width, center_angle + half_width, 28, sweep_color, 2.0)
	canvas.draw_line(pivot, pivot + Vector2(cos(center_angle - half_width), sin(center_angle - half_width)) * sweep_radius, Color(sweep_color.r, sweep_color.g, sweep_color.b, 0.18), 1.0)
	canvas.draw_line(pivot, pivot + Vector2(cos(center_angle + half_width), sin(center_angle + half_width)) * sweep_radius, Color(sweep_color.r, sweep_color.g, sweep_color.b, 0.18), 1.0)

func _retained_draw_custom_edges(canvas: CanvasItem) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var edges: Array = board_snapshot.get("edges", [])
	var edge_states: Dictionary = board_snapshot.get("edge_states", {})
	for edge in edges:
		var a := _edge_node_a(edge)
		var b := _edge_node_b(edge)
		if a < 0 or b < 0 or a >= nodes.size() or b >= nodes.size():
			continue
		var pa_center: Vector2 = _custom_node_pos(nodes[a])
		var pb_center: Vector2 = _custom_node_pos(nodes[b])
		var axis_a := _custom_node_axis(a, nodes, edges)
		var axis_b := _custom_node_axis(b, nodes, edges)
		var pa: Vector2 = _node_connection_anchor(nodes[a], axis_a, pa_center, pb_center, _node_visual_radius(nodes[a]))
		var pb: Vector2 = _node_connection_anchor(nodes[b], axis_b, pb_center, pa_center, _node_visual_radius(nodes[b]))
		var edge_state: Dictionary = edge_states.get(_edge_key(a, b), {})
		if edge_state.has("pa") and edge_state.get("pa") is Vector2:
			pa = edge_state.get("pa")
		if edge_state.has("pb") and edge_state.get("pb") is Vector2:
			pb = edge_state.get("pb")
		var edge_length := maxf(_node_physical_length(nodes[a]), _node_physical_length(nodes[b]))
		var edge_width := maxf(1.0, (2.0 + clampf(edge_length * 9.0, 1.0, 9.0)) * _custom_view_zoom())
		var edge_invalid := bool(edge_state.get("invalid", false))
		var edge_color := Color(1.0, 0.18, 0.12, 0.76) if edge_invalid else Color(0.3, 0.92, 1.0, 0.36)
		canvas.draw_line(pa, pb, edge_color, edge_width)
		canvas.draw_line(pa, pb, Color(0.04, 0.08, 0.1, 0.76), maxf(1.0, edge_width * 0.36))
		canvas.draw_circle(pa, maxf(2.5, edge_width * 0.8), Color(1.0, 0.18, 0.12, 0.82) if edge_invalid else Color(1.0, 0.88, 0.24, 0.68))
		canvas.draw_circle(pb, maxf(2.5, edge_width * 0.8), Color(1.0, 0.18, 0.12, 0.82) if edge_invalid else Color(1.0, 0.88, 0.24, 0.68))
		canvas.draw_line(pa.lerp(pb, 0.44), pa.lerp(pb, 0.56), Color(1.0, 0.88, 0.24, 0.72) if not edge_invalid else Color(1.0, 0.18, 0.12, 0.9), edge_width + 1.4)
		if edge_invalid:
			canvas.draw_string(ThemeDB.get_fallback_font(), pa.lerp(pb, 0.5) + Vector2(-22.0, -8.0), "SNAP", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 10, Color(1.0, 0.28, 0.18, 0.95))

func _retained_draw_custom_sockets(canvas: CanvasItem) -> void:
	var socket_markers: Array = board_snapshot.get("socket_markers", [])
	var material_highlights: Dictionary = board_snapshot.get("material_highlights", {})
	for marker in socket_markers:
		if not (marker is Dictionary):
			continue
		var marker_pos = marker.get("pos", Vector2.ZERO)
		if not (marker_pos is Vector2):
			continue
		var socket_pos: Vector2 = marker_pos
		var occupied := bool(marker.get("occupied", false))
		var selected_socket := bool(marker.get("selected", false))
		var slot_key := String(marker.get("slot", ""))
		var node_key := str(int(marker.get("node", -1)))
		var highlight_state := String(Dictionary(material_highlights.get(node_key, {})).get("state", ""))
		var radius := clampf(4.0 * _custom_view_zoom(), 3.2, 7.5)
		var fill := Color(0.22, 0.98, 1.0, 0.42)
		var ring := Color(0.36, 1.0, 0.92, 0.82)
		if occupied:
			fill = Color(0.18, 1.0, 0.45, 0.62)
			ring = Color(0.84, 1.0, 0.46, 0.88)
		if selected_socket:
			radius += 1.8 + snap_amount * 2.5
			ring = Color(1.0, 0.88, 0.24, 0.96)
		if highlight_state == "legal_joint" or highlight_state == "legal_socket":
			radius += 2.0 + snap_amount * 2.0
			fill = Color(0.1, 1.0, 0.76, 0.52)
			ring = Color(0.36, 1.0, 0.78, 0.96)
		elif highlight_state == "illegal_material" or highlight_state == "illegal_group":
			radius += 2.6 + snap_amount * 3.2
			fill = Color(1.0, 0.12, 0.06, 0.38)
			ring = Color(1.0, 0.24, 0.12, 0.98)
		if slot_key == "joint":
			canvas.draw_arc(socket_pos, radius + 2.2, 0.0, TAU, 18, ring, 1.5)
			canvas.draw_line(socket_pos - Vector2(radius, 0.0), socket_pos + Vector2(radius, 0.0), ring, 1.2)
			canvas.draw_line(socket_pos - Vector2(0.0, radius), socket_pos + Vector2(0.0, radius), ring, 1.2)
		else:
			canvas.draw_circle(socket_pos, radius, fill)
			canvas.draw_arc(socket_pos, radius + 1.6, 0.0, TAU, 22, ring, 1.4)
		if occupied:
			canvas.draw_line(socket_pos - Vector2(radius * 0.48, 0.0), socket_pos + Vector2(radius * 0.48, 0.0), Color(0.9, 1.0, 0.78, 0.82), 1.2)

func _retained_draw_custom_overlays(canvas: CanvasItem) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var material_highlights: Dictionary = board_snapshot.get("material_highlights", {})
	var candidate_pair: Dictionary = board_snapshot.get("candidate_socket_pair", {})
	if not candidate_pair.is_empty() and candidate_pair.get("a") is Vector2 and candidate_pair.get("b") is Vector2:
		var ca: Vector2 = candidate_pair.get("a")
		var cb: Vector2 = candidate_pair.get("b")
		canvas.draw_line(ca, cb, Color(1.0, 0.86, 0.18, 0.58), 2.4 + snap_amount * 2.0)
		canvas.draw_circle(ca, 8.0 + snap_amount * 5.0, Color(1.0, 0.86, 0.18, 0.25))
		canvas.draw_circle(cb, 8.0 + snap_amount * 5.0, Color(1.0, 0.86, 0.18, 0.25))
		canvas.draw_arc(ca, 10.0 + snap_amount * 6.0, 0.0, TAU, 24, Color(1.0, 0.86, 0.18, 0.9), 2.0)
		canvas.draw_arc(cb, 10.0 + snap_amount * 6.0, 0.0, TAU, 24, Color(1.0, 0.86, 0.18, 0.9), 2.0)
	for highlight_key in material_highlights.keys():
		var node_index := int(highlight_key)
		if node_index < 0 or node_index >= nodes.size():
			continue
		var state := String(Dictionary(material_highlights[highlight_key]).get("state", ""))
		if state == "":
			continue
		var center := _custom_node_pos(nodes[node_index])
		var radius := _node_visual_radius(nodes[node_index])
		var color := Color(0.25, 0.95, 1.0, 0.34)
		var width := 2.0
		if state == "legal_joint" or state == "legal_socket":
			color = Color(0.28, 1.0, 0.72, 0.56)
			width = 2.4
		elif state == "same_limb":
			color = Color(0.28, 0.88, 1.0, 0.34)
			width = 1.8
		elif state == "illegal_material" or state == "illegal_group":
			color = Color(1.0, 0.16, 0.08, 0.58)
			width = 2.8 + snap_amount * 2.0
		canvas.draw_arc(center, radius + 8.0 + snap_amount * 5.0, 0.0, TAU, 34, color, width)
	for raw_warning_index in Array(board_snapshot.get("material_warning_nodes", [])):
		var warning_index := int(raw_warning_index)
		if warning_index < 0 or warning_index >= nodes.size():
			continue
		var center := _custom_node_pos(nodes[warning_index])
		var radius := _node_visual_radius(nodes[warning_index])
		canvas.draw_arc(center, radius + 14.0 + snap_amount * 10.0, 0.0, TAU, 42, Color(1.0, 0.08, 0.02, 0.9), 4.0)
		canvas.draw_string(ThemeDB.get_fallback_font(), center + Vector2(-28.0, -radius - 18.0), "材料!" if _board_is_zh() else "MAT!", HORIZONTAL_ALIGNMENT_CENTER, 56.0, 12, Color(1.0, 0.2, 0.1, 0.95))
	var tryout: Dictionary = board_snapshot.get("tryout_preview", {})
	if not tryout.is_empty():
		var target_nodes := Array(tryout.get("target_nodes", []))
		var preview_color := Color(1.0, 0.28, 0.18, 0.72) if String(tryout.get("preview_kind", "")) == "projectile" else Color(0.24, 1.0, 0.82, 0.58)
		for raw_node in target_nodes:
			var try_node := int(raw_node)
			if try_node < 0 or try_node >= nodes.size():
				continue
			var center := _custom_node_pos(nodes[try_node])
			var axis := _custom_node_axis(try_node, nodes, board_snapshot.get("edges", []))
			if axis.length() < 0.01:
				axis = Vector2.RIGHT
			axis = axis.normalized()
			var reach := clampf(float(tryout.get("range", 0.7)) * 72.0 * _custom_view_zoom(), 42.0, 220.0)
			if String(tryout.get("travel_path", "straight")) == "arc_u":
				var end := center + axis * reach
				var mid := center.lerp(end, 0.5) - axis.orthogonal() * 28.0 * _custom_view_zoom()
				canvas.draw_line(center, mid, preview_color, 2.0)
				canvas.draw_line(mid, end, preview_color, 2.0)
				canvas.draw_arc(end, 16.0 + snap_amount * 6.0, 0.0, TAU, 30, Color(1.0, 0.62, 0.16, 0.76), 2.4)
			else:
				canvas.draw_line(center, center + axis * reach, preview_color, 2.2)
				canvas.draw_circle(center + axis * reach, 6.0 + snap_amount * 3.0, Color(preview_color.r, preview_color.g, preview_color.b, 0.42))
	var sweep_bad := int(board_snapshot.get("swept_collision_count", 0)) > 0
	for raw_profile in Array(board_snapshot.get("joint_slot_profiles", [])):
		if not (raw_profile is Dictionary):
			continue
		var profile: Dictionary = raw_profile
		var pivot_value = profile.get("pivot", Vector2.ZERO)
		if not (pivot_value is Vector2):
			continue
		var pivot_topology: Vector2 = pivot_value
		var pivot: Vector2 = size * 0.5 + _custom_view_offset() + (pivot_topology - Vector2(0.5, 0.5)) * _custom_board_uniform_scale()
		var center_angle := float(profile.get("world_center_angle", 0.0))
		var half_width := float(profile.get("half_width", 0.0))
		var sweep_radius := clampf(44.0 * _custom_view_zoom(), 18.0, 92.0)
		var sweep_color := Color(1.0, 0.18, 0.08, 0.46) if sweep_bad else Color(0.24, 0.88, 1.0, 0.28)
		canvas.draw_arc(pivot, sweep_radius, center_angle - half_width, center_angle + half_width, 28, sweep_color, 2.0)
		canvas.draw_line(pivot, pivot + Vector2(cos(center_angle - half_width), sin(center_angle - half_width)) * sweep_radius, Color(sweep_color.r, sweep_color.g, sweep_color.b, 0.18), 1.0)
		canvas.draw_line(pivot, pivot + Vector2(cos(center_angle + half_width), sin(center_angle + half_width)) * sweep_radius, Color(sweep_color.r, sweep_color.g, sweep_color.b, 0.18), 1.0)

func _retained_draw_custom_component(canvas: CanvasItem, node_index: int) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	var edges: Array = board_snapshot.get("edges", [])
	if node_index < 0 or node_index >= nodes.size():
		return
	var selected_nodes: Array = board_snapshot.get("selected_nodes", [])
	var pose_mode := String(board_snapshot.get("board_tool", "layout")) == "pose"
	var pose_root := int(board_snapshot.get("pose_root_node", -1))
	var pose_downstream: Array = board_snapshot.get("pose_downstream_nodes", [])
	var node: Dictionary = nodes[node_index]
	var center: Vector2 = _custom_node_pos(node)
	var selected := node_index == int(board_snapshot.get("selected", 0)) or selected_nodes.has(node_index)
	var pose_member := pose_downstream.has(node_index)
	var illegal := bool(node.get("illegal", false))
	var binding_highlights: Dictionary = board_snapshot.get("binding_highlights", {})
	var binding_info: Dictionary = Dictionary(binding_highlights.get(str(node_index), {}))
	var binding_state := String(binding_info.get("state", ""))
	var tryout: Dictionary = board_snapshot.get("tryout_preview", {})
	var tryout_nodes: Array = Array(tryout.get("target_nodes", []))
	var tryout_member := tryout_nodes.has(node_index)
	var color := _node_material_color(node)
	if illegal:
		color = Color(1.0, 0.24, 0.16, 1.0)
	var physical_radius := _node_visual_radius(node)
	var axis := _custom_node_axis(node_index, nodes, edges)
	if axis.length() < 0.01:
		axis = Vector2.UP
	axis = axis.normalized()
	if binding_state != "":
		var bind_color := Color(0.24, 1.0, 0.82, 0.88)
		var bind_width := 3.2
		if binding_state == "binding_invalid":
			bind_color = Color(1.0, 0.34, 0.12, 0.86)
			bind_width = 2.8
		elif binding_state == "allocation_bound":
			bind_color = Color(0.72, 0.52, 1.0, 0.74)
			bind_width = 2.4
		canvas.draw_arc(center, physical_radius + 15.0 + snap_amount * 7.0, 0.0, TAU, 42, bind_color, bind_width)
		if bool(binding_info.get("selected", false)):
			canvas.draw_arc(center, physical_radius + 20.0 + snap_amount * 7.0, 0.0, TAU, 42, Color(1.0, 0.88, 0.24, 0.92), 2.0)
		var bind_text := "力" if _board_is_zh() and binding_state == "allocation_bound" else ("PWR" if binding_state == "allocation_bound" else ("点" if _board_is_zh() and binding_state == "binding_valid" else ("!" if _board_is_zh() else ("CLICK" if binding_state == "binding_valid" else "NO"))))
		canvas.draw_string(ThemeDB.get_fallback_font(), center + Vector2(-24.0, physical_radius + 24.0), bind_text, HORIZONTAL_ALIGNMENT_CENTER, 48.0, 11, bind_color)
	if tryout_member:
		var try_color := Color(1.0, 0.2, 0.18, 0.72) if String(tryout.get("state", "")) == "active" else (Color(0.32, 0.62, 1.0, 0.74) if String(tryout.get("state", "")) == "armor" else Color(0.92, 0.86, 0.4, 0.68))
		canvas.draw_arc(center, physical_radius + 24.0 + snap_amount * 5.0, -0.4, TAU - 0.4, 44, try_color, 3.0)
		canvas.draw_line(center, center + axis * (physical_radius + 38.0), try_color, 2.0)
	if selected:
		canvas.draw_arc(center, physical_radius + 12.0 + snap_amount * 8.0, 0.0, TAU, 40, Color(1.0, 0.88, 0.24, 0.72), 4.0)
		if String(node.get("slot", "")) == "joint":
			_draw_joint_motion_preview_on(canvas, center, axis, physical_radius, node)
	elif pose_member:
		canvas.draw_arc(center, physical_radius + 10.0 + snap_amount * 5.0, 0.0, TAU, 36, Color(0.34, 1.0, 0.82, 0.52), 2.8)
	if pose_mode and node_index == pose_root:
		var root_socket := AssemblyBoardRenderer.component_connection_anchor(center, node, axis, physical_radius, center - axis.normalized(), "root_joint", _node_visual_length_px(node, physical_radius), true)
		canvas.draw_arc(root_socket, maxf(7.0, physical_radius * 0.2), 0.0, TAU, 24, Color(1.0, 0.86, 0.22, 0.96), 2.4)
		canvas.draw_line(root_socket - axis.normalized().orthogonal() * 8.0, root_socket + axis.normalized().orthogonal() * 8.0, Color(1.0, 0.86, 0.22, 0.82), 1.6)
	_draw_topology_component_on(canvas, center, node, color, axis, physical_radius, snap_amount)
	if int(node.get("module_count", 1)) > 1:
		canvas.draw_arc(center, physical_radius + 7.0, -0.2, TAU - 0.2, 32, Color(0.72, 0.54, 1.0, 0.66), 2.0 + float(node.get("module_count", 1)) * 0.35)
	var label := String(node.get("label", "N%d" % (node_index + 1)))
	canvas.draw_string(ThemeDB.get_fallback_font(), center + Vector2(-36.0, -physical_radius - 8.0), label, HORIZONTAL_ALIGNMENT_CENTER, 72.0, 10, Color(0.78, 0.9, 1.0, 0.76))
	if bool(board_snapshot.get("show_node_numbers", false)):
		canvas.draw_string(ThemeDB.get_fallback_font(), center + Vector2(-8.0, 5.0), str(node_index + 1), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10, Color(0.02, 0.03, 0.04, 0.42))

func _retained_draw_custom_component_placeholder(canvas: CanvasItem, node_index: int) -> void:
	var nodes: Array = board_snapshot.get("nodes", [])
	if node_index < 0 or node_index >= nodes.size():
		return
	var node: Dictionary = nodes[node_index]
	var center := _custom_node_pos(node)
	var radius := clampf(_node_visual_radius(node), 10.0, 36.0)
	var color := _node_material_color(node)
	canvas.draw_circle(center, radius * 0.72, Color(color.r, color.g, color.b, 0.18))
	canvas.draw_arc(center, radius, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.72), 1.8)
	var axis := Vector2.RIGHT.rotated(float(node.get("axis_angle", node.get("angle", 0.0))))
	if axis.length() < 0.01:
		axis = Vector2.RIGHT
	axis = axis.normalized()
	canvas.draw_line(center - axis * radius * 0.8, center + axis * radius * 0.8, Color(color.r, color.g, color.b, 0.58), 1.4)

func _retained_draw_custom_selection(canvas: CanvasItem) -> void:
	if not bool(board_snapshot.get("selection_box_active", false)):
		return
	var selection_rect := _rect_from_points(
		board_snapshot.get("selection_box_start", Vector2.ZERO),
		board_snapshot.get("selection_box_current", Vector2.ZERO)
	)
	canvas.draw_rect(selection_rect, Color(0.25, 0.82, 1.0, 0.12), true)
	canvas.draw_rect(selection_rect, Color(0.34, 0.92, 1.0, 0.75), false, 2.0)

func _assembly_template_signature() -> String:
	return String(board_snapshot.get("assembly_template_signature", ""))


func _draw_assembly_template_overlay(canvas: CanvasItem) -> void:
	var model: Dictionary = board_snapshot.get("assembly_template_model", {})
	assembly_template_overlay_renderer.draw_overlay(canvas, size, model, _board_is_zh())


func _retained_draw_custom_hint(canvas: CanvasItem) -> void:
	_draw_assembly_template_overlay(canvas)
	var canvas_hint := "自由画布 / 零件拖入画布 / 硬规则：上游端口直连下游肌肉根部关节 / 关节内置于肌肉" if _board_is_zh() else "FREE CANVAS / drag parts in / hard link: upstream socket -> downstream muscle root joint / joints are embedded"
	canvas.draw_string(ThemeDB.get_fallback_font(), Vector2(36.0, size.y - 22.0), canvas_hint, HORIZONTAL_ALIGNMENT_LEFT, size.x - 72.0, 13, Color(0.78, 0.9, 1.0, 0.72))

func _draw_custom_board() -> void:
	retained_full_draw_fallback_count += 1
	var nodes: Array = board_snapshot.get("nodes", [])
	var edges: Array = board_snapshot.get("edges", [])
	var edge_states: Dictionary = board_snapshot.get("edge_states", {})
	var selected_nodes: Array = board_snapshot.get("selected_nodes", [])
	var socket_markers: Array = board_snapshot.get("socket_markers", [])
	var material_highlights: Dictionary = board_snapshot.get("material_highlights", {})
	var material_warning_nodes: Array = board_snapshot.get("material_warning_nodes", [])
	var pose_mode := String(board_snapshot.get("board_tool", "layout")) == "pose"
	var pose_root := int(board_snapshot.get("pose_root_node", -1))
	var pose_downstream: Array = board_snapshot.get("pose_downstream_nodes", [])
	for edge in edges:
		var a := _edge_node_a(edge)
		var b := _edge_node_b(edge)
		if a < 0 or b < 0 or a >= nodes.size() or b >= nodes.size():
			continue
		var pa_center: Vector2 = _custom_node_pos(nodes[a])
		var pb_center: Vector2 = _custom_node_pos(nodes[b])
		var axis_a := _custom_node_axis(a, nodes, edges)
		var axis_b := _custom_node_axis(b, nodes, edges)
		var pa: Vector2 = _node_connection_anchor(nodes[a], axis_a, pa_center, pb_center, _node_visual_radius(nodes[a]))
		var pb: Vector2 = _node_connection_anchor(nodes[b], axis_b, pb_center, pa_center, _node_visual_radius(nodes[b]))
		var edge_state: Dictionary = edge_states.get(_edge_key(a, b), {})
		if edge_state.has("pa") and edge_state.get("pa") is Vector2:
			pa = edge_state.get("pa")
		if edge_state.has("pb") and edge_state.get("pb") is Vector2:
			pb = edge_state.get("pb")
		var edge_length := maxf(_node_physical_length(nodes[a]), _node_physical_length(nodes[b]))
		var edge_width := maxf(1.0, (2.0 + clampf(edge_length * 9.0, 1.0, 9.0)) * _custom_view_zoom())
		var edge_invalid := bool(edge_state.get("invalid", false))
		var edge_color := Color(1.0, 0.18, 0.12, 0.76) if edge_invalid else Color(0.3, 0.92, 1.0, 0.36)
		draw_line(pa, pb, edge_color, edge_width)
		draw_line(pa, pb, Color(0.04, 0.08, 0.1, 0.76), maxf(1.0, edge_width * 0.36))
		draw_circle(pa, maxf(2.5, edge_width * 0.8), Color(1.0, 0.18, 0.12, 0.82) if edge_invalid else Color(1.0, 0.88, 0.24, 0.68))
		draw_circle(pb, maxf(2.5, edge_width * 0.8), Color(1.0, 0.18, 0.12, 0.82) if edge_invalid else Color(1.0, 0.88, 0.24, 0.68))
		draw_line(pa.lerp(pb, 0.44), pa.lerp(pb, 0.56), Color(1.0, 0.88, 0.24, 0.72) if not edge_invalid else Color(1.0, 0.18, 0.12, 0.9), edge_width + 1.4)
		if edge_invalid:
			draw_string(ThemeDB.get_fallback_font(), pa.lerp(pb, 0.5) + Vector2(-22.0, -8.0), "SNAP", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 10, Color(1.0, 0.28, 0.18, 0.95))
	for marker in socket_markers:
		if not (marker is Dictionary):
			continue
		var marker_pos = marker.get("pos", Vector2.ZERO)
		if not (marker_pos is Vector2):
			continue
		var socket_pos: Vector2 = marker_pos
		var occupied := bool(marker.get("occupied", false))
		var selected_socket := bool(marker.get("selected", false))
		var slot_key := String(marker.get("slot", ""))
		var node_key := str(int(marker.get("node", -1)))
		var highlight_state := String(Dictionary(material_highlights.get(node_key, {})).get("state", ""))
		var radius := clampf(4.0 * _custom_view_zoom(), 3.2, 7.5)
		var fill := Color(0.22, 0.98, 1.0, 0.42)
		var ring := Color(0.36, 1.0, 0.92, 0.82)
		if occupied:
			fill = Color(0.18, 1.0, 0.45, 0.62)
			ring = Color(0.84, 1.0, 0.46, 0.88)
		if selected_socket:
			radius += 1.8 + snap_amount * 2.5
			ring = Color(1.0, 0.88, 0.24, 0.96)
		if highlight_state == "legal_joint" or highlight_state == "legal_socket":
			radius += 2.0 + snap_amount * 2.0
			fill = Color(0.1, 1.0, 0.76, 0.52)
			ring = Color(0.36, 1.0, 0.78, 0.96)
		elif highlight_state == "illegal_material" or highlight_state == "illegal_group":
			radius += 2.6 + snap_amount * 3.2
			fill = Color(1.0, 0.12, 0.06, 0.38)
			ring = Color(1.0, 0.24, 0.12, 0.98)
		if slot_key == "joint":
			draw_arc(socket_pos, radius + 2.2, 0.0, TAU, 18, ring, 1.5)
			draw_line(socket_pos - Vector2(radius, 0.0), socket_pos + Vector2(radius, 0.0), ring, 1.2)
			draw_line(socket_pos - Vector2(0.0, radius), socket_pos + Vector2(0.0, radius), ring, 1.2)
		else:
			draw_circle(socket_pos, radius, fill)
			draw_arc(socket_pos, radius + 1.6, 0.0, TAU, 22, ring, 1.4)
		if occupied:
			draw_line(socket_pos - Vector2(radius * 0.48, 0.0), socket_pos + Vector2(radius * 0.48, 0.0), Color(0.9, 1.0, 0.78, 0.82), 1.2)
	var candidate_pair: Dictionary = board_snapshot.get("candidate_socket_pair", {})
	if not candidate_pair.is_empty() and candidate_pair.get("a") is Vector2 and candidate_pair.get("b") is Vector2:
		var ca: Vector2 = candidate_pair.get("a")
		var cb: Vector2 = candidate_pair.get("b")
		draw_line(ca, cb, Color(1.0, 0.86, 0.18, 0.58), 2.4 + snap_amount * 2.0)
		draw_circle(ca, 8.0 + snap_amount * 5.0, Color(1.0, 0.86, 0.18, 0.25))
		draw_circle(cb, 8.0 + snap_amount * 5.0, Color(1.0, 0.86, 0.18, 0.25))
		draw_arc(ca, 10.0 + snap_amount * 6.0, 0.0, TAU, 24, Color(1.0, 0.86, 0.18, 0.9), 2.0)
		draw_arc(cb, 10.0 + snap_amount * 6.0, 0.0, TAU, 24, Color(1.0, 0.86, 0.18, 0.9), 2.0)
	for highlight_key in material_highlights.keys():
		var node_index := int(highlight_key)
		if node_index < 0 or node_index >= nodes.size():
			continue
		var state := String(Dictionary(material_highlights[highlight_key]).get("state", ""))
		if state == "":
			continue
		var center := _custom_node_pos(nodes[node_index])
		var radius := _node_visual_radius(nodes[node_index])
		var color := Color(0.25, 0.95, 1.0, 0.34)
		var width := 2.0
		if state == "legal_joint" or state == "legal_socket":
			color = Color(0.28, 1.0, 0.72, 0.56)
			width = 2.4
		elif state == "same_limb":
			color = Color(0.28, 0.88, 1.0, 0.34)
			width = 1.8
		elif state == "illegal_material" or state == "illegal_group":
			color = Color(1.0, 0.16, 0.08, 0.58)
			width = 2.8 + snap_amount * 2.0
		draw_arc(center, radius + 8.0 + snap_amount * 5.0, 0.0, TAU, 34, color, width)
	for raw_warning_index in material_warning_nodes:
		var warning_index := int(raw_warning_index)
		if warning_index < 0 or warning_index >= nodes.size():
			continue
		var center := _custom_node_pos(nodes[warning_index])
		var radius := _node_visual_radius(nodes[warning_index])
		draw_arc(center, radius + 14.0 + snap_amount * 10.0, 0.0, TAU, 42, Color(1.0, 0.08, 0.02, 0.9), 4.0)
		draw_string(ThemeDB.get_fallback_font(), center + Vector2(-28.0, -radius - 18.0), "材料!" if _board_is_zh() else "MAT!", HORIZONTAL_ALIGNMENT_CENTER, 56.0, 12, Color(1.0, 0.2, 0.1, 0.95))
	var sweep_bad := int(board_snapshot.get("swept_collision_count", 0)) > 0
	for raw_profile in Array(board_snapshot.get("joint_slot_profiles", [])):
		if not (raw_profile is Dictionary):
			continue
		var profile: Dictionary = raw_profile
		var pivot_value = profile.get("pivot", Vector2.ZERO)
		if not (pivot_value is Vector2):
			continue
		var pivot_topology: Vector2 = pivot_value
		var pivot: Vector2 = size * 0.5 + _custom_view_offset() + (pivot_topology - Vector2(0.5, 0.5)) * _custom_board_uniform_scale()
		var center_angle := float(profile.get("world_center_angle", 0.0))
		var half_width := float(profile.get("half_width", 0.0))
		var sweep_radius := clampf(44.0 * _custom_view_zoom(), 18.0, 92.0)
		var sweep_color := Color(1.0, 0.18, 0.08, 0.46) if sweep_bad else Color(0.24, 0.88, 1.0, 0.28)
		draw_arc(pivot, sweep_radius, center_angle - half_width, center_angle + half_width, 28, sweep_color, 2.0)
		draw_line(pivot, pivot + Vector2(cos(center_angle - half_width), sin(center_angle - half_width)) * sweep_radius, Color(sweep_color.r, sweep_color.g, sweep_color.b, 0.18), 1.0)
		draw_line(pivot, pivot + Vector2(cos(center_angle + half_width), sin(center_angle + half_width)) * sweep_radius, Color(sweep_color.r, sweep_color.g, sweep_color.b, 0.18), 1.0)
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		var center: Vector2 = _custom_node_pos(node)
		var selected := i == int(board_snapshot.get("selected", 0)) or selected_nodes.has(i)
		var pose_member := pose_downstream.has(i)
		var illegal := bool(node.get("illegal", false))
		var color := _node_material_color(node)
		if illegal:
			color = Color(1.0, 0.24, 0.16, 1.0)
		var physical_radius := _node_visual_radius(node)
		var axis := _custom_node_axis(i, nodes, edges)
		if axis.length() < 0.01:
			axis = Vector2.UP
		axis = axis.normalized()
		if selected:
			draw_arc(center, physical_radius + 12.0 + snap_amount * 8.0, 0.0, TAU, 40, Color(1.0, 0.88, 0.24, 0.72), 4.0)
			if String(node.get("slot", "")) == "joint":
				_draw_joint_motion_preview(center, axis, physical_radius, node)
		elif pose_member:
			draw_arc(center, physical_radius + 10.0 + snap_amount * 5.0, 0.0, TAU, 36, Color(0.34, 1.0, 0.82, 0.52), 2.8)
		if pose_mode and i == pose_root:
			var root_socket := AssemblyBoardRenderer.component_connection_anchor(center, node, axis, physical_radius, center - axis.normalized(), "root_joint", _node_visual_length_px(node, physical_radius), true)
			draw_arc(root_socket, maxf(7.0, physical_radius * 0.2), 0.0, TAU, 24, Color(1.0, 0.86, 0.22, 0.96), 2.4)
			draw_line(root_socket - axis.normalized().orthogonal() * 8.0, root_socket + axis.normalized().orthogonal() * 8.0, Color(1.0, 0.86, 0.22, 0.82), 1.6)
		_draw_topology_component(center, node, color, axis, physical_radius, snap_amount)
		if int(node.get("module_count", 1)) > 1:
			draw_arc(center, physical_radius + 7.0, -0.2, TAU - 0.2, 32, Color(0.72, 0.54, 1.0, 0.66), 2.0 + float(node.get("module_count", 1)) * 0.35)
		var label := String(node.get("label", "N%d" % (i + 1)))
		draw_string(ThemeDB.get_fallback_font(), center + Vector2(-36.0, -physical_radius - 8.0), label, HORIZONTAL_ALIGNMENT_CENTER, 72.0, 10, Color(0.78, 0.9, 1.0, 0.76))
		if bool(board_snapshot.get("show_node_numbers", false)):
			draw_string(ThemeDB.get_fallback_font(), center + Vector2(-8.0, 5.0), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10, Color(0.02, 0.03, 0.04, 0.42))
	if bool(board_snapshot.get("selection_box_active", false)):
		var selection_rect := _rect_from_points(
			board_snapshot.get("selection_box_start", Vector2.ZERO),
			board_snapshot.get("selection_box_current", Vector2.ZERO)
		)
		draw_rect(selection_rect, Color(0.25, 0.82, 1.0, 0.12), true)
		draw_rect(selection_rect, Color(0.34, 0.92, 1.0, 0.75), false, 2.0)
	_draw_assembly_template_overlay(self)
	var canvas_hint := "自由画布 / 零件拖入画布 / 硬规则：上游端口直连下游肌肉根部关节 / 关节内置于肌肉" if _board_is_zh() else "FREE CANVAS / drag parts in / hard link: upstream socket -> downstream muscle root joint / joints are embedded"
	draw_string(ThemeDB.get_fallback_font(), Vector2(36.0, size.y - 22.0), canvas_hint, HORIZONTAL_ALIGNMENT_LEFT, size.x - 72.0, 13, Color(0.78, 0.9, 1.0, 0.72))

func _rect_from_points(a, b) -> Rect2:
	var point_a: Vector2 = a if a is Vector2 else Vector2.ZERO
	var point_b: Vector2 = b if b is Vector2 else point_a
	var pos := Vector2(minf(point_a.x, point_b.x), minf(point_a.y, point_b.y))
	var rect_size := Vector2(absf(point_a.x - point_b.x), absf(point_a.y - point_b.y))
	return Rect2(pos, rect_size)

func _custom_node_pos(node: Dictionary) -> Vector2:
	var pos = node.get("visual_pos", node.get("pos", Vector2(0.5, 0.5)))
	if pos is Vector2:
		var clamped := _custom_clamp_topology_position(pos)
		return size * 0.5 + _custom_view_offset() + (clamped - Vector2(0.5, 0.5)) * _custom_board_uniform_scale()
	return size * 0.5

func _custom_board_uniform_scale() -> float:
	return _custom_board_base_scale() * _custom_view_zoom()

func _custom_board_base_scale() -> float:
	return maxf(1.0, minf(size.x - CUSTOM_BOARD_MARGIN * 2.0, size.y - CUSTOM_BOARD_MARGIN * 2.0))

func _custom_view_zoom() -> float:
	return clampf(float(board_snapshot.get("view_zoom", 1.0)), EDITOR_BOARD_ZOOM_MIN, EDITOR_BOARD_ZOOM_MAX)

func _custom_view_offset() -> Vector2:
	var offset = board_snapshot.get("view_offset", Vector2.ZERO)
	return offset if offset is Vector2 else Vector2.ZERO

func _barrier_view_zoom() -> float:
	return clampf(float(board_snapshot.get("view_zoom", 1.0)), EDITOR_BOARD_ZOOM_MIN, EDITOR_BOARD_ZOOM_MAX)

func _barrier_view_offset() -> Vector2:
	var offset = board_snapshot.get("view_offset", Vector2.ZERO)
	return offset if offset is Vector2 else Vector2.ZERO

func _barrier_columns() -> int:
	return maxi(1, int(board_snapshot.get("barrier_columns", BARRIER_BOARD_COLUMNS)))

func _barrier_rows() -> int:
	return maxi(1, int(board_snapshot.get("barrier_rows", BARRIER_BOARD_ROWS)))

func _barrier_board_rect() -> Rect2:
	var margin := Vector2(8.0, 44.0)
	var available := Vector2(maxf(64.0, size.x - margin.x * 2.0), maxf(64.0, size.y - margin.y * 2.0))
	var blueprint_width := maxf(1.0, float(board_snapshot.get("barrier_width", BARRIER_BLUEPRINT_WIDTH)))
	var blueprint_height := maxf(1.0, float(board_snapshot.get("barrier_height", BARRIER_BLUEPRINT_HEIGHT)))
	var aspect := blueprint_width / blueprint_height
	var rect_size := available
	if rect_size.x / maxf(1.0, rect_size.y) > aspect:
		rect_size.x = rect_size.y * aspect
	else:
		rect_size.y = rect_size.x / aspect
	rect_size *= _barrier_view_zoom()
	return Rect2((size - rect_size) * 0.5 + _barrier_view_offset(), rect_size)

func _barrier_cell_rect(index: int) -> Rect2:
	var rect := _barrier_board_rect()
	var columns := _barrier_columns()
	var rows := _barrier_rows()
	var cell_size := Vector2(rect.size.x / float(columns), rect.size.y / float(rows))
	var clamped := clampi(index, 0, columns * rows - 1)
	var x := clamped % columns
	var y := int(floori(float(clamped) / float(columns)))
	return Rect2(rect.position + Vector2(float(x), float(y)) * cell_size, cell_size)

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float = 1.0, dash: float = 8.0, gap: float = 6.0) -> void:
	var delta := to - from
	var length := delta.length()
	if length <= 0.01:
		return
	var direction := delta / length
	var cursor := 0.0
	while cursor < length:
		var segment_end := minf(cursor + dash, length)
		draw_line(from + direction * cursor, from + direction * segment_end, color, width)
		cursor += dash + gap

func _custom_clamp_topology_position(pos: Vector2) -> Vector2:
	return Vector2(clampf(pos.x, 0.0, 1.0), clampf(pos.y, 0.0, 1.0))

func _custom_node_axis(node_index: int, nodes: Array, edges: Array) -> Vector2:
	if nodes[node_index] is Dictionary and Dictionary(nodes[node_index]).has("axis"):
		var stored_axis = Dictionary(nodes[node_index]).get("axis")
		if stored_axis is Vector2 and Vector2(stored_axis).length() > 0.01:
			return Vector2(stored_axis).normalized()
	var slot_key := String(nodes[node_index].get("slot", ""))
	var material_class := String(nodes[node_index].get("material_class", "")).to_lower()
	if slot_key == "muscle" and (bool(nodes[node_index].get("is_torso", false)) or material_class == "torso"):
		return Vector2.RIGHT
	var center := _custom_node_pos(nodes[node_index])
	var neighbors := _custom_node_neighbors(node_index, nodes, edges)
	if neighbors.size() >= 2:
		var first := _custom_node_pos(nodes[int(neighbors[0])])
		var second := _custom_node_pos(nodes[int(neighbors[1])])
		var paired_axis := second - first
		if paired_axis.length() > 0.01:
			return paired_axis
	if neighbors.size() == 1:
		var neighbor_pos := _custom_node_pos(nodes[int(neighbors[0])])
		var outward := center - neighbor_pos
		if outward.length() > 0.01:
			return outward
	var terminal_like := slot_key == "muscle" and (bool(nodes[node_index].get("terminal_weapon", false)) or material_class in ["weapon", "gun", "missile_launcher", "web_gun", "racket"] or int(nodes[node_index].get("connection_ends", 2)) <= 1)
	if slot_key == "limb_muscle" or terminal_like:
		return Vector2.RIGHT
	return center - size * 0.5

func _custom_node_neighbors(node_index: int, nodes: Array, edges: Array) -> Array:
	var neighbors: Array = []
	for edge in edges:
		var a := _edge_node_a(edge)
		var b := _edge_node_b(edge)
		if a == node_index and b >= 0 and b < nodes.size():
			neighbors.append(b)
		elif b == node_index and a >= 0 and a < nodes.size():
			neighbors.append(a)
	return neighbors

func _node_connection_anchor(node: Dictionary, axis: Vector2, center: Vector2, toward: Vector2, physical_radius: float) -> Vector2:
	var visual_length_px := _node_visual_length_px(node, physical_radius)
	return AssemblyBoardRenderer.component_connection_anchor(center, node, axis, physical_radius, toward, "", visual_length_px, true)

func _node_edge_extent_px(node: Dictionary, fallback_radius: float) -> float:
	var extent_units := float(node.get("edge_extent_units", -1.0))
	if extent_units >= 0.0:
		var distance_scale := maxf(0.001, float(board_snapshot.get("distance_scale", TOPOLOGY_BOARD_PHYSICAL_UNITS)))
		return extent_units / distance_scale * _custom_board_uniform_scale()
	var slot_key := String(node.get("slot", ""))
	if slot_key == "joint":
		return 0.0
	if slot_key == "limb_muscle":
		return _node_visual_length_px(node, fallback_radius) * 0.5
	if slot_key == "muscle":
		return _node_visual_length_px(node, fallback_radius) * 0.5
	return fallback_radius * 0.62

func _node_material_style(node: Dictionary) -> String:
	return PartArt.material_style_for(node)

func _node_material_color(node: Dictionary) -> Color:
	return PartArt.material_color_for(_node_material_style(node), String(node.get("slot", "")))

func _node_physical_length(node: Dictionary) -> float:
	if node.has("component_length"):
		return maxf(0.04, float(node.get("component_length", 0.04)))
	return maxf(
		0.04,
		float(node.get("joint_length", 0.08))
		+ float(node.get("muscle_length", 0.24))
		+ float(node.get("terminal_length", 0.0))
	)

func _node_visual_radius(node: Dictionary) -> float:
	var length := _node_physical_length(node)
	var radius := maxf(0.0, float(node.get("component_radius", 0.04)))
	var mass := maxf(0.0, float(node.get("component_mass", 0.0)))
	var size_class := String(node.get("size_class", "")).to_lower()
	var class_bonus := 0.0
	match size_class:
		"nano":
			class_bonus = -7.0
		"micro", "xs":
			class_bonus = -4.0
		"small", "s":
			class_bonus = 1.0
		"heavy", "large", "l":
			class_bonus = 16.0
		"monster", "xl":
			class_bonus = 30.0
		"kaiju", "colossus", "leviathan":
			class_bonus = 44.0
	var visual_radius := clampf(7.0 + length * 46.0 + radius * 58.0 + sqrt(mass) * 2.4 + class_bonus, 8.0, 112.0)
	var base_radius := visual_radius
	if String(node.get("slot", "")) == "joint":
		base_radius = clampf(visual_radius * 0.22, 3.0, 14.0)
	elif String(node.get("slot", "")) == "limb_muscle":
		base_radius = clampf(visual_radius * 0.42, 4.0, 44.0)
	return clampf(base_radius * _custom_view_zoom(), 2.6, 320.0)

func _node_visual_length_px(node: Dictionary, fallback_radius: float) -> float:
	var units := _node_physical_length(node)
	var length_px := units / maxf(0.001, TOPOLOGY_BOARD_PHYSICAL_UNITS) * _custom_board_uniform_scale()
	var zoom := _custom_view_zoom()
	if String(node.get("slot", "")) == "limb_muscle":
		return clampf(maxf(18.0 * zoom, length_px), 7.0, 260.0 * zoom)
	var size_class := String(node.get("size_class", "")).to_lower()
	var class_mult := 1.0
	match size_class:
		"nano", "micro", "xs":
			class_mult = 0.74
		"small", "s":
			class_mult = 0.88
		"large", "heavy", "l":
			class_mult = 1.18
		"monster", "xl", "kaiju", "colossus", "leviathan":
			class_mult = 1.42
	return clampf(maxf(fallback_radius * 1.45, length_px * class_mult), 7.0, 260.0 * zoom)

func _edge_key(a: int, b: int) -> String:
	return "%d:%d" % [mini(a, b), maxi(a, b)]

func _draw_topology_component(center: Vector2, node: Dictionary, color: Color, axis: Vector2, physical_radius: float, pulse: float) -> void:
	_draw_topology_component_on(self, center, node, color, axis, physical_radius, pulse)

func _draw_topology_component_on(canvas: CanvasItem, center: Vector2, node: Dictionary, color: Color, axis: Vector2, physical_radius: float, pulse: float) -> void:
	var visual_length_px := _node_visual_length_px(node, physical_radius)
	AssemblyBoardRenderer.draw_component(canvas, center, node, color, axis, physical_radius, pulse, visual_length_px, true)
	if AssemblyBoardRenderer.component_kind(node) == "torso":
		var display_radius := AssemblyBoardRenderer.component_display_radius(node, physical_radius, visual_length_px, true)
		_draw_torso_slot_badges_on(canvas, center, axis, color, display_radius, node)

func _draw_torso_slot_badges(center: Vector2, axis: Vector2, color: Color, radius: float, node: Dictionary) -> void:
	_draw_torso_slot_badges_on(self, center, axis, color, radius, node)

func _draw_torso_slot_badges_on(canvas: CanvasItem, center: Vector2, axis: Vector2, color: Color, radius: float, node: Dictionary) -> void:
	var software_slots := int(node.get("module_slots", 0))
	var plugin_slots := int(node.get("torso_slots", 0))
	if software_slots <= 0 and plugin_slots <= 0:
		return
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	var start := center - right * minf(radius * 0.32, 22.0)
	var pitch := clampf(radius * 0.13, 4.0, 6.2)
	var max_draw := 10
	for i in range(mini(software_slots, max_draw)):
		var p := start + right * float(i) * pitch - forward * minf(radius * 0.24, 17.0)
		canvas.draw_rect(Rect2(p - Vector2(2.6, 2.6), Vector2(5.2, 5.2)), Color(0.72, 0.46, 1.0, 0.92), true)
	for i in range(mini(plugin_slots, max_draw)):
		var p := start + right * float(i) * pitch + forward * minf(radius * 0.24, 17.0)
		canvas.draw_rect(Rect2(p - Vector2(2.6, 2.6), Vector2(5.2, 5.2)), Color(0.32, 1.0, 0.72, 0.92), true)

func _draw_joint_motion_preview(center: Vector2, axis: Vector2, radius: float, node: Dictionary) -> void:
	_draw_joint_motion_preview_on(self, center, axis, radius, node)

func _draw_joint_motion_preview_on(canvas: CanvasItem, center: Vector2, axis: Vector2, radius: float, node: Dictionary) -> void:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var label := "%s %s" % [String(node.get("component_name", node.get("label", ""))).to_lower(), String(node.get("shape", "")).to_lower()]
	var sweep := PI
	if label.contains("90"):
		sweep = PI * 0.5
	elif label.contains("360"):
		sweep = TAU
	var base_angle := forward.angle()
	var start_angle := base_angle - sweep * 0.5
	var end_angle := base_angle + sweep * 0.5
	var preview_span_px := 0.0
	if node.has("downstream_rotation_radius_units"):
		var distance_scale := maxf(0.001, float(board_snapshot.get("distance_scale", TOPOLOGY_BOARD_PHYSICAL_UNITS)))
		preview_span_px = float(node.get("downstream_rotation_radius_units", 0.0)) / distance_scale * _custom_board_uniform_scale()
	var preview_radius := maxf(radius + 22.0, preview_span_px)
	canvas.draw_arc(center, preview_radius, start_angle, end_angle, 42, Color(1.0, 0.84, 0.22, 0.34), 2.2)
	var phase := sin(motion_phase * TAU * 0.65)
	var preview_dir := forward.rotated(phase * sweep * 0.5)
	var ghost_start := center + preview_dir * radius
	var ghost_end := center + preview_dir * maxf(preview_radius, radius + 34.0)
	canvas.draw_line(ghost_start, ghost_end, Color(1.0, 0.9, 0.24, 0.52), 3.0)
	canvas.draw_circle(ghost_end, maxf(4.0, radius * 0.16), Color(1.0, 0.9, 0.24, 0.72))
	canvas.draw_string(ThemeDB.get_fallback_font(), center + Vector2(-54.0, -preview_radius - 10.0), "ROT" if not _board_is_zh() else "转动预览", HORIZONTAL_ALIGNMENT_CENTER, 108.0, 11, Color(1.0, 0.9, 0.24, 0.72))

func _slot_position(part_key: String) -> Vector2:
	var positions := {
		"left_claw": Vector2(76.0, 66.0),
		"right_claw": Vector2(size.x - 76.0, 66.0),
		"front_left_leg": Vector2(120.0, 156.0),
		"front_right_leg": Vector2(size.x - 120.0, 156.0),
		"rear_left_leg": Vector2(170.0, 244.0),
		"rear_right_leg": Vector2(size.x - 170.0, 244.0),
	}
	return positions.get(part_key, size * 0.5)

func _draw_socket(center: Vector2, selected: bool, illegal: bool, pulse: float) -> void:
	var color := Color(0.22, 0.38, 0.44, 0.98)
	if selected:
		color = Color(0.25, 0.88, 1.0, 0.98)
	if illegal:
		color = Color(1.0, 0.25, 0.18, 0.98)
	draw_circle(center, 32.0 + pulse * 8.0, color.darkened(0.45))
	draw_circle(center, 23.0 + pulse * 5.0, color)
	draw_arc(center, 40.0 + pulse * 10.0, -0.5, TAU - 0.5, 38, Color(1.0, 0.86, 0.22, 0.16 + pulse * 0.62), 3.0)

func _draw_mini_component(center: Vector2, item: Dictionary, pulse: float) -> void:
	var damage_type := String(item.get("damage_type", "blunt"))
	var color := Color(0.85, 0.9, 0.94, 1.0)
	match damage_type:
		"bullet":
			color = Color(1.0, 0.1, 0.08, 1.0)
		"chemical":
			color = Color(1.0, 0.88, 0.12, 1.0)
		"laser":
			color = Color(0.22, 0.82, 1.0, 1.0)
		"pierce":
			color = Color(0.9, 0.32, 1.0, 1.0)
		"tear":
			color = Color(0.18, 1.0, 0.62, 1.0)
	var blade_count := int(item.get("blade_count", 1))
	if blade_count > 1:
		draw_arc(center + Vector2(-7.0, 0.0), 20.0 + pulse * 4.0, -2.2, 0.6, 20, color, 5.0)
		draw_arc(center + Vector2(7.0, 0.0), 20.0 + pulse * 4.0, PI - 0.6, PI + 2.2, 20, color, 5.0)
	elif bool(item.get("projectile", false)):
		draw_rect(Rect2(center + Vector2(-20.0, -8.0), Vector2(34.0, 16.0)), color.darkened(0.35), true)
		draw_rect(Rect2(center + Vector2(10.0, -4.0), Vector2(24.0, 8.0)), color, true)
	else:
		draw_line(center + Vector2(-20.0, 12.0), center + Vector2(20.0, -12.0), color, 7.0)
	draw_circle(center, 5.0 + pulse * 4.0, Color.WHITE.lerp(color, 0.45))
