; Bridge modes are supplied only by the fresh, foreground PID's DirectLink lease.
BridgeInit() {
    global CB
    CB := {client:0, movement:"off", ps:"off", gameplay:false, neutral:false, fired:false,
        signalOwner:0, releaseAt:0, nextTrust:0, trustPolicy:"", trustReady:false,
        lastMovement:"idle", lastPS:"idle", psDown:true, observedOutside:0, other:0, otherPID:0, returnClient:0,
        returnPID:0, returnUntil:0}
}

BridgeLease(lease) {
    global CB
    oldMovement := CB.movement, oldPS := CB.ps
    CB.movement := RegExMatch(lease, "m)^bridge_movement=(on|test|off)\r?$", &move) ? move[1] : "off"
    CB.ps := RegExMatch(lease, "m)^bridge_ps=(on|test|off)\r?$", &ps) ? ps[1] : "off"
    CB.gameplay := RegExMatch(lease, "m)^bridge_gameplay=1\r?$") != 0
    if (oldMovement != CB.movement) {
        BridgeRelease()
        CB.neutral := false, CB.fired := false
        CB.lastMovement := "idle"
    }
    if (oldPS != CB.ps) {
        CB.psDown := true
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

BridgeRelease() {
    global CB
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
        BridgeRelease()
    if (CB.client != active) {
        CB.client := active, CB.neutral := false, CB.fired := false
        CB.nextTrust := 0, CB.psDown := true, CB.returnClient := 0
    }
    if (!CM.requested or CM.phase != "messages" or A_TickCount - CM.seen > 350)
        return
    if (CB.movement != "off" and !CB.fired and states.HasOwnProp("moveX")) {
        magnitude := states.moveX * states.moveX + states.moveY * states.moveY
        if (magnitude < .12 * .12)
            CB.neutral := true
        if (magnitude >= .24 * .24) {
            if (!CB.neutral)
                BridgeDecision("movement", "waiting for neutral")
            else {
                BridgeTrustReceiver(active)
                if (CB.trustPolicy = "")
                    BridgeDecision("movement", "matching Trust receiver unavailable")
                else if (CB.trustPolicy = "Ready" and (!CB.trustReady or !CB.gameplay))
                    BridgeDecision("movement", "Ready waiting for Trust and gameplay")
                else if (WinActive("ahk_class FFXiClass") = active) {
                    CB.fired := true
                    if (CB.movement = "test")
                        BridgeDecision("movement", "Would signal Trust " . CB.trustPolicy)
                    else {
                        CB.signalOwner := active, CB.releaseAt := A_TickCount + 30
                        SendEvent("{Blind}{vk1Dsc07B down}")
                        BridgeDecision("movement", "Signaled Trust " . CB.trustPolicy)
                    }
                }
            }
        }
    }
    if (profile != "ps5-directinput" or !states.HasOwnProp("ps"))
        return
    fresh := states.ps and !CB.psDown
    CB.psDown := states.ps
    if (!fresh or CB.ps = "off")
        return
    if (!CB.gameplay)
        return BridgeDecision("ps", "blocked by context")
    for _, held in states
        if (held)
            return BridgeDecision("ps", "blocked by chord")
    target := CB.other
    try valid := (target && WinGetPID("ahk_id " . target) = CB.otherPID
        && WinGetClass("ahk_id " . target) != "FFXiClass")
    catch
        valid := false
    if (!valid)
        return BridgeDecision("ps", "no remembered non-FFXI window")
    if (CB.ps = "test")
        return BridgeDecision("ps", "Would activate HWND " . target)
    if (WinActive("ahk_class FFXiClass") != active)
        return
    try {
        CB.returnPID := WinGetPID("ahk_id " . active)
        CB.returnClient := active, CB.returnUntil := 0
        ReleaseTransport()
        WinActivate("ahk_id " . target)
        BridgeDecision("ps", "Activated HWND " . target)
    }
}

BridgeOutside() {
    global CB, profile, joystickPrefix
    BridgeRelease()
    CB.client := 0
    foreground := WinActive("A")
    if (foreground and foreground != CB.observedOutside) {
        CB.observedOutside := foreground
        try {
            if (WinGetTitle("ahk_id " . foreground) != "")
                CB.other := foreground, CB.otherPID := WinGetPID("ahk_id " . foreground)
        }
    }
    if (!CB.returnClient or profile != "ps5-directinput")
        return
    if (!WinExist("ahk_id " . CB.returnClient)
        or GetKeyState(joystickPrefix . "JoyName") = "") {
        CB.returnClient := 0
        return
    }
    pressed := GetKeyState(joystickPrefix . "Joy13") ? true : false
    fresh := pressed and !CB.psDown
    CB.psDown := pressed
    if (!fresh)
        return
    target := CB.returnClient
    CB.returnClient := 0
    try {
        if (WinGetPID("ahk_id " . target) = CB.returnPID and WinGetClass("ahk_id " . target) = "FFXiClass") {
            WinActivate("ahk_id " . target)
            BridgeDecision("ps", "Returned to FFXI HWND " . target)
        }
    }
}
