; Contributing author: Awake. Controller extras revision 2026-10-05.1.
; Shared by the root AutoHotkey v1 DirectInput and XInput wrappers.
; Tap a shoulder once; hold for a configurable delay to repeat. L3 acts on release.
#InstallKeybdHook

AExtrasInit() {
    global AExtrasEnabled, AShouldersEnabled, ASingleClientToggle, AExtrasStates
    global ARepeatEnabled, ARepeatDelayMs, ARepeatIntervalMs
    global AShoulderOwner, AShiftOwned, ATabOwned
    IniRead, AExtrasEnabled, %A_ScriptDir%\controller-extras.ini, Controller, L3Enabled, 1
    IniRead, AShouldersEnabled, %A_ScriptDir%\controller-extras.ini, Controller, ShouldersEnabled, 1
    IniRead, ASingleClientToggle, %A_ScriptDir%\controller-extras.ini, Controller, SingleClientToggle, 1
    IniRead, ARepeatEnabled, %A_ScriptDir%\controller-extras.ini, Controller, ShoulderRepeatEnabled, 1
    IniRead, ARepeatDelayMs, %A_ScriptDir%\controller-extras.ini, Controller, ShoulderRepeatDelayMs, 3000
    IniRead, ARepeatIntervalMs, %A_ScriptDir%\controller-extras.ini, Controller, ShoulderRepeatIntervalMs, 500
    ; A malformed setting falls back to the comfortable defaults. Bound the
    ; interval so a typo cannot flood the foreground client with key events.
    if ARepeatDelayMs is not integer
        ARepeatDelayMs := 3000
    if ARepeatIntervalMs is not integer
        ARepeatIntervalMs := 500
    ARepeatDelayMs := Max(0, ARepeatDelayMs)
    ARepeatIntervalMs := Max(100, ARepeatIntervalMs)
    AExtrasStates := {}, AShoulderOwner := "", AShiftOwned := false, ATabOwned := false
    OnExit("AExtrasShutdown")
}

AExtrasBlocked(busy) {
    global AShiftOwned
    ; Our own held Shift must not block the next reverse tap. The keyboard hook
    ; distinguishes a real keyboard Shift press from the Shift we injected.
    return busy or GetKeyState("Ctrl") or GetKeyState("Alt")
        or GetKeyState("LWin") or GetKeyState("RWin")
        or GetKeyState("Shift", "P")
        or (GetKeyState("Shift") and !AShiftOwned)
}

AExtrasPoll(key, l1, r1, l3, busy) {
    global AExtrasEnabled, AShouldersEnabled, ASingleClientToggle, AExtrasStates
    global ARepeatEnabled, ARepeatDelayMs, ARepeatIntervalMs, AShoulderOwner
    hwnd := WinActive("ahk_class FFXiClass")
    foreground := WinExist("A")
    now := DllCall("GetTickCount64", "UInt64")
    if (!AExtrasStates.HasKey(key)) {
        ; Loading while a controller button is held must not generate a tap.
        AExtrasStates[key] := {l1:l1, r1:r1, l3:l3, armed:0, armFocus:0
            , armSingle:false, shoulder:"", shoulderWindow:0, nextRepeat:0}
        return
    }
    old := AExtrasStates[key]
    blocked := AExtrasBlocked(busy)
    if (old.armed and (foreground != old.armFocus or blocked))
        old.armed := 0

    ; Cancel on release, focus loss, a competing shoulder, or a trigger/menu.
    ; A cancelled hold requires a fresh press before it can send another Tab.
    holding := (old.shoulder = "l1" and l1 and !r1)
        or (old.shoulder = "r1" and r1 and !l1)
    if (old.shoulder != "" and (!holding or !AShouldersEnabled or blocked
        or l3 or hwnd != old.shoulderWindow))
        AExtrasStopShoulder(key, old)

    if (AShouldersEnabled and hwnd and !blocked and !l3) {
        direction := ""
        if (l1 and !old.l1 and !r1)
            direction := "l1"
        else if (r1 and !old.r1 and !l1)
            direction := "r1"
        ; Only one connected controller owns the synthetic modifier at a time.
        if (direction != "" and AShoulderOwner = "") {
            AShoulderOwner := key
            old.shoulder := direction, old.shoulderWindow := hwnd
            old.nextRepeat := now + Max(ARepeatDelayMs, ARepeatIntervalMs)
            if (direction = "l1")
                AExtrasHoldShift()
            if (!ATargetTap(hwnd))
                AExtrasStopShoulder(key, old)
        } else if (old.shoulder != "" and ARepeatEnabled and now >= old.nextRepeat) {
            ; Schedule from this tick rather than catching up with a burst
            ; after a slow frame, paused script, or delayed polling thread.
            old.nextRepeat := now + ARepeatIntervalMs
            if (!ATargetTap(hwnd))
                AExtrasStopShoulder(key, old)
        }
    }

    if (l3 and !old.l3 and AExtrasEnabled and !blocked) {
        WinGet, windows, List, ahk_class FFXiClass
        if (windows = 1 and ASingleClientToggle) {
            ; With one client, L3 may intentionally bring it back from another
            ; program. Remember that foreground so a mid-hold focus change
            ; cancels the action instead of stealing focus on release.
            old.armed := windows1, old.armFocus := foreground, old.armSingle := true
        } else if (windows > 1 and hwnd) {
            old.armed := hwnd, old.armFocus := foreground, old.armSingle := false
        }
    }
    if (!l3 and old.l3) {
        target := old.armed, single := old.armSingle
        old.armed := 0
        if (target and foreground = old.armFocus and !blocked) {
            ; Release any owned modifier before minimizing or switching clients.
            AExtrasStopAllShoulders()
            ASwitchWindow(target, single)
        }
    }
    old.l1 := l1, old.r1 := r1, old.l3 := l3
}

AExtrasHoldShift() {
    global AShiftOwned
    AShiftOwned := true
    SendEvent {Blind}{LShift down}
}

AExtrasReleaseShift() {
    global AShiftOwned
    if (!AShiftOwned)
        return
    ; Leave a genuinely held keyboard Shift alone; its physical release will
    ; release it. Otherwise send the matching key-up for our synthetic hold.
    if (!GetKeyState("LShift", "P"))
        SendEvent {Blind}{LShift up}
    AShiftOwned := false
}

AExtrasStopShoulder(key, state) {
    global AShoulderOwner
    if (AShoulderOwner = key) {
        AExtrasReleaseShift()
        AShoulderOwner := ""
    }
    state.shoulder := "", state.shoulderWindow := 0, state.nextRepeat := 0
}

AExtrasStopAllShoulders() {
    global AExtrasStates
    ; A second controller can request a switch while the first owns Shift.
    ; Clear every hold before changing focus, without releasing physical keys.
    for key, state in AExtrasStates
        AExtrasStopShoulder(key, state)
}

AExtrasDisconnect(key) {
    global AExtrasStates
    if (!AExtrasStates.HasKey(key))
        return
    AExtrasStopShoulder(key, AExtrasStates[key])
    ; Reseed on reconnect, so plugging in while held is not a fresh press.
    AExtrasStates.Delete(key)
}

ATargetTap(hwnd) {
    global ATabOwned
    if (WinActive("ahk_class FFXiClass") != hwnd)
        return false
    ; Keep the proven 40 ms Tab pulse. Blind mode preserves our held Shift,
    ; and Tab is released even if another window gains focus during the pulse.
    ATabOwned := true
    SendEvent {Blind}{Tab down}
    Sleep, 40
    SendEvent {Blind}{Tab up}
    ATabOwned := false
    return WinActive("ahk_class FFXiClass") = hwnd
}

ASwitchWindow(current, single := false) {
    WinGet, windows, List, ahk_class FFXiClass
    if (single) {
        ; Recheck the count: opening/closing clients during the held L3 press
        ; must not turn an intended solo toggle into a different action.
        if (windows != 1 or windows1 != current)
            return
        if (WinActive("ahk_id " . current))
            WinMinimize, ahk_id %current%
        else
            WinActivate, ahk_id %current%
        ; WinActivate restores a minimized client without altering a visible
        ; maximized client's size. The next released press minimizes it again.
        return
    }
    ; Preserve the numeric HWND order used by the working multi-client switch.
    order := ""
    Loop, %windows% {
        id := windows%A_Index%
        order .= (id + 0) . Chr(10)
    }
    Sort, order, N
    first := 0, next := 0, found := false
    for _, entry in StrSplit(order, Chr(10), Chr(13)) {
        if (entry = "")
            continue
        id := entry + 0
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

AExtrasShutdown(reason, code) {
    global AExtrasStates, ATabOwned
    if (ATabOwned) {
        SendEvent {Blind}{Tab up}
        ATabOwned := false
    }
    AExtrasStopAllShoulders()
    return 0
}
