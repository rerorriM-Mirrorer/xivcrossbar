; Bridge modes are supplied only by the fresh, foreground PID's DirectLink lease.
BridgeInit() {
    global CB, PPS
    PPS := PersonalPSState()
    CB := {client:0, movement:"off", ps:"off", gameplay:false, neutral:false, fired:false, armMode:"client", neutralSince:0,
        signalOwner:0, releaseAt:0, nextTrust:0, trustPolicy:"", trustReady:false,
        lastMovement:"idle", lastPS:"idle", zoom:false, zoomOwner:0, zoomKey:"", zoomState:{armed:false, previousL1:false}}
}

BridgeLease(lease) {
    global CB, PPS
    oldMovement := CB.movement, oldPS := CB.ps, oldArm := CB.armMode
    CB.movement := RegExMatch(lease, "m)^bridge_movement=(on|test|off)\r?$", &move) ? move[1] : "off"
    CB.ps := RegExMatch(lease, "m)^bridge_ps=(on|test|off)\r?$", &ps) ? ps[1] : "off"
    CB.gameplay := RegExMatch(lease, "m)^bridge_gameplay=1\r?$") != 0
    CB.zoom := RegExMatch(lease,"m)^bridge_zoom=1\r?$") != 0
    CB.armMode := RegExMatch(lease,"m)^movement_arm=neutral\r?$") ? "neutral" : "client"
    if (oldMovement != CB.movement || oldArm != CB.armMode) {
        BridgeRelease()
        CB.neutral := false, CB.fired := false, CB.neutralSince := 0
        CB.lastMovement := "idle"
    }
    if (oldPS != CB.ps) {
        PPS.down := true
        if (CB.ps = "off")
            PPS.returnClient := 0
        CB.lastPS := "idle"
    }
}

BridgeTrustReceiver(active) {
    global CB
    if (A_TickCount < CB.nextTrust)
        return
    CB.nextTrust := A_TickCount + 100
    CB.trustPolicy := "", CB.trustReady := false
    try title := WinGetTitle("ahk_id " . active)
    catch
        return
    now := DateDiff(A_NowUTC, "19700101000000", "Seconds")
    Loop Files A_ScriptDir . "\..\trust\data\movement\*.lease"
    {
        try lease := FileRead(A_LoopFileFullPath, "CP0")
        catch
            continue
        if (!RegExMatch(lease, "m)^name=([A-Za-z]+)\r?$", &name)
            or !RegExMatch(title, "i)(^|[^a-z])" . name[1] . "([^a-z]|$)")
            or !RegExMatch(lease, "m)^timestamp=(\d+)\r?$", &stamp)
            or !RegExMatch(lease, "m)^ready=([01])\r?$", &ready)
            or !RegExMatch(lease, "m)^policy=(Send|Ready)\r?$", &policy))
            continue
        age := now - stamp[1]
        if (age < -1 or age > 2)
            continue
        CB.trustPolicy := policy[1], CB.trustReady := ready[1] = "1"
        return
    }
}

BridgeRelease(all := true) {
    global CB
    if (all) {
        ZoomRelease()
        if (IsSet(CB))
            CB.zoomState := {armed:false,previousL1:false}
    }
    if (!IsSet(CB) or !CB.signalOwner)
        return
    target := CB.signalOwner
    CB.signalOwner := 0
    if (target = WinActive("ahk_class FFXiClass"))
        SendEvent("{Blind}{vk1Dsc07B up}")
    else if WinExist("ahk_id " . target)
        try ControlSend("{Blind}{vk1Dsc07B up}", , "ahk_id " . target)
}

BridgeDecision(feature, message) {
    global CB
    if (feature = "movement") {
        if (CB.lastMovement = message)
            return
        CB.lastMovement := message
    } else {
        if (CB.lastPS = message)
            return
        CB.lastPS := message
    }
    DiagRecord("bridge " . feature . ": " . message)
}

BridgePoll(states, active) {
    global CB, CM, profile
    if (CB.signalOwner and (CB.signalOwner != active or A_TickCount >= CB.releaseAt))
        BridgeRelease(CB.signalOwner != active)
    if (CB.client != active) {
        CB.client := active, CB.neutral := false, CB.fired := false, CB.neutralSince := 0
        CB.nextTrust := 0
    }
    zoomEligible := CM.requested && CM.phase = "messages" && A_TickCount-CM.seen<=350 && CB.gameplay && CB.zoom && CM.count=23
    ZoomPoll(states,active,zoomEligible)
    if (!CM.requested or CM.phase != "messages" or A_TickCount - CM.seen > 350)
        return
    if (CB.movement != "off" and states.HasOwnProp("moveX")) {
        magnitude := states.moveX * states.moveX + states.moveY * states.moveY
        MovementArmStep(CB,magnitude,A_TickCount)
        if (magnitude >= .24 * .24 && !CB.fired) {
            if (!CB.neutral)
                BridgeDecision("movement", "waiting for neutral")
            else {
                BridgeTrustReceiver(active)
                if (CB.trustPolicy = "")
                    BridgeDecision("movement", "matching Trust receiver unavailable")
                else if (CB.trustPolicy = "Ready" and (!CB.trustReady or !CB.gameplay))
                    BridgeDecision("movement", "Ready waiting for Trust and gameplay")
                else if (WinActive("ahk_class FFXiClass") = active) {
                    CB.fired := true, CB.neutral := false
                    if (CB.movement = "test")
                        BridgeDecision("movement", "Would signal Trust " . CB.trustPolicy)
                    else {
                        CB.signalOwner := active, CB.releaseAt := A_TickCount + 30
                        SendEvent("{Blind}{vk1Dsc07B down}")
                        BridgeDecision("movement", "Signaled Trust " . CB.trustPolicy)
                    }
                }
                if (CB.armMode = "neutral")
                    CB.fired := true, CB.neutral := false
            }
        }
    }
}

BridgeOutside() {
    global CB
    BridgeRelease()
    CB.client := 0
    PersonalPSPoll(ReadTransportStates(GetKeyState,true),0,CB.ps,false)
}

; Hysteresis plus 100 ms centered time prevents steering noise from rearming.
MovementArmStep(s, magnitude, now) {
    if (magnitude < .12*.12) {
        if (!s.neutralSince)
            s.neutralSince := now
        if (now-s.neutralSince>=100) {
            s.neutral := true
            if (s.armMode = "neutral")
                s.fired := false
        }
    } else
        s.neutralSince := 0
    return magnitude>=.24*.24 && s.neutral && !s.fired
}

; Require L1 first and a centered right stick. Never adopt a held zoom across clients.
ZoomDecision(s,states,eligible) {
    l1 := eligible && states.Length>=23 && states[13] && !states[14] && !states[11] && !states[12] && !states[9] && !states[10]
    Loop 8
        if (states[A_Index])
            l1 := false
    if (!l1 || !s.previousL1)
        s.armed := false
    if (l1 && !states[20] && !states[21] && !states[22] && !states[23])
        s.armed := true
    s.previousL1 := l1
    return l1 && s.armed ? (states[20] && !states[22] ? "vkBE" : states[22] && !states[20] ? "vkBC" : "") : ""
}
ZoomRelease() {
    global CB
    if (!IsSet(CB) || !CB.HasOwnProp("zoomOwner") || !CB.zoomOwner)
        return
    owner := CB.zoomOwner, key := CB.zoomKey
    CB.zoomOwner := 0, CB.zoomKey := ""
    if (owner = WinActive("ahk_class FFXiClass"))
        SendEvent("{Blind}{" . key . " up}")
    else if WinExist("ahk_id " . owner)
        try ControlSend("{Blind}{" . key . " up}",,"ahk_id " . owner)
}
ZoomPoll(states,active,eligible) {
    global CB
    if (CB.zoomOwner && CB.zoomOwner != active) {
        ZoomRelease()
        CB.zoomState := {armed:false,previousL1:false}
    }
    eligible := eligible && !GetKeyState("Alt","P") && !GetKeyState("Ctrl","P") && !GetKeyState("Shift","P") && !GetKeyState("LWin","P") && !GetKeyState("RWin","P")
    key := ZoomDecision(CB.zoomState,states,eligible)
    if (CB.zoomKey != key)
        ZoomRelease()
    if (key != "" && !CB.zoomOwner && active && WinActive("ahk_class FFXiClass")=active) {
        CB.zoomOwner := active, CB.zoomKey := key
        SendEvent("{Blind}{" . key . " down}")
    }
}
