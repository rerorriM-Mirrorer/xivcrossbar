; Beta 1 opt-in AHK observation feed; no input or routing changes.
; AHK writes a bounded temporary file. Lua alone writes the final per-character log.
DiagInit() {
    global DX
    DX := {active:false, lines:[], bytes:0, dropped:0, id:"", pid:0, matched:false, stageAt:0
        , nextRequest:0, nextSave:0, deadline:0, lastSignature:"", lastPoll:0}
}
DiagClock() {
    ft := Buffer(8, 0)
    DllCall("GetSystemTimeAsFileTime", "Ptr", ft)
    return Floor((NumGet(ft, 0, "Int64") - 116444736000000000) / 10000)
}
DiagRecord(message) {
    global DX
    if (!IsObject(DX) or !DX.active or !DX.matched)
        return
    message := RegExReplace(message, "(?: HWND |owner=)\d+", " [window]")
    line := DiagClock() . " " . message . Chr(10)
    if (DX.bytes + StrLen(line) > 524288) {
        DX.dropped += 1
        return
    }
    DX.bytes += StrLen(line)
    DX.lines.Push(line)
}
DiagWrite() {
    global DX
    if (!DX.id)
        return
    folder := A_ScriptDir . "\data\diagnostics-staging"
    try DirCreate(folder)
    catch OSError
        return
    path := folder . "\" . DX.id . ".ahk"
    temp := path . ".tmp"
    content := "# diagnostic-feed " . DX.id . Chr(10)
        . "state=" . (DX.active ? "active" : "stopped") . Chr(10)
        . "dropped=" . DX.dropped . Chr(10)
    for _, line in DX.lines
        content .= line
    WriteControllerFile(temp, path, content)
}
DiagClose(reason) {
    global DX
    if (!DX.active)
        return
    DiagRecord("session stop reason=" . reason)
    DX.active := false
    DiagWrite()
}
DiagMatch(hwnd, pid) {
    if (!pid)
        return true
    if (!hwnd)
        return false
    try return WinGetPID("ahk_id " . hwnd) = pid
    catch
        return false
}
DiagStage(name) {
    global DX
    if (!DX.active or !DX.matched)
        return
    DllCall("QueryPerformanceCounter", "Int64*", &now := 0)
    if (DX.stageAt) {
        elapsed := 1000.0 * (now - DX.stageAt) / DX.frequency
        if (elapsed >= 8)
            DiagRecord("stage=" . name . " elapsed_ms=" . Round(elapsed, 2))
    }
    DX.stageAt := now
}
DiagTick(hwnd) {
    global DX, profile, device
    now := A_TickCount
    if (DX.active)
        DX.matched := DiagMatch(hwnd, DX.pid)
    DX.stageAt := 0
    if (DX.active and DX.lastPoll and now - DX.lastPoll > 30)
        DiagRecord("poll gap_ms=" . (now - DX.lastPoll))
    DX.lastPoll := now
    if (DX.active and now >= DX.deadline)
        DiagClose("deadline")
    if (DX.active and now >= DX.nextSave) {
        DX.nextSave := now + 1000
        DiagWrite()
    }
    if (now < DX.nextRequest)
        return
    DX.nextRequest := now + 100
    requestPath := A_ScriptDir . "\data\diagnostics-staging\request.txt"
    if (!FileExist(requestPath))
        return
    try {
        command := FileRead(requestPath)
        FileDelete(requestPath)
    } catch Error {
        return
    }
    command := Trim(command, " " . Chr(9) . Chr(13) . Chr(10))
    if (RegExMatch(command, "^on ([A-Za-z0-9_-]+) ([A-Za-z]+)(?: (\d+))?$", &m)) {
        if (DX.active) {
            path := A_ScriptDir . "\data\diagnostics-staging\" . m[1] . ".ahk"
            contents := "# diagnostic-feed " . m[1] . "`nstate=stopped`ndropped=0`n"
                . DiagClock() . " capture refused: shared reader already recording`n"
            WriteControllerFile(path . ".tmp", path, contents)
            return
        }
        DX.id := m[1], DX.pid := m[3] != "" ? Integer(m[3]) : 0
        DX.matched := DiagMatch(hwnd, DX.pid)
        DX.lines := [], DX.bytes := 0
        DllCall("QueryPerformanceFrequency", "Int64*", &frequency := 0)
        DX.frequency := frequency
        DX.dropped := 0, DX.active := true, DX.deadline := now + 30000
        DX.lastSignature := "", DX.nextSave := now + 1000
        DiagRecord("session start id=" . DX.id . " profile=" . profile . " device=" . device . " ahk=" . A_AhkVersion)
        DiagWrite()
    } else if (RegExMatch(command, "^off ([A-Za-z0-9_-]+) ([A-Za-z]+)$", &m)
        and DX.active and m[1] = DX.id) {
        DiagClose("Lua stop requested")
    }
}
DiagSample(states, hwnd, route) {
    global DX, CM
    if (!DX.active or !DX.matched)
        return
    mask := ""
    if (IsObject(states)) {
        for _, pressed in states
            mask .= pressed ? "1" : "0"
    } else mask := "disconnected"
    signature := "route=" . route . " mask=" . mask
        . " messages=" . CM.requested . " phase=" . CM.phase
        . " msg_seq=" . CM.seq . " ack=" . CM.ack . " pending=" . CM.pending.Length
    if (signature != DX.lastSignature) {
        DX.lastSignature := signature
        DiagRecord("poll " . signature)
    }
}
