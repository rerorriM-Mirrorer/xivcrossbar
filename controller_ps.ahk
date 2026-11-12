; Bare PS window toggle. One global physical edge latch survives focus changes.
PersonalPSState() => {down:true, other:0, otherPID:0, returnClient:0, returnPID:0, returnUntil:0}
PersonalPSDecision(s, pressed, active, eligible, chord, mode, now) {
    fresh := pressed && !s.down
    s.down := pressed
    if (mode = "off") {
        s.returnClient := 0
        return false
    }
    if (s.returnClient && now > s.returnUntil)
        s.returnClient := 0
    if (!fresh || chord)
        return false
    if (active && eligible && s.other)
        return {kind:"away", target:s.other, pid:s.otherPID}
    if (!active && s.returnClient)
        return {kind:"return", target:s.returnClient, pid:s.returnPID}
    return false
}
PersonalPSValid(hwnd, pid, ffxi) {
    try {
        if (!hwnd || !WinExist("ahk_id " . hwnd) || WinGetPID("ahk_id " . hwnd) != pid)
            return false
        windowClass := WinGetClass("ahk_id " . hwnd)
        return ffxi ? windowClass = "FFXiClass" : windowClass != "FFXiClass"
            && windowClass != "Progman" && windowClass != "WorkerW" && windowClass != "Shell_TrayWnd"
    } catch Error {
        return false
    }
}
PersonalPSPoll(states, active, mode, eligible) {
    global PPS, profile
    if (!active) {
        other := WinActive("A")
        try {
            pid := WinGetPID("ahk_id " . other)
            if (PersonalPSValid(other,pid,false) && WinGetTitle("ahk_id " . other) != "")
                PPS.other := other, PPS.otherPID := pid
        } catch Error {
        }
    }
    pressed := IsObject(states) && states.HasOwnProp("ps") && states.ps
    chord := false
    if (IsObject(states)) {
        Loop states.Length
            if (A_Index != 17)
                chord := chord || states[A_Index]
    }
    fresh := pressed && !PPS.down
    decision := PersonalPSDecision(PPS,pressed,active,eligible,chord,
        profile = "ps5-directinput" ? mode : "off",A_TickCount)
    if (!IsObject(decision)) {
        if (fresh && active && eligible && !chord && mode != "off" && !PPS.other)
            BridgeDecision("ps","No remembered window; visit it with Alt-Tab first")
        return
    }
    returning := decision.kind = "return"
    if (!PersonalPSValid(decision.target,decision.pid,returning)) {
        if (returning)
            PPS.returnClient := 0
        else
            PPS.other := 0
        return BridgeDecision("ps","remembered window unavailable")
    }
    if (mode = "test")
        return BridgeDecision("ps","Would switch " . decision.kind)
    if (active && WinActive("ahk_class FFXiClass") != active)
        return
    try {
        if (!returning) {
            sourcePID := WinGetPID("ahk_id " . active)
            ReleaseTransport()
        }
        WinActivate("ahk_id " . decision.target)
        if (returning)
            PPS.returnClient := 0
        else
            PPS.returnClient := active, PPS.returnPID := sourcePID, PPS.returnUntil := A_TickCount+30000
        BridgeDecision("ps",returning ? "Returned to FFXI" : "Switched to remembered window")
    } catch Error {
        BridgeDecision("ps","window activation unavailable")
    }
}
