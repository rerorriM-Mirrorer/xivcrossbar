; A: the mutex prevents duplicates; this registry decides whether anyone still
; needs the shared wrapper. No heartbeat expiry: minimized clients count too.
WrapperClientsInit() {
    global WC
    WC := {seen:false, tokens:{}, lastPoll:0, emptySince:0, lastClose:0, kill:false}
}

WrapperClientsShouldExit() {
    global WC
    if (A_TickCount - WC.lastPoll < 250)
        return false
    WC.lastPoll := A_TickCount
    loaded := 0
    latestClose := 0
    latestKill := false
    pattern := A_ScriptDir . "\data\controller-clients\*.ini"
    Loop, Files, %pattern%, F
    {
        path := A_LoopFileFullPath
        IniRead, protocol, %path%, Client, protocol, missing
        if (protocol != "owner-file-v1")
            continue ; old registrations do not use this ownership protocol
        IniRead, id, %path%, Client, id, missing
        IniRead, state, %path%, Client, state, missing
        IniRead, kill, %path%, Client, kill, false
        IniRead, closed, %path%, Client, closed, 0
        alive := WrapperOwnerAlive(path . ".owner")
        if (alive) {
            loaded++
            WC.seen := true
            WC.tokens[id] := {kill:kill = "true"}
        } else if (state = "closing") {
            if (closed + 0 >= latestClose) {
                latestClose := closed + 0
                latestKill := kill = "true"
            }
        } else if (WC.tokens.HasKey(id)) {
            ; Owner handles also close when a game/Lua process terminates.
            known := WC.tokens[id]
            if (!known.deadAt)
                known.deadAt := WrapperClientsClock()
            if (known.deadAt >= latestClose) {
                latestClose := known.deadAt
                latestKill := known.kill
            }
        }
    }
    return WrapperClientsDecision(WC, loaded, latestClose, latestKill, A_TickCount)
}

; A: testable lifecycle policy; native enumeration above supplies observations.
WrapperClientsDecision(state, loaded, latestClose, latestKill, now) {
    if (loaded) {
        state.emptySince := 0
        state.lastClose := 0
        return false
    }
    if (!state.seen)
        return false
    if (!state.emptySince or state.lastClose != latestClose) {
        state.emptySince := now
        state.lastClose := latestClose
    }
    return latestKill and now - state.emptySince >= 2000
}

WrapperOwnerAlive(path) {
    ; A live Lua session holds a read handle; an exclusive open fails with 32.
    ; Access/query failures are treated as live, so uncertainty never kills it.
    handle := DllCall("CreateFileW", "WStr", path, "UInt", 0x80000000, "UInt", 0, "Ptr", 0, "UInt", 3, "UInt", 128, "Ptr", 0, "Ptr")
    if (handle = -1 or handle = 0xFFFFFFFF) {
        code := A_LastError
        return code != 2 and code != 3
    }
    DllCall("CloseHandle", "Ptr", handle)
    return false
}

WrapperClientsClock() {
    stamp := A_NowUTC
    EnvSub, stamp, 19700101000000, Seconds
    return stamp + A_MSec / 1000
}
