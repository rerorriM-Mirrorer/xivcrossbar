; Same profile/mapping for every slot of that profile's backend. No cross-API
; polling and no mapping inference. Publish one logical stream to existing routing.
ReadProfileSlots(readSlot, maximum, scan, logChange := LogProfileSlots) {
    combined := []
    Loop 23
        combined.Push(false)
    combined.ps := false
    found := false, connected := "", active := "", signature := ""
    Loop maximum {
        slot := A_Index
        sample := readSlot(slot)
        if (!IsObject(sample)) {
            if scan.armed.Has(slot)
                scan.armed.Delete(slot)
            continue
        }
        found := true
        connected .= (connected = "" ? "" : ",") . slot
        mask := 0
        Loop 23 {
            if (sample.Length >= A_Index && sample[A_Index])
                mask |= 1 << (A_Index - 1)
        }
        ps := sample.HasOwnProp("ps") && sample.ps
        if (!scan.armed.Has(slot))
            scan.armed[slot] := false
        if (!mask && !ps)
            scan.armed[slot] := true
        signature .= slot . ":" . (scan.armed[slot] ? mask : "waiting-neutral") . ":" . ps . ";"
        if (!scan.armed[slot])
            continue
        if (mask || ps)
            active .= (active = "" ? "" : ",") . slot
        Loop 23
            combined[A_Index] := combined[A_Index] || (sample.Length >= A_Index && sample[A_Index])
        if (ps)
            combined.ps := true
        ; Preserve a real source's stick vector, never add multiple axes together.
        if (sample.HasOwnProp("moveX") && sample.HasOwnProp("moveY")) {
            strength := sample.moveX ** 2 + sample.moveY ** 2
            previous := combined.HasOwnProp("moveX") ? combined.moveX ** 2 + combined.moveY ** 2 : -1
            if (strength > previous)
                combined.moveX := sample.moveX, combined.moveY := sample.moveY
        }
    }
    scan.connected := connected, scan.active := active
    if (signature != scan.signature) {
        scan.signature := signature
        logChange(connected, active, signature)
    }
    return found ? combined : false
}
LogProfileSlots(connected, active, signature) {
    global profile
    path := A_ScriptDir . "\data\controller-all-slots.log"
    try {
        if (FileExist(path) && FileGetSize(path) > 2097152)
            FileDelete(path)
        FileAppend(FormatTime(A_NowUTC, "yyyy-MM-dd HH:mm:ss") . " UTC | " . profile
            . " | pid=" . DllCall("GetCurrentProcessId", "UInt") . " | script=" . A_ScriptName
            . " | connected=" . connected . " | active=" . active . " | " . signature . "`n", path, "UTF-8-RAW")
    } catch Error as slotLogError {
        ; Diagnostics must not interrupt controller routing.
    }
}
