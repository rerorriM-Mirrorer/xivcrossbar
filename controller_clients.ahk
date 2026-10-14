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
        IniRead, pid, %path%, Client, pid, 0
        IniRead, token, %path%, Client, token, missing
        IniRead, state, %path%, Client, state, missing
        IniRead, kill, %path%, Client, kill, false
        IniRead, closed, %path%, Client, closed, 0
        actual := WrapperProcessToken(pid)
        if (actual = token and state = "loaded") {
            loaded++
            WC.seen := true
            WC.tokens[pid] := {token:token, kill:kill = "true"}
        } else if (actual = token and state = "closing") {
            if (closed + 0 >= latestClose) {
                latestClose := closed + 0
                latestKill := kill = "true"
            }
        } else if (actual = "" and WC.tokens.HasKey(pid) and WC.tokens[pid].token = token) {
            ; A client process ended without an observable unload callback.
            Process, Exist, %pid%
            if (ErrorLevel) {
                loaded++ ; inability to query a still-live client is not an unload
            } else {
                known := WC.tokens[pid]
                if (!known.deadAt)
                    known.deadAt := DllCall("GetTickCount64", "Int64") / 1000
                if (known.deadAt >= latestClose) {
                    latestClose := known.deadAt
                    latestKill := known.kill
                }
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

WrapperProcessToken(pid) {
    if (!pid or pid < 1)
        return ""
    handle := DllCall("OpenProcess", "UInt", 0x1000, "Int", 0, "UInt", pid, "Ptr")
    if (!handle)
        return ""
    VarSetCapacity(created, 8, 0)
    VarSetCapacity(exited, 8, 0)
    VarSetCapacity(kernel, 8, 0)
    VarSetCapacity(user, 8, 0)
    ok := DllCall("GetProcessTimes", "Ptr", handle, "Ptr", &created, "Ptr", &exited, "Ptr", &kernel, "Ptr", &user, "Int")
    DllCall("CloseHandle", "Ptr", handle)
    return ok ? NumGet(created, 4, "UInt") . ":" . NumGet(created, 0, "UInt") : ""
}
