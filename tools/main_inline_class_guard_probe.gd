extends SceneTree

const MAIN_PATH := "res://scripts/main.gd"

const ALLOWED_INLINE_CLASSES := {
	"MobiusStripSurfaceView": "mobius surface view extraction is deferred until the Mobius visual boundary batch",
	"MobiusStardustBandView": "mobius surface view extraction is deferred until the Mobius visual boundary batch",
	"ScoutUnitDetailView": "unit detail preview is coupled to saved-unit/editor hover flows",
	"PartPreviewTextureRenderCanvas": "catalog preview texture cache cluster is deferred",
	"PartPreviewTextureCache": "catalog preview texture cache cluster is deferred",
	"PartPreviewIconView": "catalog preview texture cache cluster is deferred",
	"CatalogCardTextLayer": "catalog card cluster is deferred",
	"CatalogCardBodyTextureRenderCanvas": "catalog card cluster is deferred",
	"CatalogCardBodyTextureCache": "catalog card cluster is deferred",
	"CatalogCardRetainedItem": "catalog card cluster is deferred",
	"PartCatalogCardButton": "catalog card cluster is deferred",
	"EditorStatsRailView": "unit editor rail extraction is deferred",
	"EditorPartHoverPopupView": "pinned part detail panel remains high-coupling",
	"TorsoDetailPanelView": "torso detail panel remains high-coupling",
	"EngineMomentumAllocationPanelView": "power allocation detail panel remains high-coupling",
	"UnitEditorPowerDockView": "power dock remains high-coupling",
	"AssemblyBoardRenderLayer": "board render support cluster is deferred",
	"AssemblyBoardRenderComponentItem": "board render support cluster is deferred",
	"AssemblyBoardRenderItem": "board render support cluster is deferred",
	"AssemblyBoardView": "assembly board extraction is deferred to EC-SLIM-003",
	"BattleContactVfxPool": "contact VFX pool owns runtime particle pooling",
	"SalvoLandingPreviewEffect": "contextual battle effect extraction is deferred",
	"LaserAimTelegraphEffect": "contextual battle effect extraction is deferred",
	"TrueBulletTargetLockEffect": "contextual battle effect extraction is deferred",
	"BlindZoneEffect": "contextual battle effect extraction is deferred",
	"FieldAuraEffect": "contextual battle effect extraction is deferred",
	"CoinPickupEffect": "contextual battle effect extraction is deferred",
	"IdentityTransferEffect": "contextual battle effect extraction is deferred",
}

const EXTRACTED_INLINE_CLASSES := [
	"BackdropView",
	"SortieThumbView",
	"CockpitHudView",
	"BattleInstrumentGaugeView",
	"BattleMinimapView",
	"BattleActionDiagnosticsView",
	"BattlePartPreviewView",
	"TrainingEntryIntroView",
	"PartDragGhostView",
	"ComponentArtView",
	"HitEffect",
	"ComboRippleEffect",
	"ProjectileTraceEffect",
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _inline_class_names(source: String) -> Array[String]:
	var result: Array[String] = []
	for raw_line in source.split("\n"):
		var line := String(raw_line).strip_edges()
		if not line.begins_with("class ") or not line.ends_with(":"):
			continue
		var name := line.substr(6, line.length() - 7).strip_edges()
		if name.find(" ") >= 0 or name.find("\t") >= 0:
			continue
		result.append(name)
	return result


func _init() -> void:
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	if source.is_empty():
		_fail("main.gd source is empty or missing.")
	var inline_classes := _inline_class_names(source)
	if inline_classes.is_empty():
		_fail("Inline class guard expected existing deferred inline classes in main.gd.")
	for inline_class_name in inline_classes:
		if not ALLOWED_INLINE_CLASSES.has(inline_class_name):
			_fail("New inline class in main.gd must be extracted or explicitly justified in the guard allowlist: %s" % inline_class_name)
	for extracted_class_name in EXTRACTED_INLINE_CLASSES:
		if source.find("\nclass %s:" % extracted_class_name) >= 0:
			_fail("Extracted class should not be reintroduced inline in main.gd: %s" % extracted_class_name)
	print("MAIN_INLINE_CLASS_GUARD_PROBE ok allowed=%d active=%d extracted=%d" % [ALLOWED_INLINE_CLASSES.size(), inline_classes.size(), EXTRACTED_INLINE_CLASSES.size()])
	quit(0)
