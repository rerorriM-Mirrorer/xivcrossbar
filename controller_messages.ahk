; Ordered messages for every controller profile. A missing lease emits no input.
ControllerMessageInit() {
    global CM
    CM := {requested:false, token:"", ack:0, seq:0, count:12, pending:[], previous:NeutralButtons()
        , phase:"waiting-lease", seen:0, path:"", nextWrite:0, error:false}
}
ControllerMessageContext(hwnd) {
    global CM, profile, device
    try {
        pid := WinGetPID("ahk_id " . hwnd)
        path := A_ScriptDir . "\data\directlink\" . pid . ".ini"
        lease := FileRead(path)
    } catch Error {
        return
    }
    ; Device remains a compatibility field; all-profile-slot routing owns the
    ; mapping, while the native guard tracks its attachment separately.
    if (!RegExMatch(lease, "m)^timestamp=(\d+)\r?$", &stamp)
        or !RegExMatch(lease, "m)^profile=([a-z0-9-]+)\r?$", &selected)
        or selected[1] != profile
        or !RegExMatch(lease, "m)^device=(\d+)\r?$", &number)
        or !RegExMatch(lease, "m)^button_mode=messages\r?$")
        or !RegExMatch(lease, "m)^button_token=([A-Za-z0-9-]+)\r?$", &token)
        or !RegExMatch(lease, "m)^button_ack=(\d+)\r?$", &ack)
        or !RegExMatch(lease, "m)^END\r?$"))
        return
    now := DateDiff(A_NowUTC, "19700101000000", "Seconds")
    age := now - stamp[1]
    if (age < -1 or age > 2)
        return
    BridgeLease(lease)
    count := RegExMatch(lease, "m)^button_count=14\r?$") ? 14 : 12
    ControllerMessageSelect(true, token[1], ack[1] + 0, RegExReplace(path, "\.ini$", ".buttons"), count)
}
ControllerMessageSelect(requested, token, ack, path, count := 12) {
    global CM
    if (requested != CM.requested or token != CM.token or path != CM.path or count != CM.count) {
        ReleaseTransport()
        CM.requested := requested, CM.token := token, CM.seq := ack, CM.ack := ack, CM.count := count
        CM.pending := [], CM.previous := NeutralButtons(), CM.phase := "neutral"
        CM.nextWrite := 0, CM.path := path
        if (requested) {
            ControllerMessageAdd("cancel", 0)
            ControllerMessageFlush(true)
        }
    }
    CM.seen := A_TickCount
    ; A brief lease publication gap must never permanently freeze this token.
    ; Rejoin only after a neutral gesture and tell Lua to cancel old ownership.
    if (requested and CM.phase = "uncertain") {
        CM.previous := NeutralButtons()
        CM.phase := "neutral"
        ControllerMessageAdd("cancel", 0)
        ControllerMessageFlush(true)
    }
    if (requested) {
        CM.ack := ack
        retained := []
        for _, event in CM.pending
            if (event.seq > ack)
                retained.Push(event)
        CM.pending := retained
    }
}
ControllerMessageAdd(kind, button, chord := false) {
    global CM
    CM.seq += 1
    CM.pending.Push({seq:CM.seq, kind:kind, button:button, chord:chord, tick:A_TickCount})
    DiagRecord("DirectLink seq=" . CM.seq . " " . kind . " button=" . button . " ack=" . CM.ack)
}
ControllerMessageCancel() {
    global CM
    if (!IsObject(CM) or !CM.requested)
        return
    if (CM.phase = "messages" or CM.phase = "backpressure") {
        ControllerMessageAdd("cancel", 0)
        ControllerMessageFlush(true)
    }
    CM.previous := NeutralButtons(), CM.phase := "neutral"
}
ControllerMessageFlush(force := false) {
    global CM
    if (!CM.requested or CM.token = "" or CM.path = "")
        return false
    if (!force and A_TickCount < CM.nextWrite)
        return true
    CM.nextWrite := A_TickCount + 100
    stamp := DateDiff(A_NowUTC, "19700101000000", "Seconds")
    contents := "token=" . CM.token . "`nstamp=" . stamp . "`nbeat=" . A_TickCount . "`n"
    if (CM.count = 14)
        contents .= "buttons=14`n"
    for _, event in CM.pending
        contents .= event.seq . "," . event.kind . "," . event.button . (event.chord ? ",1" : "") . "`n"
    contents .= "END`n"
    temporary := CM.path . ".tmp"
    CM.error := !WriteControllerFile(temporary, CM.path, contents)
    return !CM.error
}
ControllerMessagePoll(states, hwnd) {
    global CM
    if (hwnd)
        ControllerMessageContext(hwnd)
    if (!CM.requested)
        return false
    neutral := true
    Loop CM.count
        if (states[A_Index])
            neutral := false
    now := A_TickCount
    if (CM.requested and (CM.phase = "uncertain" or now - CM.seen > 350)) {
        if (CM.phase = "messages")
            ControllerMessageCancel()
        CM.phase := "uncertain"
        DiagRecord("DirectLink uncertain lease_age_ms=" . (now-CM.seen))
        if (neutral and now - CM.seen > 2500) {
            CM.requested := false, CM.token := "", CM.phase := "waiting-lease"
        }
        return true
    }
    if (CM.phase = "neutral") {
        if (neutral)
            CM.phase := "messages"
        ControllerMessageFlush()
        return true
    }
    if (CM.phase = "backpressure") {
        if (neutral and !CM.pending.Length)
            CM.phase := "messages"
        ControllerMessageFlush()
        return true
    }
    if (CM.pending.Length > 96 or (CM.pending.Length and now - CM.pending[1].tick > 350)) {
        ControllerMessageCancel()
        CM.phase := "backpressure"
        DiagRecord("DirectLink backpressure pending=" . CM.pending.Length)
        return true
    }
    changed := false
    Loop CM.count {
        i := A_Index
        if (CM.previous[i] and !states[i]) {
            ControllerMessageAdd("up", i)
            CM.previous[i] := false, changed := true
        }
    }
    for _, i in [11, 12, 9, 10, 13, 14, 1, 2, 3, 4, 5, 6, 7, 8] {
        if (i <= CM.count and states[i] and !CM.previous[i]) {
            chord := i >= 13 && states[13] && states[14]
            ControllerMessageAdd("down", i, chord)
            CM.previous[i] := true, changed := true
        }
    }
    ControllerMessageFlush(changed)
    return true
}

NeutralButtons() {
    buttons := []
    Loop 14
        buttons.Push(false)
    return buttons
}
