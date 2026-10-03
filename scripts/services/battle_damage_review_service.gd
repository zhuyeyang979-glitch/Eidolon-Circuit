extends RefCounted
class_name BattleDamageReviewService

const CATEGORIES := ["active", "passive", "field", "environment", "status", "other"]

var totals := {1: {}, 2: {}}
var latest := {1: {}, 2: {}}


func reset() -> void:
    totals = {1: {}, 2: {}}
    latest = {1: {}, 2: {}}


func record(victim_owner: int, health_lost: int, attacker_owner: int, category: String, source_label: String, actor_name: String, stamp: float) -> void:
    if victim_owner not in [1, 2] or health_lost <= 0:
        return
    var kind := category if category in CATEGORIES else "other"
    var player_totals: Dictionary = totals[victim_owner]
    player_totals[kind] = int(player_totals.get(kind, 0)) + health_lost
    latest[victim_owner] = {
        "attacker": attacker_owner,
        "category": kind,
        "source": source_label.strip_edges(),
        "actor": actor_name.strip_edges(),
        "damage": health_lost,
        "time": stamp,
    }


func summary(zh: bool) -> String:
    var lines := PackedStringArray()
    for player_id in [1, 2]:
        var player_totals: Dictionary = totals.get(player_id, {})
        var total := 0
        var parts := PackedStringArray()
        for kind in CATEGORIES:
            var amount := int(player_totals.get(kind, 0))
            if amount <= 0:
                continue
            total += amount
            parts.append("%s %d" % [_category_name(kind, zh), amount])
        if total <= 0:
            continue
        if lines.is_empty():
            lines.append("英雄生命损失" if zh else "Hero HP lost")
        var event: Dictionary = latest.get(player_id, {})
        var source_text := _source_text(event, zh)
        var attacker := int(event.get("attacker", 0))
        var from_text := "P%d" % attacker if attacker in [1, 2] else ("环境" if zh else "world")
        if zh:
            lines.append("P%d -%d HP（%s）；最近 %s %s -%d，%.1fs" % [player_id, total, "/".join(parts), from_text, source_text, int(event.get("damage", 0)), float(event.get("time", 0.0))])
        else:
            lines.append("P%d -%d HP (%s); last %s %s -%d at %.1fs" % [player_id, total, "/".join(parts), from_text, source_text, int(event.get("damage", 0)), float(event.get("time", 0.0))])
    return "\n".join(lines)


func _source_text(event: Dictionary, zh: bool) -> String:
    var attacker := int(event.get("attacker", 0))
    var actor := String(event.get("actor", ""))
    if attacker in [1, 2] and actor.begins_with("P%d " % attacker):
        actor = actor.substr(3)
    actor = actor.replace("DEFENSE_TOWER", "防御塔" if zh else "Defense Tower")
    var source := String(event.get("source", ""))
    if source == "Field effect":
        source = "场域" if zh else "field"
    var result := (source + " · " + actor).strip_edges().trim_prefix("· ").trim_suffix(" ·")
    if result.length() > 30:
        result = result.substr(0, 29) + "…"
    return result


func _category_name(kind: String, zh: bool) -> String:
    if not zh:
        return kind
    match kind:
        "active": return "主动"
        "passive": return "碰撞"
        "field": return "场域"
        "environment": return "环境"
        "status": return "状态"
    return "其他"
