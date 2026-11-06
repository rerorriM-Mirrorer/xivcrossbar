#pragma once
#include <cstdint>

namespace xb {
constexpr unsigned up = 1, circle = 0x40, slots = 0xff, triggers = 0xc00;
constexpr unsigned controls = slots | triggers;
constexpr unsigned default_passthrough = up | circle;

struct Sample {
    unsigned suppressed;
    unsigned down;
    unsigned up;

    // Buffered releases belong to the same owner as their press.
    unsigned buffered_mask() const { return suppressed | up; }
};

class Ownership {
    unsigned previous_ = 0;
    unsigned owned_ = 0;
    bool armed_ = false;
public:
    void reset() { previous_ = owned_ = 0; armed_ = false; }

    // mode 1 is the isolated Up and Circle probe. Mode 2 routes the normal crossbar.
    Sample apply(unsigned raw, unsigned mode, bool menu, bool native_menu, unsigned passthrough = 0) {
        if (!armed_) {
            armed_ = !(raw & controls);
            return {};
        }
        const unsigned down = raw & ~previous_;
        const unsigned released = owned_ & ~raw;
        previous_ = raw;
        owned_ &= raw;
        unsigned capture = mode == 1 ? (up | circle) : 0;
        if (mode == 2 && !native_menu) {
            capture = triggers;
            if (menu || (owned_ & triggers) || (down & triggers))
                capture |= slots & ~passthrough;
        }
        const unsigned acquired = down & capture;
        owned_ |= acquired;
        return {owned_, acquired, released};
    }
};
}
