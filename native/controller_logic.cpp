#include "controller_logic.hpp"

extern "C" __declspec(dllexport) void __cdecl xb_logic_v1_apply(
    xb::Ownership* state, const xb::LogicInput* input, xb::Sample* output) {
    *output = state->apply(input->raw, input->mode, input->menu != 0, input->native_menu != 0,
        0, input->now, input->targeting != 0, input->banks, input->binding != 0, input->trust_slots);
}
