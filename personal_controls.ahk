; A: isolated, optional PS5 personal controls. No output in ordinary profiles.
; This include owns its keys; base Apps/F1-F12 routing stays in the wrapper.
PersonalInit(selected, prefix) {
    global PC
    PC := {enabled:selected = "ps5-extended", prefix:prefix, owner:0, ready:false
        , keys:{}, releases:{}, blocked:{}, suppressed:{}, previous:[], connected:false
        , touch:{phase:"idle"}, clicks:{phase:"idle"}
        , shoulders:{r1:{phase:"idle", key:"F8"}}, layer:{phase:"idle"}, layerVisible:""
        , l1:{token:"", mode:"keyboard", seq:0, ack:0, pending:[], available:false, showing:false}
        , clients:[], lastClient:0, lastOther:0, contextSeen:0, contextPaused:false, contextPauses:0
        , targetR2:false, targetR3:false}
    ; Old PSHoldAction/DoubleTapMs preferences remain untouched but are dormant.
}

PersonalPoll(states, active) {
    global PC, appsOwned, previous
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
    if (PersonalLeasePause(mode, now, PC.contextSeen, PC.ready)) {
        if (!PC.contextPaused) {
            PC.contextPauses += 1
            InputTraceRecord("context pause; no new downs")
        }
        PC.contextPaused := true, PC.context := "updating"
        ; Keep existing transport holds only while still physically held. New
        ; downs wait for a verified current lease; releases are never delayed.
        Loop, 12
            states[A_Index] := states[A_Index] and previous[A_Index]
        PersonalL1Block(raw)
        return PersonalFilter(states, raw)
    }
    if (PC.contextPaused)
        InputTraceRecord("context resume=" . mode)
    PC.contextPaused := false
    if (mode = "gameplay" or mode = "crossbar")
        PC.contextSeen := now
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
        if (allowed)
            PersonalL1Block(raw)
        PC.previous := raw
        return PersonalFilter(states, raw)
    }

    arrows := ["Up", "Right", "Down", "Left"]
    PersonalTargetTrial(raw, mode)
    layer := PersonalLayerStep(PC.layer, raw.l1, raw[11], raw.r1, raw[12])
    layerChanged := layer != PC.layerVisible
    if (layerChanged) {
        PersonalRelease(false)
        if (layer = "keyboard" or layer = "bank") {
            ; Release the old ordinary transport before revealing L1. A held
            ; slot is consumed on reveal, never executed in the new layer.
            ReleaseTransport(true)
            PersonalL1Block(raw)
            PersonalL1Event(layer = "bank" ? "bank" : "show")
        } else
            PersonalL1Event("release")
        PC.layerVisible := layer
        InputTraceRecord("layer " . layer)
    }
    if (layer = "bank" or layer = "tail")
        states[11] := false
    if (layer = "tail") {
        Loop, 12
            if (raw[A_Index])
                PC.blocked[A_Index] := ""
    }
    allowed := contextAllowed and layer != "ordinary" and layer != "tail" and !raw[12] and !appsOwned
    if (!allowed) {
        PersonalRelease(false)
        PC.previous := raw
        return PersonalFilter(states, raw)
    }

    taps := []
    ; Each assigned Ctrl shortcut fires once. Empty L1 slots are reserved and
    ; consume their button rather than leaking native confirm/cancel.
    if ((layer = "keyboard" or layer = "bank") and !raw.r1) {
        shortcuts := {1:"i", 2:"m", 3:"e", 4:"j", 5:"Space", 6:"q", 7:"", 8:"s"}
        for i, key in shortcuts {
            if (!layerChanged and raw[i] and !PC.previous[i]) {
                PC.blocked[i] := key
                if (PC.l1.available and layer = "bank") {
                    slots := [4, 3, 2, 1, 6, 5, 7, 8]
                    PersonalL1Event("slot", slots[i])
                } else if (layer = "keyboard" and key != "")
                    taps.Push({key:key, modifier:"LControl"})
            }
        }
        ; A held button from before L1 is consumed, never re-fired or leaked.
        PersonalL1Block(raw)
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
        if (event != "")
            PersonalChord(event, "", now)
    }
    PC.previous := raw
    return states
}

PersonalFilter(states, raw) {
    global PC
    if (!PC.blocked.Count())
        return states
    retired := []
    for i, key in PC.blocked {
        states[i] := false
        if (!raw[i]) {
            if (i <= 4)
                PersonalKey(key, false)
            retired.Push(i)
        }
    }
    ; AHK enumerators can skip the next entry if the current key is deleted.
    ; Finish masking every held button before retiring released entries.
    for _, i in retired {
        PC.blocked.Delete(i)
        PC.suppressed.Delete(i)
    }
    return states
}

PersonalContext(hwnd) {
    global PC
    if (!hwnd)
        return "unfocused"
    WinGetTitle, title, ahk_id %hwnd%
    now := A_NowUTC
    EnvSub, now, 19700101000000, Seconds
    ; Retry the directory read once without sleeping: Lua's remove/rename
    ; publication may complete between scans. Never reuse cached permission.
    Loop, 2 {
        Loop, Files, %A_ScriptDir%\data\personal-controls\*.ini
        {
            FileRead, lease, %A_LoopFileFullPath%
            if (!RegExMatch(lease, "m)^name=([A-Za-z]+)\r?$", name))
                continue
            if (!RegExMatch(title, "i)(^|[^a-z])" . name1 . "([^a-z]|$)"))
                continue
            if (!RegExMatch(lease, "m)^timestamp=(\d+)\r?$", stamp)
                or !RegExMatch(lease, "m)^mode=([^\r\n]+)\r?$", mode)
                or !RegExMatch(lease, "m)^END\r?$"))
                return InputTraceContextMiss("malformed")
            age := now - stamp1
            if (age >= -1 and age <= 2) {
                PersonalL1Lease(lease, A_LoopFileFullPath)
                return mode1
            }
            return InputTraceContextMiss("stale")
        }
    }
    return InputTraceContextMiss("no-matching-lease")
}

; A: complete mailbox snapshots; only Lua's current session token may receive
; edges. No F13/media-key experiment, synthetic menu keys or process IPC hook.
PersonalL1Lease(lease, contextPath) {
    global PC
    ; Native menu toggles still use keyboard shortcuts on the L1 layer. Only
    ; bank events need an executable play token; text is blocked by
    ; the ordinary context gate above.
    if RegExMatch(lease, "m)^l1mode=(keyboard|bank)\r?$", mode)
        PC.l1.mode := mode1
    if (!RegExMatch(lease, "m)^l1token=([A-Za-z0-9-]+)\r?$", token)
        or !RegExMatch(lease, "m)^l1mode=(keyboard|bank)\r?$", mode)
        or !RegExMatch(lease, "m)^l1ack=(\d+)\r?$", ack)) {
        PC.l1.available := false
        PC.targetR2 := false, PC.targetR3 := false
        return
    }
    if (PC.l1.token != token1) {
        PC.l1 := {token:token1, mode:mode1, seq:0, ack:0, pending:[], available:true
            , path:RegExReplace(contextPath, "\.ini$", ".l1"), showing:false}
        PC.ready := false
    }
    PC.l1.available := true, PC.l1.mode := mode1, PC.l1.ack := ack1 + 0
    PC.targetR2 := RegExMatch(lease, "m)^target_r2=1\r?$") ? true : false
    PC.targetR3 := RegExMatch(lease, "m)^target_r3=1\r?$") ? true : false
    retained := []
    for _, event in PC.l1.pending
        if (event.seq > PC.l1.ack)
            retained.Push(event)
    PC.l1.pending := retained
}

PersonalL1Block(raw) {
    global PC
    if (raw.l1)
        Loop, 8
            if (raw[A_Index] and !PC.blocked.HasKey(A_Index))
                PC.blocked[A_Index] := ""
}

PersonalL1Event(kind, slot := 0) {
    global PC
    if (!PC.l1.available or PC.l1.pending.Length() >= 64)
        return false
    if ((kind = "release" or kind = "cancel") and !PC.l1.showing)
        return false
    PC.l1.seq += 1
    event := {seq:PC.l1.seq, kind:kind, slot:slot}
    PC.l1.pending.Push(event)
    if (kind = "show" or kind = "bank")
        PC.l1.showing := true
    else if (kind = "release" or kind = "cancel")
        PC.l1.showing := false
    stamp := A_NowUTC
    EnvSub, stamp, 19700101000000, Seconds
    contents := "token=" . PC.l1.token . "`nstamp=" . stamp . "`n"
    for _, edge in PC.l1.pending
        contents .= edge.seq . "," . edge.kind . "," . edge.slot . "`n"
    contents .= "END`n"
    temporary := PC.l1.path . ".tmp"
    destination := PC.l1.path
    FileDelete, %temporary%
    FileAppend, %contents%, %temporary%
    if (ErrorLevel)
        return false
    FileMove, %temporary%, %destination%, 1
    return !ErrorLevel
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
        InputTraceRecord("personal " . key . " down owner=" . PC.owner)
        SendEvent, % "{Blind}{" . key . " down}"
    } else if (PC.keys.HasKey(key)) {
        owner := PC.keys[key]
        InputTraceRecord("personal " . key . " up owner=" . owner)
        if (owner = WinExist("A")) {
            if (!GetKeyState(key, "P"))
                SendEvent, % "{Blind}{" . key . " up}"
        } else if WinExist("ahk_id " . owner)
            ControlSend,, % "{" . key . " up}", ahk_id %owner%
        PC.keys.Delete(key)
        PC.releases.Delete(key)
    }
}

; A: isolated opt-in acquisition experiment. Use the existing sender's key
; delay between F8 down/up; add no Sleep or global SetKeyDelay change. F8 is
; fully released before the ordinary Apps+F12 signal or stick-click handling.
PersonalTargetTrial(raw, mode) {
    global PC, appsOwned
    if (mode != "gameplay" or !PC.l1.available or appsOwned or PC.keys.Count()
        or raw.l1 or raw.r1 or raw.l3 or raw.touch or raw.ps or raw.mute)
        return
    Loop, 11
        if (raw[A_Index])
            return
    source := ""
    if (PC.targetR2 and raw[12] and !PC.previous[12] and !raw.r3)
        source := "R2"
    else if (PC.targetR3 and raw.r3 and !PC.previous.r3 and !raw[12] and PC.clicks.phase = "idle")
        source := "R3"
    if (source = "")
        return
    for _, key in ["Control", "Alt", "Shift", "LWin", "RWin", "AppsKey", "F8"]
        if GetKeyState(key, "P")
            return
    InputTraceRecord("target prefire=" . source)
    PersonalKey("F8", true)
    PersonalKey("F8", false)
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
    if (reset) {
        PersonalL1Event("cancel")
        PC.layer.phase := "idle", PC.layerVisible := ""
        PC.contextSeen := 0, PC.contextPaused := false
    }
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
