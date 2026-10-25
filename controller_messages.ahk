; Beta 1: independent twelve-button PS5 message reader.
; Apps/F-key transport remains untouched for every other controller profile.
ControllerMessageInit() {
    global CM
    CM := {requested:false, token:"", ack:0, seq:0, pending:[], previous:[]
        , phase:"keys", seen:0, path:"", nextWrite:0, error:false}
}
ControllerMessageContext(hwnd) {
    global CM, profile
    if (profile != "ps5-directinput" or !hwnd)
        return
    WinGetTitle, title, ahk_id %hwnd%
    now := A_NowUTC
    EnvSub, now, 19700101000000, Seconds
    found := false
    Loop, Files, %A_ScriptDir%\data\directlink\*.ini
    {
        FileRead, lease, %A_LoopFileFullPath%
        if (!RegExMatch(lease, "m)^name=([A-Za-z]+)\r?$", name))
            continue
        if (!RegExMatch(title, "i)(^|[^a-z])" . name1 . "([^a-z]|$)"))
            continue
        if (!RegExMatch(lease, "m)^timestamp=(\d+)\r?$", stamp)
            or !RegExMatch(lease, "m)^button_mode=(messages|keys)\r?$", mode)
            or !RegExMatch(lease, "m)^END\r?$"))
            break
        age := now - stamp1
        if (age < -1 or age > 2)
            break
        requested := mode1 = "messages"
        token := ""
        ackValue := 0
        if (requested) {
            if (!RegExMatch(lease, "m)^button_token=([A-Za-z0-9-]+)\r?$", value)
                or !RegExMatch(lease, "m)^button_ack=(\d+)\r?$", ack))
                break
            token := value1, ackValue := ack1 + 0
        }
        ControllerMessageSelect(requested, token, ackValue, RegExReplace(A_LoopFileFullPath, "\.ini$", ".buttons"))
        found := true
        break
    }
    ; Do not trust the previous client's cached permission after a focus switch.
    if (!found and CM.requested and A_TickCount - CM.seen > 150)
        CM.phase := "uncertain"
}
ControllerMessageSelect(requested, token, ack, path) {
    global CM
    if (requested != CM.requested or token != CM.token or path != CM.path) {
        ReleaseTransport()
        CM.requested := requested, CM.token := token, CM.seq := ack, CM.ack := ack
        CM.pending := [], CM.previous := [], CM.phase := "neutral"
        CM.nextWrite := 0, CM.path := path
        if (requested) {
            ControllerMessageAdd("cancel", 0)
            ControllerMessageFlush(true)
        }
    }
    CM.seen := A_TickCount
    if (requested) {
        CM.ack := ack
        retained := []
        for _, event in CM.pending
            if (event.seq > ack)
                retained.Push(event)
        CM.pending := retained
    }
}
ControllerMessageAdd(kind, button) {
    global CM
    CM.seq += 1
    CM.pending.Push({seq:CM.seq, kind:kind, button:button, tick:A_TickCount})
}
ControllerMessageCancel() {
    global CM
    if (!IsObject(CM) or !CM.requested)
        return
    if (CM.phase = "messages" or CM.phase = "backpressure") {
        ControllerMessageAdd("cancel", 0)
        ControllerMessageFlush(true)
    }
    CM.previous := [], CM.phase := "neutral"
}
ControllerMessageFlush(force := false) {
    global CM
    if (!CM.requested or CM.token = "" or CM.path = "")
        return false
    if (!force and A_TickCount < CM.nextWrite)
        return true
    CM.nextWrite := A_TickCount + 100
    stamp := A_NowUTC
    EnvSub, stamp, 19700101000000, Seconds
    contents := "token=" . CM.token . "`nstamp=" . stamp . "`nbeat=" . A_TickCount . "`n"
    for _, event in CM.pending
        contents .= event.seq . "," . event.kind . "," . event.button . "`n"
    contents .= "END`n"
    temporary := CM.path . ".tmp"
    FileDelete, %temporary%
    FileAppend, %contents%, %temporary%
    if (!ErrorLevel)
        FileMove, %temporary%, % CM.path, 1
    CM.error := ErrorLevel ? true : false
    return !CM.error
}
ControllerMessagePoll(states, hwnd) {
    global CM, profile
    if (profile != "ps5-directinput")
        return false
    if (hwnd)
        ControllerMessageContext(hwnd)
    neutral := true
    Loop, 12
        if (states[A_Index])
            neutral := false
    now := A_TickCount
    if (CM.requested and (CM.phase = "uncertain" or now - CM.seen > 350)) {
        if (CM.phase = "messages")
            ControllerMessageCancel()
        CM.phase := "uncertain"
        if (neutral and now - CM.seen > 2500) {
            CM.requested := false, CM.token := "", CM.phase := "keys"
        }
        return true
    }
    if (CM.phase = "neutral") {
        if (neutral)
            CM.phase := CM.requested ? "messages" : "keys"
        ControllerMessageFlush()
        return true
    }
    if (!CM.requested)
        return false
    if (CM.phase = "backpressure") {
        if (neutral and !CM.pending.Length())
            CM.phase := "messages"
        ControllerMessageFlush()
        return true
    }
    if (CM.pending.Length() > 96 or (CM.pending.Length() and now - CM.pending[1].tick > 350)) {
        ControllerMessageCancel()
        CM.phase := "backpressure"
        return true
    }
    changed := false
    Loop, 12 {
        i := A_Index
        if (CM.previous[i] and !states[i]) {
            ControllerMessageAdd("up", i)
            CM.previous[i] := false, changed := true
        }
    }
    for _, i in [11, 12, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8] {
        if (states[i] and !CM.previous[i]) {
            ControllerMessageAdd("down", i)
            CM.previous[i] := true, changed := true
        }
    }
    ControllerMessageFlush(changed)
    return true
}
