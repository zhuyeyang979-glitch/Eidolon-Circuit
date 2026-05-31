extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var script := "$desktop=[Environment]::GetFolderPath('Desktop'); $names=@('Eidolon Circuit.lnk','Strike Lab Game.lnk','Godot 4.6.2.lnk'); $w=New-Object -ComObject WScript.Shell; foreach($n in $names){ $p=Join-Path $desktop $n; if(!(Test-Path -LiteralPath $p)){ Write-Output ('MISSING|{0}' -f $n); continue }; $s=$w.CreateShortcut($p); Write-Output ('{0}|{1}|{2}|{3}' -f $n,$s.TargetPath,$s.Arguments,$s.WorkingDirectory) }"
	var output: Array = []
	var exit_code := OS.execute("powershell", PackedStringArray(["-NoProfile", "-Command", script]), output, true)
	if exit_code != 0:
		_fail("PowerShell shortcut inspection failed: %d %s" % [exit_code, "\n".join(output)])
		return
	var expected_target := "E:\\New project\\tools\\godot-4.6.2\\Godot_v4.6.2-stable_win64.exe"
	var expected_args := "--path \"E:\\New project\""
	var expected_workdir := "E:\\New project"
	var seen := 0
	for raw_line in output:
		for line in String(raw_line).split("\n", false):
			line = line.strip_edges()
			if line == "":
				continue
			var pieces := line.split("|")
			if pieces.size() < 4:
				_fail("Malformed shortcut output: %s" % line)
				return
			if String(pieces[0]).begins_with("MISSING"):
				_fail("Missing shortcut: %s" % line)
				return
			seen += 1
			if String(pieces[1]) != expected_target or String(pieces[2]) != expected_args or String(pieces[3]) != expected_workdir:
				_fail("Shortcut is not on latest E: project: %s" % line)
				return
	if seen != 3:
		_fail("Expected 3 project shortcuts, saw %d." % seen)
		return
	print("DESKTOP_SHORTCUT_LATEST_PROBE ok shortcuts=%d" % seen)
	quit(0)
