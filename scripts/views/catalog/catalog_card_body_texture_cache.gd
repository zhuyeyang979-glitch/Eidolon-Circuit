class_name CatalogCardBodyTextureCache
extends RefCounted

const CatalogCardBodyTextureRenderCanvas = preload("res://scripts/views/catalog/catalog_card_body_texture_render_canvas.gd")
const CATALOG_CARD_BODY_TEXTURE_STYLE_REVISION := 2

static var textures := {}
static var pending_requests := {}
static var pending_order: Array = []
static var lru_order: Array = []
static var active_request := {}
static var render_viewport: SubViewport
static var render_canvas: CatalogCardBodyTextureRenderCanvas
static var max_entries := 256
static var submit_count := 0
static var capture_count := 0
static var hit_count := 0
static var miss_count := 0
static var queue_hit_count := 0
static var last_captured_keys: Array = []
static var request_time_usec := 0
static var submit_time_usec := 0
static var capture_time_usec := 0
static var last_request_usec := 0
static var last_submit_usec := 0
static var last_capture_usec := 0
static var prewarm_request_count := 0

static func key_for(slot_key: String, part: Dictionary, display_name: String, line_a: String, line_b: String, selected: bool, preview_size: Vector2) -> String:
	var size_key := "%dx%d" % [maxi(1, int(round(preview_size.x))), maxi(1, int(round(preview_size.y)))]
	return "%s|%s|%s|%s|%s|%s|%s" % [
		str(CATALOG_CARD_BODY_TEXTURE_STYLE_REVISION),
		slot_key,
		String(part.get("stable_key", part.get("name", ""))),
		display_name,
		line_a,
		line_b,
		size_key,
	]

static func request_preview(owner: Node, slot_key: String, part: Dictionary, display_name: String, line_a: String, line_b: String, selected: bool, preview_size: Vector2) -> Texture2D:
	var started := Time.get_ticks_usec()
	if DisplayServer.get_name().to_lower() == "headless":
		last_request_usec = Time.get_ticks_usec() - started
		request_time_usec += last_request_usec
		return null
	var safe_size := Vector2(maxf(8.0, preview_size.x), maxf(8.0, preview_size.y))
	var cache_key := key_for(slot_key, part, display_name, line_a, line_b, selected, safe_size)
	if textures.has(cache_key):
		hit_count += 1
		_touch_lru(cache_key)
		last_request_usec = Time.get_ticks_usec() - started
		request_time_usec += last_request_usec
		return textures[cache_key]
	miss_count += 1
	if pending_requests.has(cache_key):
		queue_hit_count += 1
		last_request_usec = Time.get_ticks_usec() - started
		request_time_usec += last_request_usec
		return null
	pending_requests[cache_key] = {
		"display_name": display_name,
		"line_a": line_a,
		"line_b": line_b,
		"selected": false,
		"size": safe_size,
	}
	pending_order.append(cache_key)
	last_request_usec = Time.get_ticks_usec() - started
	request_time_usec += last_request_usec
	return null

static func peek_preview(slot_key: String, part: Dictionary, display_name: String, line_a: String, line_b: String, selected: bool, preview_size: Vector2) -> Texture2D:
	var safe_size := Vector2(maxf(8.0, preview_size.x), maxf(8.0, preview_size.y))
	var cache_key := key_for(slot_key, part, display_name, line_a, line_b, selected, safe_size)
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

static func process_queue(owner: Node, budget: int = 1) -> int:
	last_captured_keys = []
	if DisplayServer.get_name().to_lower() == "headless":
		active_request = {}
		pending_requests.clear()
		pending_order.clear()
		return 0
	var captured := _capture_active_request()
	if budget <= 0:
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
		var request_size: Vector2 = request.get("size", Vector2(96.0, 32.0))
		if _submit_render(owner, cache_key, String(request.get("display_name", "")), String(request.get("line_a", "")), String(request.get("line_b", "")), bool(request.get("selected", false)), request_size):
			submitted += 1
	return captured + submitted

static func _submit_render(owner: Node, cache_key: String, display_name: String, line_a: String, line_b: String, selected: bool, preview_size: Vector2) -> bool:
	var started := Time.get_ticks_usec()
	var tree: SceneTree = null
	if owner != null and owner.is_inside_tree():
		tree = owner.get_tree()
	else:
		tree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		last_submit_usec = Time.get_ticks_usec() - started
		submit_time_usec += last_submit_usec
		return false
	_ensure_renderer(tree, preview_size)
	if render_viewport == null or render_canvas == null:
		last_submit_usec = Time.get_ticks_usec() - started
		submit_time_usec += last_submit_usec
		return false
	var viewport_size := Vector2i(maxi(8, int(ceil(preview_size.x))), maxi(8, int(ceil(preview_size.y))))
	if render_viewport.size != viewport_size:
		render_viewport.size = viewport_size
	render_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	render_canvas.configure(display_name, line_a, line_b, selected, preview_size)
	active_request = {
		"key": cache_key,
		"submit_frame": Engine.get_process_frames(),
	}
	submit_count += 1
	last_submit_usec = Time.get_ticks_usec() - started
	submit_time_usec += last_submit_usec
	return true

static func _capture_active_request() -> int:
	var started := Time.get_ticks_usec()
	if active_request.is_empty() or render_viewport == null:
		last_capture_usec = Time.get_ticks_usec() - started
		return 0
	if Engine.get_process_frames() <= int(active_request.get("submit_frame", -1)):
		last_capture_usec = Time.get_ticks_usec() - started
		return 0
	var cache_key := String(active_request.get("key", ""))
	active_request = {}
	if cache_key == "" or textures.has(cache_key):
		last_capture_usec = Time.get_ticks_usec() - started
		return 0
	var viewport_texture := render_viewport.get_texture()
	if viewport_texture == null:
		last_capture_usec = Time.get_ticks_usec() - started
		return 0
	var image := viewport_texture.get_image()
	if image == null or image.is_empty():
		last_capture_usec = Time.get_ticks_usec() - started
		return 0
	textures[cache_key] = ImageTexture.create_from_image(image)
	capture_count += 1
	last_capture_usec = Time.get_ticks_usec() - started
	capture_time_usec += last_capture_usec
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
	render_canvas = CatalogCardBodyTextureRenderCanvas.new()
	render_viewport.add_child(render_canvas)
	tree.root.add_child(render_viewport)

static func _touch_lru(cache_key: String) -> void:
	lru_order.erase(cache_key)
	lru_order.append(cache_key)

static func _prune_lru() -> void:
	while lru_order.size() > max_entries:
		var old_key := String(lru_order.pop_front())
		textures.erase(old_key)

static func prewarm(owner: Node, slot_key: String, part: Dictionary, display_name: String, line_a: String, line_b: String, selected: bool, preview_size: Vector2) -> bool:
	if DisplayServer.get_name().to_lower() == "headless":
		return false
	var before_pending := pending_order.size()
	var texture := request_preview(owner, slot_key, part, display_name, line_a, line_b, selected, preview_size)
	if texture != null:
		return false
	if pending_order.size() > before_pending:
		prewarm_request_count += 1
		return true
	return false
