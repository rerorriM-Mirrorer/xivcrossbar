#pragma once
#include <cstdint>

#include "controller_mappings.hpp"

namespace xb {
constexpr unsigned extra_buttons = 0x7c000, right_directions = 0x780000;
constexpr unsigned extra_controls = extra_buttons | right_directions;
inline unsigned read_right(double x, double y) {
    return (y < -.55 ? 1u<<19 : 0) | (x > .55 ? 1u<<20 : 0) |
        (y > .55 ? 1u<<21 : 0) | (x < -.55 ? 1u<<22 : 0);
}
inline unsigned read_extra_buttons(const std::uint8_t* buttons, bool fight) {
    if (fight) return 0; // No inferred extra-button layout for fightpads.
    unsigned raw=0;
    for (unsigned i=0;i<5;++i) if (buttons[10+i]&0x80) raw|=1u<<(14+i);
    return raw;
}
inline void filter_extra_buttons(std::uint8_t* buttons,unsigned mask,bool fight) {
    if (!fight) for (unsigned i=0;i<5;++i) if (mask&(1u<<(14+i))) buttons[10+i]&=0x7f;
}

inline unsigned xbox_button(unsigned i, bool r1_chooser) {
    if (i >= 12) return i == 13 && r1_chooser ? 0 : xbox_shoulders[i - 12];
    return i == 9 && r1_chooser ? xbox_alternate_chooser : xbox[i];
}

inline unsigned read_xbox(unsigned buttons, unsigned left, unsigned right, bool r1_chooser = false) {
    unsigned raw = (left > xbox_trigger_threshold ? 0x400 : 0) | (right > xbox_trigger_threshold ? 0x800 : 0);
    for (unsigned i = 0; i < 10; ++i)
        if (buttons & xbox_button(i, r1_chooser)) raw |= 1u << i;
    for (unsigned i = 12; i < 14; ++i)
        if (buttons & xbox_button(i, r1_chooser)) raw |= 1u << i;
    if (buttons & 0x40) raw |= 1u<<14;
    if (buttons & 0x80) raw |= 1u<<15;
    return raw;
}
inline unsigned read_joystick(unsigned pov, const std::uint8_t* buttons, bool fight) {
    unsigned raw = 0;
    if (pov < 36000 && pov % 4500 == 0) {
        raw = 1u << (pov / 9000);
        if (pov % 9000) raw |= 1u << ((pov / 9000 + 1) % 4);
    }
    const auto* map = fight ? fightpad : dualsense;
    for (unsigned i = 0; i < sizeof(logical_buttons) / sizeof(*logical_buttons); ++i)
        if (buttons[map[i]] & 0x80) raw |= 1u << logical_buttons[i];
    return raw | read_extra_buttons(buttons,fight);
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
    for (unsigned i = 0; i < sizeof(logical_buttons) / sizeof(*logical_buttons); ++i)
        if (suppressed & (1u << logical_buttons[i])) buttons[map[i]] &= 0x7f;
}
}
