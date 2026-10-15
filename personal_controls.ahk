; A: isolated, optional PS5 personal controls. No output in ordinary profiles.
; This include owns its keys; base Apps/F1-F12 routing stays in the wrapper.
PersonalInit(selected, prefix) {
    global PC
    PC := {enabled:selected = "ps5-extended", prefix:prefix, owner:0, ready:false
        , keys:{}, releases:{}, blocked:{}, suppressed:{}, previous:[], connected:false
        , touch:{phase:"idle"}, clicks:{phase:"idle"}, navigation:{ctrl:false, alt:false}
        , shoulders:{l1:{phase:"idle", key:"switch"}, r1:{phase:"idle", key:"F8"}}
        , clients:[], lastClient:0, lastOther:0, navigationActive:false}
    ; Old PSHoldAction/DoubleTapMs preferences remain untouched but are dormant.
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
        PC.connected := false, PC.previous := []
        return states
    }
    raw := []
    for i, value in states
        raw[i] := value
    for name, button in {l1:5, r1:6, l3:11, r3:12, ps:13, touch:14, mute:15}
        raw[name] := GetKeyState(PC.prefix . "Joy" . button) ? true : false
    now := DllCall("GetTickCount64", "UInt64")
    if (!PC.connected) {
        PC.connected := true, PC.previous := raw
        PC.ready := false, PC.blocked := {}, PC.suppressed := {}
        return states
    }
    PersonalPS(raw.ps, foreground, active, raw.l1 or raw.r1 or raw[11] or raw[12])
    if (WinActive("ahk_class FFXiClass") != active) {
        PC.previous := raw
        return states
    }
    if (PC.owner != active) {
        PersonalRelease()
        PC.owner := active, PC.previous := raw
    }
    PersonalReleaseDue(now)
    mode := PersonalContext(active)
    PC.context := mode
    contextAllowed := active and (mode = "gameplay" or mode = "crossbar") and !raw[9] and !raw[10]
    allowed := contextAllowed and mode = "gameplay" and !raw[11] and !raw[12] and !appsOwned
    neutral := !raw.l1 and !raw.r1 and !raw.l3 and !raw.r3 and !raw.touch and !raw.ps and !raw.mute
    Loop, 12
        if (raw[A_Index])
            neutral := false
    if (!contextAllowed) {
        PersonalRelease()
        PC.previous := raw
        return PersonalFilter(states, raw)
    }
    if (!PC.ready) {
        if (allowed and neutral) {
            PC.ready := true
            PC.touch.phase := "idle", PC.clicks.phase := "idle"
            for _, gesture in PC.shoulders
                gesture.phase := "idle"
        }
        PC.previous := raw
        return PersonalFilter(states, raw)
    }

    arrows := ["Up", "Right", "Down", "Left"]
    navigation := PersonalModifierStep(PC.navigation, raw.l1, raw[11], raw.r1, raw[12], contextAllowed)
    if (navigation != "") {
        if (!PC.navigationActive) {
            PersonalRelease(false)
            ; Release Apps/F11/F12 before native modifiers: no Apps+Ctrl+arrow
            ; and no crossbar action from the same physical chord.
            ReleaseTransport(true)
            PC.navigationActive := true
        }
        Loop, 12 {
            i := A_Index
            if (raw[i]) {
                PC.blocked[i] := i <= 4 ? arrows[i] : ""
                if (!PC.previous[i] and i <= 4)
                    PC.suppressed.Delete(i)
                else if (i <= 4 and !PC.keys.HasKey(arrows[i]))
                    PC.suppressed[i] := true
            }
        }
        PersonalKey("LControl", PC.navigation.ctrl)
        PersonalKey("LAlt", PC.navigation.alt)
        Loop, 4 {
            i := A_Index
            PersonalKey(arrows[i], raw[i] and !PC.suppressed.HasKey(i))
        }
        PC.previous := raw
        return PersonalFilter(states, raw)
    }
    if (PC.navigationActive) {
        PersonalRelease(false)
        PC.navigationActive := false
    }
    if (!allowed) {
        PersonalRelease(false)
        PC.previous := raw
        return PersonalFilter(states, raw)
    }

    taps := []
    ; Each assigned Ctrl shortcut fires once. Empty L1 slots are reserved and
    ; consume their button rather than leaking native confirm/cancel.
    if (raw.l1 and !raw.r1) {
        shortcuts := {1:"i", 2:"m", 3:"e", 4:"j", 5:"Space", 6:"q", 7:"", 8:"s"}
        for i, key in shortcuts {
            if (raw[i] and !PC.previous[i]) {
                PC.blocked[i] := key
                if (key != "")
                    taps.Push({key:key, modifier:"LControl"})
            }
        }
    } else if (raw.r1 and !raw.l1) {
        Loop, 4 {
            i := A_Index
            if (raw[i] and !PC.previous[i])
                PC.blocked[i] := arrows[i]
        }
        for i, key in {5:"Enter", 7:"Escape", 8:"NumpadAdd"} {
            if (raw[i] and !PC.previous[i]) {
                PC.blocked[i] := key
                taps.Push({key:key, modifier:i = 8 ? "LControl" : ""})
            }
        }
    } else if (raw.l1 and raw.r1) {
        Loop, 8
            if (raw[A_Index])
                PC.blocked[A_Index] := ""
        if (!PC.previous.l1 or !PC.previous.r1)
            taps.Push({key:"Tab", modifier:""})
    }
    states := PersonalFilter(states, raw)
    transportBusy := false
    Loop, 12
        if (states[A_Index])
            transportBusy := true
    if (transportBusy)
        PersonalRelease(false)
    else {
        Loop, 4 {
            i := A_Index
            PersonalKey(arrows[i], raw.r1 and !raw.l1 and PC.blocked.HasKey(i)
                and raw[i] and !PC.suppressed.HasKey(i))
        }
        if (taps.Length()) {
            Loop, 4 {
                i := A_Index
                if (PC.blocked[i] = arrows[i]) {
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
    busy := transportBusy or anyButton or raw.ps or raw.mute
    touchEvent := PersonalTouchStep(PC.touch, raw.touch, PC.previous.touch
        , busy or raw.l1 or raw.r1 or raw.l3 or raw.r3, now)
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
        event := PersonalShoulderStep(gesture, raw[name], PC.previous[name], consumed)
        if (event = "switch") {
            PersonalSwitchClient(active)
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

PersonalRelease(reset := true) {
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
    if (reset) {
        PC.navigation.ctrl := false, PC.navigation.alt := false
        PC.navigationActive := false
    }
    for _, gesture in PC.shoulders
        gesture.phase := "cancelled"
}

PersonalOtherWindow(hwnd) {
    if (!hwnd or !WinExist("ahk_id " . hwnd))
        return false
    WinGetClass, class, ahk_id %hwnd%
    return class != "FFXiClass" and class != "Progman" and class != "WorkerW"
        and class != "Shell_TrayWnd" and class != "AutoHotkey" and class != "tooltips_class32"
}

PersonalPS(pressed, foreground, active, consumed) {
    global PC
    ; A single fresh press toggles focus. Holds never cycle or minimize clients.
    if (!pressed or PC.previous.ps or consumed)
        return
    target := active ? PC.lastOther : PersonalClientTarget(0)
    if (active and !PersonalOtherWindow(target)) {
        WinGet, windows, List
        Loop, %windows% {
            id := windows%A_Index%
            if (PersonalOtherWindow(id)) {
                target := id
                break
            }
        }
    }
    if (!target or (active and !PersonalOtherWindow(target)))
        return
    ReleaseTransport()
    PersonalActivate(target)
}

PersonalActivate(target) {
    if (!target or !WinExist("ahk_id " . target))
        return
    WinGet, minimized, MinMax, ahk_id %target%
    if (minimized = -1)
        WinRestore, ahk_id %target%
    WinActivate, ahk_id %target%
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
    if (!target or target = active)
        return
    ReleaseTransport()
    PersonalActivate(target)
}
