; A: isolated, optional PS5 personal controls. No output in ordinary profiles.
; This include owns its keys; base Apps/F1-F12 routing stays in the wrapper.
PersonalInit(selected, prefix) {
    global PC
    PC := {enabled:selected = "ps5-extended", prefix:prefix, owner:0, ready:false
        , keys:{}, releases:{}, blocked:{}, suppressed:{}, previous:[], connected:false, altLatched:false
        , psPhase:"idle", touch:{phase:"idle"}, clicks:{phase:"idle"}
        , shoulders:{l1:{phase:"idle", key:"F10", direction:-1}, r1:{phase:"idle", key:"F8", direction:1}}
        , clients:[], lastClient:0, lastOther:0, switchPending:0}
    if (!PC.enabled)
        return
    file := A_ScriptDir . "\data\personal-controller.ini"
    if !FileExist(file)
        FileAppend, % "[Personal]`nPSHoldAction=focus`nDoubleTapMs=250`n", %file%
    IniRead, hold, %file%, Personal, PSHoldAction, focus
    IniRead, doubleTap, %file%, Personal, DoubleTapMs, 250
    PC.holdAction := hold = "minimize" ? "minimize" : "focus"
    PC.doubleTapMs := doubleTap >= 100 and doubleTap <= 600 ? doubleTap + 0 : 250
}

PersonalPoll(states, active) {
    global PC, appsOwned
    if (!PC.enabled)
        return states
    foreground := WinExist("A")
    if (active)
        PC.lastClient := active
    else if PersonalOtherWindow(foreground)
        PC.lastOther := foreground
    if (!IsObject(states)) {
        PersonalRelease()
        PC.connected := false, PC.psPhase := "idle", PC.previous := []
        return states
    }
    raw := []
    for i, value in states
        raw[i] := value
    for name, button in {l1:5, r1:6, l3:11, r3:12, ps:13, touch:14}
        raw[name] := GetKeyState(PC.prefix . "Joy" . button) ? true : false
    now := DllCall("GetTickCount64", "UInt64")
    if (!PC.connected) {
        PC.connected := true, PC.previous := raw
        PC.ready := false, PC.psPhase := "idle", PC.blocked := {}, PC.suppressed := {}
        return states
    }
    PersonalPS(raw.ps, foreground, active, now)
    if (PC.owner != active) {
        PersonalRelease()
        PC.owner := active, PC.ready := false
        PC.previous := raw
    }
    PersonalReleaseDue(now)
    mode := PersonalContext(active)
    PC.context := mode
    keepAlt := active and mode = "gameplay" and raw.r1
        and !raw[11] and !raw[12] and !raw[9] and !raw[10]
    allowed := active and mode = "gameplay" and !raw[11] and !raw[12]
        and !raw[9] and !raw[10] and !appsOwned
    if (!allowed) {
        PersonalRelease(false, keepAlt)
    }
    neutral := !raw.l1 and !raw.r1 and !raw.l3 and !raw.r3 and !raw.touch and !raw.ps
    Loop, 12
        if (raw[A_Index])
            neutral := false
    if (PC.switchPending) {
        step := PersonalSwitchStep(PC.switchPending, active, allowed, neutral, now)
        if (step = "cancel")
            PersonalRelease()
        else if (step = "switch") {
            pending := PC.switchPending
            PC.switchPending := 0
            if WinExist("ahk_id " . pending.target) {
                ; Escape's due key-up was delivered above to its original owner.
                ReleaseTransport()
                target := pending.target
                WinActivate, ahk_id %target%
            }
            PC.previous := raw
            return states
        } else {
            PC.previous := raw
            return PersonalFilter(states, raw)
        }
    }
    if (!PC.ready) {
        if (allowed and neutral) {
            PC.ready := true
            PC.touch.phase := "idle", PC.clicks.phase := "idle"
            for _, gesture in PC.shoulders
                gesture.phase := "idle", gesture.pending := 0
        }
        PC.previous := raw
        return PersonalFilter(states, raw)
    }

    ; Claim only a fresh button-down. A held button cannot acquire a new
    ; meaning by pressing a shoulder, changing focus, or closing an addon menu.
    arrows := ["Up", "Right", "Down", "Left"]
    taps := []
    fresh := []
    Loop, 4 {
        i := A_Index
        fresh[i] := raw[i] and !PC.previous[i]
    }
    directionChanged := false
    Loop, 4 {
        i := A_Index
        if (allowed and raw.r1 and !raw.l1 and raw[i] and !PC.previous[i])
            PC.blocked[i] := arrows[i], directionChanged := true
    }
    if (directionChanged) {
        ; A held previous direction must not acquire the new chord's modifier.
        Loop, 4 {
            i := A_Index
            if (PC.blocked.HasKey(i) and !fresh[i]) {
                PC.suppressed[i] := true
                PersonalKey(arrows[i], false)
            }
        }
    }
    if (allowed and raw.l1 and !raw.r1 and raw[5] and !PC.previous[5]) {
        PC.blocked[5] := "Space"
        taps.Push({key:"Space", modifier:"LControl"})
    }
    if (allowed and raw.r1 and !raw.l1) {
        for i, key in {5:"Enter", 7:"Escape", 8:"NumpadAdd"} {
            if (raw[i] and !PC.previous[i]) {
                PC.blocked[i] := key
                taps.Push({key:key, modifier:i = 8 ? "LControl" : ""})
            }
        }
    }
    states := PersonalFilter(states, raw)
    transportBusy := false
    Loop, 12
        if (states[A_Index])
            transportBusy := true
    ; A native F8 tap must finish before Apps/F8 can belong to a slot packet.
    if (transportBusy)
        PersonalRelease(false, keepAlt)

    latched := PersonalAltStep(PC, raw.r1, allowed and !raw.l1 and fresh[2], allowed and !raw.l1 and fresh[4])
    pulseBusy := PC.releases.HasKey("Enter") or PC.releases.HasKey("Escape")
        or PC.releases.HasKey("Space") or PC.releases.HasKey("NumpadAdd")
    alt := PersonalAltOutput(latched, allowed, raw.l1, pulseBusy, taps.Length())
    if (!transportBusy) {
        PersonalKey("LAlt", alt)
        Loop, 4 {
            i := A_Index
            PersonalKey(arrows[i], allowed and raw.r1 and !raw.l1 and PC.blocked.HasKey(i)
                and raw[i] and !PC.suppressed.HasKey(i))
        }
        ; A direct Enter/Escape/Ctrl shortcut must not regain inventory Alt
        ; during its short pulse. Require held arrows to release before reuse.
        if (taps.Length()) {
            Loop, 4 {
                i := A_Index
                if (PC.blocked.HasKey(i)) {
                    PC.suppressed[i] := true
                    PersonalKey(arrows[i], false)
                }
            }
        }
        for _, tap in taps
            PersonalChord(tap.key, tap.modifier, now)
    }

    anyButton := false
    Loop, 12
        if (raw[A_Index])
            anyButton := true
    busy := !allowed or anyButton or raw.ps
    touchEvent := PersonalTouchStep(PC.touch, raw.touch, PC.previous.touch, raw.l1
        , busy or raw.r1 or raw.l3 or raw.r3, now)
    if (touchEvent != "")
        PersonalChord(touchEvent, "", now)
    clickEvent := PersonalClicksStep(PC.clicks, raw.l3, raw.r3
        , PC.previous.l3, PC.previous.r3, busy or raw.l1 or raw.r1 or raw.touch)
    PersonalKey("vkBCsc033", clickEvent = "vkBCsc033")
    PersonalKey("vkBEsc034", clickEvent = "vkBEsc034")
    if (clickEvent = "h" or clickEvent = "r")
        PersonalChord(clickEvent, "", now)

    for name, gesture in PC.shoulders {
        other := name = "l1" ? raw.r1 : raw.l1
        consumed := busy or other or raw.touch or raw.l3 or raw.r3
        event := PersonalShoulderStep(gesture, raw[name], PC.previous[name]
            , consumed, now, PC.doubleTapMs)
        if (event = "switch") {
            target := PersonalClientTarget(active, gesture.direction)
            if (target and target != active) {
                ; A: clear the current client's target before focus changes.
                ; Queue the switch until the 40ms Escape pulse has completed.
                PersonalKey(gesture.key, false)
                PersonalChord("Escape", "", now)
                ; Count from completed emission, not the poll's earlier clock:
                ; file reads/SendEvent delays must not shorten Escape's hold.
                due := DllCall("GetTickCount64", "UInt64") + 40
                if (PC.keys.HasKey("Escape"))
                    PC.releases["Escape"] := due
                PC.switchPending := {owner:active, target:target, due:due}
            }
            PC.previous := raw
            return states
        } else if (event != "")
            PersonalChord(event, "", now)
    }
    PC.previous := raw
    return states
}

PersonalFilter(states, raw) {
    global PC
    for i, key in PC.blocked {
        states[i] := false
        if (!raw[i]) {
            if (i <= 4)
                PersonalKey(key, false)
            PC.blocked.Delete(i)
            PC.suppressed.Delete(i)
        }
    }
    return states
}

PersonalContext(hwnd) {
    if (!hwnd)
        return "unfocused"
    WinGetTitle, title, ahk_id %hwnd%
    now := A_NowUTC
    EnvSub, now, 19700101000000, Seconds
    Loop, Files, %A_ScriptDir%\data\personal-controls\*.ini
    {
        FileRead, lease, %A_LoopFileFullPath%
        if (!RegExMatch(lease, "m)^name=([A-Za-z]+)\r?$", name))
            continue
        if (!RegExMatch(title, "i)(^|[^a-z])" . name1 . "([^a-z]|$)"))
            continue
        if (!RegExMatch(lease, "m)^timestamp=(\d+)\r?$", stamp)
            or !RegExMatch(lease, "m)^mode=([^\r\n]+)\r?$", mode))
            return "unknown"
        age := now - stamp1
        return age >= -1 and age <= 2 ? mode1 : "stale"
    }
    return "unknown"
}

PersonalKey(key, down) {
    global PC
    if (down) {
        if (PC.keys.HasKey(key) or !PC.owner or PC.owner != WinActive("ahk_class FFXiClass"))
            return
        ; A genuinely held keyboard key remains owned by the keyboard.
        if GetKeyState(key, "P")
            return
        PC.keys[key] := PC.owner
        SendEvent, % "{Blind}{" . key . " down}"
    } else if (PC.keys.HasKey(key)) {
        owner := PC.keys[key]
        if (owner = WinExist("A")) {
            if (!GetKeyState(key, "P"))
                SendEvent, % "{Blind}{" . key . " up}"
        } else if WinExist("ahk_id " . owner)
            ControlSend,, % "{" . key . " up}", ahk_id %owner%
        PC.keys.Delete(key)
        PC.releases.Delete(key)
    }
}

PersonalTap(key, now) {
    global PC
    PersonalKey(key, true)
    if (PC.keys.HasKey(key))
        PC.releases[key] := now + 40
}

PersonalChord(key, modifier, now) {
    global PC
    PersonalKey("LControl", false)
    PersonalKey("LAlt", false)
    PersonalKey("LShift", false)
    if (modifier != "")
        PersonalKey(modifier, true)
    PersonalTap(key, now)
    if (modifier != "" and PC.keys.HasKey(modifier))
        PC.releases[modifier] := now + 40
}

PersonalReleaseDue(now) {
    global PC
    due := []
    for key, time in PC.releases
        if (now >= time)
            due.Push(key)
    for _, key in due
        if (key != "LControl" and key != "LAlt" and key != "LShift")
            PersonalKey(key, false)
    for _, key in due
        if (key = "LControl" or key = "LAlt" or key = "LShift")
            PersonalKey(key, false)
}

PersonalRelease(reset := true, keepAlt := false) {
    global PC
    if (!IsObject(PC) or !PC.enabled)
        return
    keys := []
    for key in PC.keys
        keys.Push(key)
    for _, key in keys
        if (key != "LControl" and key != "LAlt" and key != "LShift")
            PersonalKey(key, false)
    for _, key in keys
        if (key = "LControl" or key = "LAlt" or key = "LShift")
            PersonalKey(key, false)
    for i in PC.blocked
        PC.suppressed[i] := true
    if (reset)
        PC.ready := false
    PC.touch.phase := "cancelled"
    PC.clicks.phase := "cancelled"
    if (!keepAlt)
        PC.altLatched := false
    PC.switchPending := 0
    for _, gesture in PC.shoulders
        gesture.phase := "cancelled", gesture.pending := 0
}

PersonalOtherWindow(hwnd) {
    if (!hwnd or !WinExist("ahk_id " . hwnd))
        return false
    WinGetClass, class, ahk_id %hwnd%
    return class != "FFXiClass" and class != "Progman" and class != "WorkerW"
        and class != "Shell_TrayWnd" and class != "AutoHotkey" and class != "tooltips_class32"
}

PersonalPS(pressed, foreground, active, now) {
    global PC
    if (pressed and !PC.previous.ps) {
        PC.psPhase := "timing", PC.psStarted := now, PC.psFocus := foreground
    }
    if (PC.psPhase = "timing" and foreground != PC.psFocus)
        PC.psPhase := "cancelled"
    if (pressed and PC.psPhase = "timing" and active and now - PC.psStarted >= 500) {
        PC.psPhase := "fired"
        ReleaseTransport()
        if (PC.holdAction = "minimize") {
            WinGet, clients, List, ahk_class FFXiClass
            Loop, %clients% {
                id := clients%A_Index%
                WinMinimize, ahk_id %id%
            }
        } else {
            target := PC.lastOther
            if (!PersonalOtherWindow(target)) {
                WinGet, windows, List
                Loop, %windows% {
                    id := windows%A_Index%
                    if (PersonalOtherWindow(id)) {
                        target := id
                        break
                    }
                }
            }
            if (PersonalOtherWindow(target))
                WinActivate, ahk_id %target%
        }
    }
    if (!pressed and PC.previous.ps) {
        phase := PC.psPhase
        PC.psPhase := "idle"
        if (phase = "timing" and foreground = PC.psFocus)
            PersonalSwitchClient(active)
    }
}

PersonalClientTarget(active, direction := 1) {
    global PC
    WinGet, windows, List, ahk_class FFXiClass
    available := {}, ordered := []
    Loop, %windows%
        available[windows%A_Index%] := true
    for _, id in PC.clients
        if available.HasKey(id)
            ordered.Push(id)
    ; Append new clients without reordering existing ones on every activation.
    Loop, %windows% {
        index := windows - A_Index + 1
        id := windows%index%
        found := false
        for _, existing in ordered
            if (existing = id)
                found := true
        if (!found)
            ordered.Push(id)
    }
    PC.clients := ordered
    if (!ordered.Length())
        return
    target := ordered[1]
    if (!active and available.HasKey(PC.lastClient))
        target := PC.lastClient
    else if (active) {
        for index, id in ordered
            if (id = active)
                target := ordered[Mod(index - 1 + direction + ordered.Length(), ordered.Length()) + 1]
    }
    return target
}

PersonalSwitchClient(active, direction := 1) {
    target := PersonalClientTarget(active, direction)
    if (!target)
        return
    ReleaseTransport()
    WinActivate, ahk_id %target%
}
