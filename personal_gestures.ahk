; A: gesture decisions contain no keyboard/Windows calls. The wrapper applies
; their results only to the current FFXI owner, and cancels them on context loss.
PersonalShoulderStep(g, pressed, previous, consumed, now, interval) {
    if (consumed) {
        g.pending := 0, g.phase := pressed ? "cancelled" : "idle"
        return ""
    }
    event := ""
    ; A: the first completed tap already targeted. The remaining window
    ; recognizes a second tap without delaying the first key.
    if (g.pending and now > g.pending)
        g.pending := 0
    if (pressed and !previous) {
        g.phase := g.pending ? "double" : "single"
        g.pending := 0, g.started := now
    }
    if (pressed and g.phase = "double" and now - g.started > interval)
        g.phase := "cancelled"
    if (!pressed and previous) {
        if (g.phase = "double")
            event := "switch"
        else if (g.phase = "single") {
            event := g.key
            g.pending := now + interval
        }
        g.phase := "idle"
    }
    if (!pressed and g.phase = "cancelled")
        g.phase := "idle"
    return event
}

PersonalTouchStep(g, pressed, previous, l1, consumed, now) {
    if (consumed) {
        g.phase := pressed ? "cancelled" : "idle"
        return ""
    }
    if (pressed and !previous) {
        g.phase := "timing", g.started := now, g.withL1 := l1
        ; A: the short shortcut responds on down. A later hold additionally
        ; emits F15; it cannot retract the Tab already delivered to the game.
        if (l1)
            return "Tab"
    }
    ; A shoulder changing while touchpad remains held cannot change the action.
    ; Releasing both together still permits the short L1+touchpad tap.
    if (pressed and g.phase = "timing" and l1 != g.withL1)
        g.phase := "cancelled"
    if (pressed and g.phase = "timing" and now - g.started >= 500) {
        g.phase := "fired"
        return g.withL1 ? "F15" : "vkC0sc029"
    }
    if (!pressed and previous) {
        phase := g.phase, g.phase := "idle"
        if (phase = "timing")
            return g.withL1 ? "" : "vkC0sc029"
        if (phase = "fired" and !g.withL1)
            return "Escape"
    }
    return ""
}

PersonalClicksStep(g, l3, r3, previousL3, previousR3, consumed) {
    if (consumed) {
        g.phase := l3 or r3 ? "cancelled" : "idle"
        return ""
    }
    phase := g.phase
    if (phase = "idle") {
        ; Simultaneous samples establish no order, so produce no guessed chord.
        if (l3 and r3)
            g.phase := "cancelled"
        else if (l3 and !previousL3)
            g.phase := "l3"
        else if (r3 and !previousR3)
            g.phase := "r3"
    } else if (phase = "l3" and l3 and r3 and !previousR3) {
        g.phase := "period"
    } else if (phase = "r3" and r3 and l3 and !previousL3) {
        g.phase := "comma"
    }
    ; A: the second click owns the held zoom key. Releasing the first click
    ; does not interrupt it; once the second releases, both must return neutral.
    if (g.phase = "comma" and l3)
        return "vkBCsc033"
    if (g.phase = "period" and r3)
        return "vkBEsc034"
    if (g.phase = "comma" or g.phase = "period")
        g.phase := "cancelled"
    if (!l3 and !r3) {
        g.phase := "idle"
        if (phase = "l3")
            return "h"
        if (phase = "r3")
            return "r"
    }
    ; Releasing the first click while the other remains held cancels the pair.
    if ((phase = "l3" and !l3 and r3) or (phase = "r3" and !r3 and l3))
        g.phase := "cancelled"
    return ""
}

PersonalAltStep(g, r1, right, left) {
    ; A: once horizontal input used Alt, keep the latch until R1 releases.
    ; Direct shortcuts may suspend the physical modifier without clearing it.
    if (!r1)
        g.altLatched := false
    else if (right or left)
        g.altLatched := true
    return g.altLatched
}

PersonalSwitchStep(pending, active, allowed, neutral, now) {
    if (active != pending.owner or !allowed or !neutral)
        return "cancel"
    return now >= pending.due ? "switch" : "wait"
}

PersonalAltOutput(latched, allowed, l1, pulseBusy, newTap) {
    return latched and allowed and !l1 and !pulseBusy and !newTap
}
