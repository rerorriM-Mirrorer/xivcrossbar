; A: gesture decisions contain no keyboard/Windows calls. The wrapper applies
; their results only to the current FFXI owner, and cancels them on context loss.
PersonalShoulderStep(g, pressed, previous, consumed) {
    if (consumed) {
        g.phase := pressed ? "cancelled" : "idle"
        return ""
    }
    if (pressed and !previous)
        g.phase := "single"
    if (!pressed and previous) {
        phase := g.phase, g.phase := "idle"
        return phase = "single" ? g.key : ""
    }
    return ""
}

PersonalTouchStep(g, pressed, previous, consumed, now) {
    if (consumed) {
        g.phase := pressed ? "cancelled" : "idle"
        return ""
    }
    if (pressed and !previous)
        g.phase := "timing", g.started := now
    if (pressed and g.phase = "timing" and now - g.started >= 500) {
        g.phase := "fired"
        return "vkC0sc029"
    }
    if (!pressed and previous) {
        phase := g.phase, g.phase := "idle"
        if (phase = "timing")
            return "vkC0sc029"
        if (phase = "fired")
            return "Escape"
    }
    return ""
}

PersonalModifierStep(g, l1, l2, r1, r2, allowed) {
    if (!allowed) {
        g.ctrl := false, g.alt := false
        return ""
    }
    if (!l1 and !l2)
        g.ctrl := false
    else if (l1 and l2)
        g.ctrl := true
    if (!r1 and !r2)
        g.alt := false
    else if (r1 and r2)
        g.alt := true
    if (g.ctrl and g.alt)
        return "both"
    return g.ctrl ? "ctrl" : (g.alt ? "alt" : "")
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


PersonalPovDirection(pov, previous) {
    if (pov = 0)
        return 1
    if (pov = 9000)
        return 2
    if (pov = 18000)
        return 3
    if (pov = 27000)
        return 4
    if (pov = 4500)
        return previous = 2 ? 2 : 1
    if (pov = 13500)
        return previous = 3 ? 3 : 2
    if (pov = 22500)
        return previous = 4 ? 4 : 3
    if (pov = 31500)
        return previous = 1 ? 1 : 4
    return 0
}
