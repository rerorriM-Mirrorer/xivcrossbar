#pragma once
#include <cstdint>

#include "controller_mappings.hpp"

namespace xb {
inline unsigned xbox_button(unsigned i, bool r1_chooser) {
    return i == 9 && r1_chooser ? xbox_alternate_chooser : xbox[i];
}

inline unsigned read_xbox(unsigned buttons, unsigned left, unsigned right, bool r1_chooser = false) {
    unsigned raw = (left > xbox_trigger_threshold ? 0x400 : 0) | (right > xbox_trigger_threshold ? 0x800 : 0);
    for (unsigned i = 0; i < 10; ++i)
        if (buttons & xbox_button(i, r1_chooser)) raw |= 1u << i;
    return raw;
}
inline unsigned read_joystick(unsigned pov, const std::uint8_t* buttons, bool fight) {
    unsigned raw = 0;
    if (pov < 36000 && pov % 4500 == 0) {
        raw = 1u << (pov / 9000);
        if (pov % 9000) raw |= 1u << ((pov / 9000 + 1) % 4);
    }
    const auto* map = fight ? fightpad : dualsense;
    for (unsigned i = 0; i < 8; ++i)
        if (buttons[map[i]] & 0x80) raw |= 1u << logical_buttons[i];
    return raw;
}
// Extended profiles retain the personal shoulder, stick-click and PS gestures.
constexpr unsigned personal_di[] = {4, 5, 10, 11, 12, 13, 14};
constexpr unsigned personal_xi[] = {0x0100, 0x0200, 0x0040, 0x0080, 0, 0x0400, 0};
inline unsigned joystick_button_bit(unsigned instance, bool fight, bool personal) {
    const auto* map = fight ? fightpad : dualsense;
    for (unsigned i = 0; i < 8; ++i)
        if (instance == map[i]) return 1u << logical_buttons[i];
    if (personal)
        for (unsigned i = 0; i < 7; ++i)
            if (instance == personal_di[i]) return 1u << (12 + i);
    return 0;
}
inline unsigned read_personal_joystick(const std::uint8_t* buttons) {
    unsigned raw = 0;
    for (unsigned i = 0; i < 7; ++i)
        if (buttons[personal_di[i]] & 0x80) raw |= 1u << (12 + i);
    return raw;
}
inline unsigned filter_hat(unsigned pov, unsigned suppressed) {
    if (pov >= 36000 || pov % 4500 != 0) return pov;
    const unsigned first = pov / 9000;
    const unsigned second = (first + 1) % 4;
    if (!(suppressed & (1u << first)))
        return (pov % 9000 && (suppressed & (1u << second))) ? first * 9000 : pov;
    if (pov % 9000 && !(suppressed & (1u << second))) return second * 9000;
    return 0xffffffffu;
}
inline void filter_joystick(std::uint8_t* buttons, unsigned suppressed, bool fight) {
    const auto* map = fight ? fightpad : dualsense;
    for (unsigned i = 0; i < 8; ++i)
        if (suppressed & (1u << logical_buttons[i])) buttons[map[i]] &= 0x7f;
}
}
