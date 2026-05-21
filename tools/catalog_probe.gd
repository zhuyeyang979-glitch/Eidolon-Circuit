extends SceneTree

const MainScene := preload("res://scripts/main.gd")

func _init() -> void:
	print("JOINTS")
	for j in range(MainScene.COMMON_CATALOG["joint"].size()):
		var joint: Dictionary = MainScene.COMMON_CATALOG["joint"][j]
		if j >= 12:
			print("%d %s cost=%d size=%s len=%.2f" % [j, String(joint.get("name", "")), int(joint.get("cost", 0)), String(joint.get("size_class", "")), float(joint.get("length", 0.0))])
	print("MUSCLES")
	for i in range(MainScene.COMMON_CATALOG["muscle"].size()):
		var part: Dictionary = MainScene.COMMON_CATALOG["muscle"][i]
		var name := String(part.get("name", ""))
		if name.contains("RIFLE") or name.contains("GUN") or name.contains("CORE"):
			print("%d %s cost=%d len=%.2f projectile=%s torso=%s" % [i, name, int(part.get("cost", 0)), float(part.get("length", 0.0)), str(bool(part.get("projectile", false))), str(bool(part.get("is_torso", false)))])
	quit()
