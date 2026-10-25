; Beta 1 opt-in AHK observation feed; no input or routing changes.
; AHK writes a bounded temporary file. Lua alone writes the final per-character log.
DiagInit() {
    global DX
    DX := {active:false, lines:[], bytes:0, dropped:0, id:"", name:""
        , nextRequest:0, nextSave:0, deadline:0, lastSignature:"", lastPoll:0}
}
DiagClock() {
    VarSetCapacity(ft, 8, 0)
    DllCall("GetSystemTimeAsFileTime", "Ptr", &ft)
    return Floor((NumGet(ft, 0, "Int64") - 116444736000000000) / 10000)
}
DiagRecord(message) {
    global DX
    if (!IsObject(DX) or !DX.active)
        return
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
    FileCreateDir, %folder%
    path := folder . "\" . DX.id . ".ahk"
    temp := path . ".tmp"
    content := "# diagnostic-feed " . DX.id . Chr(10)
        . "state=" . (DX.active ? "active" : "stopped") . Chr(10)
        . "dropped=" . DX.dropped . Chr(10)
    for _, line in DX.lines
        content .= line
    FileDelete, %temp%
    FileAppend, %content%, %temp%
    if (!ErrorLevel)
        FileMove, %temp%, %path%, 1
}
DiagClose(reason) {
    global DX
    if (!DX.active)
        return
    DiagRecord("session stop reason=" . reason)
    DX.active := false
    DiagWrite()
}
DiagTick() {
    global DX, profile, device
    now := A_TickCount
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
    FileRead, command, %requestPath%
    FileDelete, %requestPath%
    command := Trim(command, " " . Chr(9) . Chr(13) . Chr(10))
    if (RegExMatch(command, "^on ([A-Za-z0-9_-]+) ([A-Za-z]+)$", m)) {
        if (DX.active)
            DiagClose("replaced-by-request")
        DX.id := m1, DX.name := m2, DX.lines := [], DX.bytes := 0
        DX.dropped := 0, DX.active := true, DX.deadline := now + 30000
        DX.lastSignature := "", DX.nextSave := now + 1000
        DiagRecord("session start id=" . DX.id . " character=" . DX.name . " profile=" . profile . " device=" . device . " ahk=" . A_AhkVersion)
        DiagWrite()
    } else if (RegExMatch(command, "^off ([A-Za-z0-9_-]+) ([A-Za-z]+)$", m)
        and DX.active and m1 = DX.id) {
        DiagClose("Lua stop requested")
    }
}
DiagSample(states, hwnd, route) {
    global DX, CM, appsOwned
    if (!DX.active)
        return
    mask := ""
    if (IsObject(states)) {
        Loop, 12
            mask .= states[A_Index] ? "1" : "0"
    } else mask := "disconnected"
    signature := "hwnd=" . hwnd . " route=" . route . " mask=" . mask
        . " messages=" . CM.requested . " phase=" . CM.phase
        . " msg_seq=" . CM.seq . " ack=" . CM.ack . " pending=" . CM.pending.Length()
        . " apps_owned=" . appsOwned
    if (signature != DX.lastSignature) {
        DX.lastSignature := signature
        DiagRecord("poll " . signature)
    }
}
