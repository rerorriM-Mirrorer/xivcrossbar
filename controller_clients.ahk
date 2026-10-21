; A: the mutex prevents duplicates; this registry decides whether anyone still
; needs the shared wrapper. No heartbeat expiry: minimized clients count too.
WrapperClientsInit() {
    global WC
    WC := {seen:false, tokens:{}, retired:{}, lastPoll:0, emptySince:0, lastClose:0, kill:false}
}

WrapperClientsShouldExit() {
    global WC
    if (A_TickCount - WC.lastPoll < 250)
        return false
    WC.lastPoll := A_TickCount
    scanStarted := DllCall("GetTickCount64", "UInt64")
    loaded := 0
    latestClose := 0
    latestKill := false
    pattern := A_ScriptDir . "\data\controller-clients\*.ini"
    Loop, Files, %pattern%, F
    {
        path := A_LoopFileFullPath
        ; Each owner token is a unique Lua session. Once its owner is closed,
        ; that session cannot return; new loads publish a new filename/token.
        if (WC.retired.HasKey(path)) {
            record := WC.retired[path]
            alive := false
        } else {
            readStarted := DllCall("GetTickCount64", "UInt64")
            FileRead, contents, %path%
            readFailed := ErrorLevel
            InputTimingOperation("client-record-read", readStarted)
            record := readFailed ? false : WrapperClientRecord(contents)
            ownerStarted := DllCall("GetTickCount64", "UInt64")
            alive := WrapperOwnerAlive(path . ".owner")
            InputTimingOperation("client-owner-check", ownerStarted)
            if (!IsObject(record)) {
                ; An uncertain live owner must not make the wrapper exit.
                if (alive) {
                    loaded++
                    WC.seen := true
                }
                continue
            }
            if (!alive)
                WC.retired[path] := record
        }
        id := record.id, state := record.state, kill := record.kill, closed := record.closed
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
    InputTimingOperation("client-registry-scan", scanStarted)
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

; A: one complete snapshot replaces five synchronous Windows INI reads.
; Lua writes this exact private format atomically. Unrelated files are ignored.
WrapperClientRecord(contents) {
    if (!RegExMatch(contents, "smi)^\[Client\]\r?\n(.*?)(?=^\[|\z)", section))
        return false
    if (!RegExMatch(section1, "im)^protocol=([^\r\n]+)\r?$", protocol) or protocol1 != "owner-file-v1")
        return false
    if (!RegExMatch(section1, "im)^id=([A-Za-z0-9-]+)\r?$", id)
        or !RegExMatch(section1, "im)^state=(loaded|closing)\r?$", state)
        or !RegExMatch(section1, "im)^kill=(true|false)\r?$", kill)
        or !RegExMatch(section1, "im)^closed=([0-9]+(?:\.[0-9]+)?)\r?$", closed))
        return false
    return {id:id1, state:state1, kill:kill1, closed:closed1 + 0}
}
