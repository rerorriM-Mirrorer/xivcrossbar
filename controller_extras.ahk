; Contributing author: A. One rising-edge shoulder tap; switch on L3 release.
; Shared by the root DirectInput and XInput wrappers. R3 remains native Run.
AExtrasInit() {
    global AExtrasEnabled, AShouldersEnabled, AExtrasStates
    IniRead, AExtrasEnabled, %A_ScriptDir%\controller-extras.ini, Controller, L3Enabled, 1
    IniRead, AShouldersEnabled, %A_ScriptDir%\controller-extras.ini, Controller, ShouldersEnabled, 1
    AExtrasStates := {}
}

AExtrasPoll(key, l1, r1, l3, busy) {
    global AExtrasEnabled, AShouldersEnabled, AExtrasStates
    hwnd := WinActive("ahk_class FFXiClass")
    if (!AExtrasStates.HasKey(key)) {
        ; Seed physical state: loading while held must not generate a tap.
        AExtrasStates[key] := {l1:l1, r1:r1, l3:l3, armed:0}
        return
    }
    old := AExtrasStates[key]
    blocked := busy or GetKeyState("Ctrl") or GetKeyState("Shift") or GetKeyState("Alt")
    if (old.armed and (hwnd != old.armed or blocked))
        old.armed := 0
    if (AShouldersEnabled and hwnd and !blocked) {
        if (r1 and !old.r1)
            ATargetTap(false, hwnd)
        if (l1 and !old.l1)
            ATargetTap(true, hwnd)
    }
    if (l3 and !old.l3)
        old.armed := (AExtrasEnabled and hwnd and !blocked) ? hwnd : 0
    if (!l3 and old.l3) {
        if (old.armed and hwnd = old.armed and !blocked)
            ASwitchWindow(hwnd)
        old.armed := 0
    }
    old.l1 := l1, old.r1 := r1, old.l3 := l3
}

ATargetTap(reverse, hwnd) {
    ; SendEvent plus explicit hold gives FFXI time to sample Tab. Release even
    ; if focus changes during the tap; no repeat is generated while held.
    if (reverse)
        SendEvent {LShift down}
    SendEvent {Tab down}
    Sleep, 40
    SendEvent {Tab up}
    if (reverse)
        SendEvent {LShift up}
}

ASwitchWindow(current) {
    ; Stable numeric HWND order cycles all clients, unlike changing Z-order.
    WinGet, windows, List, ahk_class FFXiClass
    order := ""
    Loop, %windows% {
        id := windows%A_Index%
        order .= (id + 0) . "`n"
    }
    Sort, order, N
    first := 0, next := 0, found := false
    Loop, Parse, order, `n, `r
    {
        if (A_LoopField = "")
            continue
        id := A_LoopField + 0
        if (!first)
            first := id
        if (found) {
            next := id
            break
        }
        if (id = current)
            found := true
    }
    if (!next and found)
        next := first
    if (next and next != current)
        WinActivate, ahk_id %next%
}
