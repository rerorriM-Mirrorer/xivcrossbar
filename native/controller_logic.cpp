#include "controller_logic.hpp"

namespace {
#ifdef XB_SHOULDER_GESTURES
constexpr bool shoulder_gestures = true;
#else
constexpr bool shoulder_gestures = false;
#endif
}

extern "C" __declspec(dllexport) void __cdecl xb_logic_v1_apply(
    xb::Ownership* state, const xb::LogicInput* input, xb::Sample* output) {
    *output = state->apply(input->raw, input->mode, input->menu != 0, input->native_menu != 0,
        0, input->now, input->targeting != 0, input->banks & 7, input->binding != 0,
        input->trust_slots, shoulder_gestures, (input->banks & 8) != 0, (input->banks & 16) != 0);
}
