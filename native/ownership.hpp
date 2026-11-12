#pragma once
#include <cstdint>

namespace xb {
constexpr unsigned up = 1, circle = 0x40, slots = 0xff, triggers = 0xc00;
constexpr unsigned directions = 0xf, direction_resume_ms = 120;
constexpr unsigned share = 0x100, chooser = 0x200;
constexpr unsigned l1 = 0x1000, r1 = 0x2000;
constexpr unsigned controls = slots | triggers | share | chooser;
constexpr unsigned default_passthrough = up | circle;

struct Sample {
    unsigned suppressed;
    unsigned down;
    unsigned up;

    // Buffered releases belong to the same owner as their press.
    unsigned buffered_mask() const { return suppressed | up; }
};

// Covers the brief foreground-to-Lua-heartbeat gap without replaying old input.
class FocusHandoff {
    bool active_=false;
    unsigned blocked_=0;
public:
    void reset() { active_=false;blocked_=0; }
    unsigned blocked() const { return blocked_; }
    unsigned sample(unsigned raw,bool foreground,bool enabled,bool joining) {
        if (!foreground || !enabled) { reset();return 0; }
        if (!active_ && (raw & (triggers | l1 | r1))) blocked_=raw & (controls | l1 | r1);
        active_=true;blocked_ &= raw;
        if (joining && (blocked_ & (triggers | l1 | r1))) blocked_ |= raw & controls;
        return blocked_;
    }
};

class Ownership {
    std::uint64_t direction_resume_at_ = 0;
    std::uint32_t previous_ = 0;
    std::uint32_t owned_ = 0;
    std::uint32_t shoulder_directions_ = 0;
    std::uint32_t armed_ = 0;
public:
    void reset() { previous_ = owned_ = shoulder_directions_ = 0; armed_ = false; direction_resume_at_ = 0; }

    // mode 1 is the isolated Up and Circle probe. Mode 2 routes the normal crossbar.
    Sample apply(unsigned raw, unsigned mode, bool menu, bool native_menu, unsigned passthrough = 0,
        std::uint64_t now = 0, bool targeting = false, unsigned banks = 0, bool binding = false, unsigned trust_slots = 0,
        bool shoulder_gestures = false, bool inherit = false, bool set_controls = false) {
        if (!armed_) {
            if (inherit && mode==2 && !menu && (raw & (triggers | l1 | r1))) {
                // Adopt modifiers without a press gesture. Quarantine every
                // preheld action until release, including during reader join.
                armed_=true;previous_=raw;owned_=raw & (controls | l1 | r1);
                shoulder_directions_=raw & directions;
                return {owned_,0,0};
            }
            armed_ = !(raw & controls);
            previous_ = raw;
            return {};
        }
        const unsigned down = raw & ~previous_;
        const unsigned released = owned_ & ~raw;
        previous_ = raw;
        owned_ &= raw;
        shoulder_directions_ &= raw;
        unsigned capture = mode == 1 ? (up | circle) : 0;
        if (mode == 2 && trust_slots) {
            capture = trust_slots & slots;
            shoulder_directions_ |= down & capture & directions;
        } else if (mode == 2 && !native_menu) {
            const unsigned shoulders = raw & (l1 | r1);
            const unsigned bank = shoulders == (l1 | r1) ? 4 : shoulders == r1 ? 2 : shoulders == l1 ? 1 : 0;
            const bool bank_owns = !menu && (banks & bank) && !(raw & (triggers | share | chooser));

            capture = triggers | share | chooser;
            if (set_controls && !menu) {
                if ((raw & triggers)==0x400) capture |= l1;
                if ((raw & triggers)==0x800) capture |= r1;
            }
            if (binding && menu) capture |= l1 | r1;
            if (bank_owns) {
                capture |= shoulders | slots;
                shoulder_directions_ |= down & directions;
            }
            if (targeting && !menu && !(raw & (triggers | share | chooser))) {
                if (shoulder_gestures) capture |= l1 | r1;
                else if (!(raw & l1)) capture |= r1;
            }
            if (menu || ((owned_ | down) & (triggers | share | chooser)))
                capture |= slots & ~passthrough;
        }
        const unsigned acquired = down & capture;
        owned_ |= acquired;
        if (now && mode == 2) {
            if (menu || (owned_ & (triggers | l1 | r1))) direction_resume_at_ = 0;
            else if (released & triggers) direction_resume_at_ = now + direction_resume_ms;
            if (direction_resume_at_ && now >= direction_resume_at_) {
                owned_ &= ~(directions & ~shoulder_directions_);
                direction_resume_at_ = 0;
            }
        }
        return {owned_, acquired, released};
    }
};
}
