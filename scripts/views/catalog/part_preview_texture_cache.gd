class_name PartPreviewTextureCache
extends RefCounted

const PartPreviewTextureRenderCanvas = preload("res://scripts/views/catalog/part_preview_texture_render_canvas.gd")

static var textures := {}
static var pending_requests := {}
static var pending_order: Array = []
static var lru_order: Array = []
static var hit_count := 0
static var miss_count := 0
static var render_count := 0
static var submit_count := 0
static var capture_count := 0
static var force_draw_count := 0
static var queue_hit_count := 0
static var process_count := 0
static var subviewport_create_count := 0
static var last_captured_keys: Array = []
static var active_request := {}
static var max_entries := 256
static var render_viewport: SubViewport
static var render_canvas: PartPreviewTextureRenderCanvas

static func key_for(slot_key: String, part: Dictionary, selected: bool, pulse: float, preview_size: Vector2) -> String:
	var size_key := "%dx%d" % [maxi(1, int(round(preview_size.x))), maxi(1, int(round(preview_size.y)))]
	# Selection and pulse are lightweight overlay states. Keeping them out of
	# the body-art key prevents hover/selection animation from invalidating
	# the expensive renderer cache while scrolling the catalog.
	return "%s|%s|%s|%s|%s|%s|%s" % [
		slot_key,
		String(part.get("name", "")),
		String(part.get("size_tier", part.get("size_class", part.get("slot_volume_tier", "")))),
		String(part.get("material_visual", part.get("material_class", ""))),
		String(part.get("weapon_family", part.get("gun_kind", ""))),
		"body",
		size_key,
	]

static func get_or_create(owner: Node, slot_key: String, part: Dictionary, selected: bool, pulse: float, preview_size: Vector2) -> Texture2D:
	return request_preview(owner, slot_key, part, selected, pulse, preview_size)

static func request_preview(_owner: Node, slot_key: String, part: Dictionary, selected: bool, pulse: float, preview_size: Vector2) -> Texture2D:
	if DisplayServer.get_name().to_lower() == "headless":
		return null
	var safe_size := Vector2(maxf(8.0, preview_size.x), maxf(8.0, preview_size.y))
	var cache_key := key_for(slot_key, part, selected, pulse, safe_size)
	if textures.has(cache_key):
		hit_count += 1
		_touch_lru(cache_key)
		return textures[cache_key]
	miss_count += 1
	if pending_requests.has(cache_key):
		queue_hit_count += 1
		return null
	pending_requests[cache_key] = {
		"slot": slot_key,
		"part": part,
		"selected": selected,
		"pulse": pulse,
		"size": safe_size,
	}
	pending_order.append(cache_key)
	return null

static func peek_preview(slot_key: String, part: Dictionary, selected: bool, pulse: float, preview_size: Vector2) -> Texture2D:
	var safe_size := Vector2(maxf(8.0, preview_size.x), maxf(8.0, preview_size.y))
	var cache_key := key_for(slot_key, part, selected, pulse, safe_size)
	if textures.has(cache_key):
		_touch_lru(cache_key)
		return textures[cache_key]
	return null

static func clear_pending_requests() -> void:
	pending_requests.clear()
	pending_order.clear()
	active_request = {}

static func clear_all(release_renderer: bool = true) -> void:
	textures.clear()
	lru_order.clear()
	last_captured_keys.clear()
	clear_pending_requests()
	if release_renderer and render_viewport != null:
		if is_instance_valid(render_viewport):
			var parent := render_viewport.get_parent()
			if parent != null:
				parent.remove_child(render_viewport)
			render_viewport.queue_free()
		render_viewport = null
		render_canvas = null

static func process_queue(owner: Node, budget: int = 2) -> int:
	last_captured_keys = []
	if DisplayServer.get_name().to_lower() == "headless":
		active_request = {}
		pending_requests.clear()
		pending_order.clear()
		return 0
	var captured := _capture_active_request()
	if budget <= 0:
		process_count += captured
		return captured
	var submitted := 0
	while active_request.is_empty() and submitted < budget and not pending_order.is_empty():
		var cache_key := String(pending_order.pop_front())
		if not pending_requests.has(cache_key):
			continue
		if textures.has(cache_key):
			pending_requests.erase(cache_key)
			_touch_lru(cache_key)
			continue
		var request: Dictionary = pending_requests[cache_key]
		pending_requests.erase(cache_key)
		var request_size: Vector2 = request.get("size", Vector2(64.0, 48.0))
		if _submit_render(owner, cache_key, String(request.get("slot", "")), Dictionary(request.get("part", {})), false, 0.0, request_size):
			submitted += 1
	process_count += captured + submitted
	return captured

static func _touch_lru(cache_key: String) -> void:
	lru_order.erase(cache_key)
	lru_order.append(cache_key)

static func _prune_lru() -> void:
	while lru_order.size() > max_entries:
		var old_key := String(lru_order.pop_front())
		textures.erase(old_key)

static func _submit_render(owner: Node, cache_key: String, slot_key: String, part: Dictionary, selected: bool, pulse: float, preview_size: Vector2) -> bool:
	if DisplayServer.get_name().to_lower() == "headless":
		return false
	var tree: SceneTree = null
	if owner != null and owner.is_inside_tree():
		tree = owner.get_tree()
	else:
		tree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	_ensure_renderer(tree, preview_size)
	if render_viewport == null or render_canvas == null:
		return false
	var viewport_size := Vector2i(maxi(8, int(ceil(preview_size.x))), maxi(8, int(ceil(preview_size.y))))
	if render_viewport.size != viewport_size:
		render_viewport.size = viewport_size
	render_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	render_canvas.configure(slot_key, part, selected, pulse, preview_size)
	active_request = {
		"key": cache_key,
		"submit_frame": Engine.get_process_frames(),
	}
	submit_count += 1
	return true

static func _capture_active_request() -> int:
	if active_request.is_empty() or render_viewport == null:
		return 0
	if Engine.get_process_frames() <= int(active_request.get("submit_frame", -1)):
		return 0
	var cache_key := String(active_request.get("key", ""))
	active_request = {}
	if cache_key == "" or textures.has(cache_key):
		return 0
	var viewport_texture := render_viewport.get_texture()
	if viewport_texture == null:
		return 0
	var image := viewport_texture.get_image()
	if image == null or image.is_empty():
		return 0
	render_count += 1
	capture_count += 1
	textures[cache_key] = ImageTexture.create_from_image(image)
	_touch_lru(cache_key)
	_prune_lru()
	last_captured_keys.append(cache_key)
	return 1

static func _ensure_renderer(tree: SceneTree, preview_size: Vector2) -> void:
	if render_viewport != null and is_instance_valid(render_viewport) and render_canvas != null and is_instance_valid(render_canvas):
		return
	render_viewport = SubViewport.new()
	render_viewport.disable_3d = true
	render_viewport.transparent_bg = true
	render_viewport.size = Vector2i(maxi(8, int(ceil(preview_size.x))), maxi(8, int(ceil(preview_size.y))))
	render_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	render_canvas = PartPreviewTextureRenderCanvas.new()
	render_viewport.add_child(render_canvas)
	tree.root.add_child(render_viewport)
	subviewport_create_count += 1
