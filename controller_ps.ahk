; Permissive personal PS toggle: last other application <-> last FFXI client.
; A global physical edge latch prevents a held PS from bouncing between windows.
PersonalPSState() => {down:true, other:0, otherPID:0, returnClient:0, returnPID:0}
PersonalPSDecision(s, pressed, active, eligible, chord, mode, now) {
    fresh := pressed && !s.down
    s.down := pressed
    if (mode = "off" || !fresh || chord)
        return false
    if (active && s.other)
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
            && windowClass != "AutoHotkey" && windowClass != "tooltips_class32"
    } catch Error {
        return false
    }
}
PersonalPSFallback(ffxi) {
    for hwnd in WinGetList(ffxi ? "ahk_class FFXiClass" : "") {
        try {
            pid := WinGetPID("ahk_id " . hwnd)
            if (PersonalPSValid(hwnd,pid,ffxi) && WinGetTitle("ahk_id " . hwnd) != "")
                return {hwnd:hwnd,pid:pid}
        } catch Error {
        }
    }
    return false
}
PersonalPSPoll(states, active, mode, eligible) {
    global PPS, profile
    try {
        if (active)
            PPS.returnClient := active, PPS.returnPID := WinGetPID("ahk_id " . active)
        else {
            other := WinActive("A"), pid := WinGetPID("ahk_id " . other)
            if (PersonalPSValid(other,pid,false) && WinGetTitle("ahk_id " . other) != "")
                PPS.other := other, PPS.otherPID := pid
        }
    } catch Error {
    }
    pressed := IsObject(states) && states.HasOwnProp("ps") && states.ps
    ; Match the old personal wrapper: shoulders/triggers consume PS combos.
    ; Face buttons, stick motion, menus/chat/events and join timing do not block PS.
    chord := false
    if (IsObject(states)) {
        for i in [11,12,13,14]
            chord := chord || states[i]
    }
    fresh := pressed && !PPS.down
    if (fresh && !chord && mode != "off" && profile = "ps5-directinput") {
        valid := active ? PersonalPSValid(PPS.other,PPS.otherPID,false) : PersonalPSValid(PPS.returnClient,PPS.returnPID,true)
        if (!valid) {
            fallback := PersonalPSFallback(!active)
            if (IsObject(fallback)) {
                if (active)
                    PPS.other := fallback.hwnd, PPS.otherPID := fallback.pid
                else
                    PPS.returnClient := fallback.hwnd, PPS.returnPID := fallback.pid
            }
        }
    }
    decision := PersonalPSDecision(PPS,pressed,active,eligible,chord,
        profile = "ps5-directinput" ? mode : "off",A_TickCount)
    if (!IsObject(decision))
        return
    returning := decision.kind = "return"
    if (!PersonalPSValid(decision.target,decision.pid,returning))
        return BridgeDecision("ps","No suitable window available")
    if (mode = "test")
        return BridgeDecision("ps","Would switch " . decision.kind)
    if (active && WinActive("ahk_class FFXiClass") != active)
        return
    try {
        BridgeRelease()
        ReleaseTransport()
        if (WinGetMinMax("ahk_id " . decision.target) = -1)
            WinRestore("ahk_id " . decision.target)
        WinActivate("ahk_id " . decision.target)
        BridgeDecision("ps",returning ? "Returned to FFXI" : "Switched to remembered window")
    } catch Error {
        BridgeDecision("ps","window activation unavailable")
    }
}
