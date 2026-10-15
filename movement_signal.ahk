; A: Trust movement experiment 0.1.0, AutoHotkey v1.
; One signal per observed FFXI focus session. Neutral, modifier releases,
; disconnection and trips to other applications do not reset that latch.
MovementInit() {
    global TM
    TM := {client:0, fired:false, sent:0, signalOwner:0, due:0
        , nextLease:0, ready:false, reason:"waiting-client", threshold:0.24}
}

MovementTick(active) {
    global TM
    if (TM.signalOwner and (active != TM.signalOwner
        or DllCall("GetTickCount64", "UInt64") >= TM.due))
        MovementRelease()
    ; Keep the last FFXI identity while the desktop or another app is active.
    if (active and active != TM.client) {
        TM.client := active, TM.fired := false
        TM.nextLease := 0, TM.ready := false, TM.reason := "armed"
    }
}

MovementPoll(states, active) {
    global TM, PC
    if (TM.fired or !active or !states.HasKey("moveX") or !states.HasKey("moveY"))
        return
    if (states.moveX * states.moveX + states.moveY * states.moveY < TM.threshold * TM.threshold)
        return
    ; Existing personal controls expose addon menus as well as text entry.
    ; Holding a crossbar trigger alone still permits movement takeover.
    if (PC.enabled) {
        context := PersonalContext(active)
        if (context != "gameplay" and context != "crossbar") {
            TM.reason := "personal-" . context
            return
        }
    }
    if (!MovementReceiverReady(active))
        return
    ; Recheck immediately before injecting. Blind preserves held modifiers;
    ; this is a separate scan code, outside the wrapper's F1-F12 signals.
    if (WinActive("ahk_class FFXiClass") != active)
        return
    TM.fired := true, TM.sent += 1, TM.reason := "sent"
    TM.signalOwner := active
    TM.due := DllCall("GetTickCount64", "UInt64") + 30
    SendEvent, {Blind}{vk1Dsc07B down}
    WinGetTitle, title, ahk_id %active%
    line := A_NowUTC . " hwnd=" . active . " title=" . title . " x=" . states.moveX . " y=" . states.moveY . "`n"
    FileAppend, %line%, %A_ScriptDir%\data\trust-movement.log
}

MovementReceiverReady(active) {
    global TM
    nowTick := DllCall("GetTickCount64", "UInt64")
    if (nowTick < TM.nextLease)
        return TM.ready
    TM.nextLease := nowTick + 100, TM.ready := false
    TM.reason := "receiver-not-ready"
    WinGetTitle, title, ahk_id %active%
    now := A_NowUTC
    EnvSub, now, 19700101000000, Seconds
    ; The receiver publishes only while its own client has focus. Match the
    ; character in the title, as the existing personal-controls bridge does.
    Loop, Files, %A_ScriptDir%\..\trustmovement\data\*.lease
    {
        FileRead, lease, %A_LoopFileFullPath%
        if (!RegExMatch(lease, "m)^name=([A-Za-z]+)\r?$", name)
            or !RegExMatch(title, "i)(^|[^a-z])" . name1 . "([^a-z]|$)"))
            continue
        if (!RegExMatch(lease, "m)^timestamp=(\d+)\r?$", stamp)
            or !RegExMatch(lease, "m)^ready=([01])\r?$", ready))
            continue
        age := now - stamp1
        if (age < -1 or age > 2) {
            TM.reason := "receiver-stale"
            continue
        }
        TM.ready := ready1 = "1"
        TM.reason := TM.ready ? "receiver-ready" : "receiver-blocked"
        return TM.ready
    }
    return false
}

MovementRelease() {
    global TM
    if (!IsObject(TM) or !TM.signalOwner)
        return
    target := TM.signalOwner
    TM.signalOwner := 0
    if (target = WinActive("ahk_class FFXiClass")) {
        SendEvent, {Blind}{vk1Dsc07B up}
    } else if WinExist("ahk_id " . target) {
        ControlSend,, {Blind}{vk1Dsc07B up}, ahk_id %target%
    }
}
