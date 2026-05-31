extends RefCounted
class_name UILifecycleService


static func trim_dictionary_cache(cache: Dictionary, max_entries: int) -> int:
	var removed := 0
	while cache.size() > max_entries:
		var keys := cache.keys()
		if keys.is_empty():
			break
		cache.erase(keys[0])
		removed += 1
	return removed


static func node_descendant_count(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	for child in node.get_children():
		count += 1
		if child is Node:
			count += node_descendant_count(child)
	return count


static func visible_control_count(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is Control:
		var control: Control = node
		if control.visible:
			count += 1
	for child in node.get_children():
		if child is Node:
			count += visible_control_count(child)
	return count


static func layer_snapshot(layers: Dictionary) -> Dictionary:
	var layer_counts := {}
	var layer_visible_controls := {}
	for key in layers.keys():
		var layer = layers[key]
		layer_counts[key] = node_descendant_count(layer)
		layer_visible_controls[key] = visible_control_count(layer)
	return {
		"nodes": layer_counts,
		"visible_controls": layer_visible_controls,
	}
