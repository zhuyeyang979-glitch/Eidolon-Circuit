extends RefCounted
class_name BattleReplayFileService

const DIRECTORY := "user://battle_replays"
const SCHEMA_VERSION := 1
const RULESET_ID := "star_soul_local_replay_1"
const MAX_FILE_BYTES := 128 * 1024 * 1024
const MAX_INPUT_STEPS := 108000
const ContactTape = preload("res://scripts/services/battle_contact_tape_service.gd")
const InputService = preload("res://scripts/services/battle_input_service.gd")


static func validate_payload(payload: Dictionary) -> String:
    if int(payload.get("schema_version", -1)) != SCHEMA_VERSION or String(payload.get("ruleset_id", "")) != RULESET_ID:
        return "Replay version is incompatible with this game build."
    var start: Dictionary = payload.get("start", {}) if payload.get("start") is Dictionary else {}
    var setup: Dictionary = payload.get("setup", {}) if payload.get("setup") is Dictionary else {}
    var tape: Dictionary = payload.get("contact_tape", {}) if payload.get("contact_tape") is Dictionary else {}
    var final_state: Dictionary = payload.get("final", {}) if payload.get("final") is Dictionary else {}
    var frames: Array = payload.get("input_frames", []) if payload.get("input_frames") is Array else []
    var input_service = InputService.new()
    var canonical_start: Dictionary = input_service.deserialize_battle_start_payload(input_service.serialize_battle_start_payload(start))
    var seed_value := int(canonical_start.get("replay_seed", 0))
    if canonical_start.is_empty() or seed_value <= 0 or String(canonical_start.get("mode", "")) != "pvp":
        return "Replay start settings are missing or unsupported."
    for key in ["blueprints", "active_roster_indices", "initial_role", "initial_sortie_slot", "sortie_loadouts", "summon_pair_bindings", "team_color_indices", "team_custom_colors", "star_soul_battle_draft_payload"]:
        if not (setup.get(key) is Dictionary):
            return "Replay opening team or draft is incomplete."
    if not bool(Dictionary(setup.get("star_soul_battle_draft_payload", {})).get("valid", false)):
        return "Replay Star Soul draft is incomplete."
    if frames.is_empty() or frames.size() > MAX_INPUT_STEPS or int(final_state.get("simulation_steps", -1)) != frames.size():
        return "Replay input length does not match its result."
    var action_names: Array = canonical_start.get("action_names", [])
    for raw_frame in frames:
        if not (raw_frame is String):
            return "Replay contains an invalid input frame."
        var parsed = JSON.parse_string(String(raw_frame))
        if not (parsed is Dictionary) or int(Dictionary(parsed).get("schema_version", -1)) != InputService.INPUT_FRAME_SCHEMA_VERSION:
            return "Replay contains an incompatible input frame."
        if input_service.serialize_input_frame(input_service.deserialize_input_frame(String(raw_frame)), action_names) != String(raw_frame):
            return "Replay input frame failed validation."
    if int(tape.get("schema_version", -1)) != ContactTape.SCHEMA_VERSION or int(tape.get("replay_seed", 0)) != seed_value or not (tape.get("frames") is Array):
        return "Replay contact data is missing or incompatible."
    var last_step := 0
    for raw_step in Array(tape.get("frames", [])):
        if not (raw_step is Dictionary):
            return "Replay contact step is invalid."
        var step: Dictionary = raw_step
        var index := int(step.get("step", -1))
        if index <= last_step or index > frames.size():
            return "Replay contact steps are out of order."
        var decoded: Dictionary = ContactTape.decode_step(step, index, int(step.get("collider_count", -1)))
        if decoded.has("error"):
            return "Replay contact data failed validation: %s" % String(decoded["error"])
        last_step = index
    if int(final_state.get("winner", 0)) not in [1, 2] or String(final_state.get("reason", "")) == "" or String(final_state.get("checkpoint_digest", "")) == "":
        return "Replay result is incomplete."
    return ""


static func write_new(payload: Dictionary) -> Dictionary:
    var error_text := validate_payload(payload)
    if error_text != "":
        return {"ok": false, "error": error_text}
    if DirAccess.make_dir_recursive_absolute(DIRECTORY) != OK:
        return {"ok": false, "error": "Cannot create the replay folder."}
    var stem := "replay_%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
    var path := "%s/%s.json" % [DIRECTORY, stem]
    if FileAccess.file_exists(path):
        return {"ok": false, "error": "Replay filename already exists."}
    var temporary_path := "%s/%s.tmp" % [DIRECTORY, stem]
    var body_json := JSON.stringify(payload)
    var encoded := JSON.stringify({"schema_version": SCHEMA_VERSION, "sha256": body_json.sha256_text(), "body_json": body_json})
    if encoded.to_utf8_buffer().size() > MAX_FILE_BYTES:
        return {"ok": false, "error": "Replay is too large to save."}
    var file := FileAccess.open(temporary_path, FileAccess.WRITE)
    if file == null:
        return {"ok": false, "error": "Cannot write the replay folder."}
    file.store_string(encoded)
    file.flush()
    file.close()
    var readback := _parse_text(FileAccess.get_file_as_string(temporary_path))
    if not bool(readback.get("ok", false)):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
        return {"ok": false, "error": "Replay write verification failed: %s" % String(readback.get("error", ""))}
    var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path), ProjectSettings.globalize_path(path))
    if rename_error != OK:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_path))
        return {"ok": false, "error": "Cannot finish replay save."}
    return {"ok": true, "path": path}


static func latest_path() -> String:
    var dir := DirAccess.open(DIRECTORY)
    if dir == null:
        return ""
    var paths: Array[String] = []
    dir.list_dir_begin()
    while true:
        var name := dir.get_next()
        if name == "":
            break
        if not dir.current_is_dir() and name.begins_with("replay_") and name.ends_with(".json"):
            paths.append("%s/%s" % [DIRECTORY, name])
    dir.list_dir_end()
    paths.sort()
    return paths.back() if not paths.is_empty() else ""


static func read_path(path: String) -> Dictionary:
    if not path.begins_with(DIRECTORY + "/") or not path.ends_with(".json") or not FileAccess.file_exists(path):
        return {"ok": false, "error": "Replay file was not found."}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {"ok": false, "error": "Replay file cannot be opened."}
    var length := file.get_length()
    if length <= 0 or length > MAX_FILE_BYTES:
        file.close()
        return {"ok": false, "error": "Replay file size is invalid."}
    var encoded := file.get_as_text()
    file.close()
    return _parse_text(encoded)


static func _parse_text(encoded: String) -> Dictionary:
    var envelope = JSON.parse_string(encoded)
    if not (envelope is Dictionary) or int(Dictionary(envelope).get("schema_version", -1)) != SCHEMA_VERSION:
        return {"ok": false, "error": "Replay file format is incompatible."}
    var body_json := String(Dictionary(envelope).get("body_json", ""))
    if body_json == "" or body_json.sha256_text() != String(Dictionary(envelope).get("sha256", "")):
        return {"ok": false, "error": "Replay integrity check failed."}
    var payload = JSON.parse_string(body_json)
    if not (payload is Dictionary):
        return {"ok": false, "error": "Replay body cannot be read."}
    var error_text := validate_payload(payload)
    if error_text != "":
        return {"ok": false, "error": error_text}
    return {"ok": true, "payload": payload}
