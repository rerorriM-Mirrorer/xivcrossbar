#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cstddef>
#include <cstring>

// A minimal Lua 5.1 export surface for the native module registration test.
using LuaFunction = int (__cdecl*)(void*);
struct State {
    std::ptrdiff_t value{};
    std::ptrdiff_t process_id{};
    std::ptrdiff_t shoulder_slots{}, trust_menu{}, reverse_tab{};
    LuaFunction function{};
    LuaFunction tap_tab{}, begin{};
    const char* detail{};
    unsigned callbacks{};
    bool table{};
};

extern "C" {
__declspec(dllexport) std::ptrdiff_t __cdecl lua_tointeger(State*, int) { return 0; }
__declspec(dllexport) const char* __cdecl lua_tolstring(State*, int, size_t*) { return nullptr; }
__declspec(dllexport) void __cdecl lua_pushinteger(State* state, std::ptrdiff_t value) { state->value = value; }
__declspec(dllexport) void __cdecl lua_pushstring(State* state, const char* value) { state->detail = value; }
__declspec(dllexport) void __cdecl lua_createtable(State* state, int, int) { state->table = true; }
__declspec(dllexport) void __cdecl lua_pushcclosure(State* state, LuaFunction fn, int) { state->function = fn; }
__declspec(dllexport) void __cdecl lua_setfield(State* state, int, const char* name) {
    if (strcmp(name, "process_id") == 0) state->process_id = state->value;
    else if (strcmp(name, "shoulder_slots") == 0) state->shoulder_slots = state->value;
    else if (strcmp(name, "reverse_tab") == 0) state->reverse_tab = state->value;
    else if (strcmp(name, "trust_menu") == 0) state->trust_menu = state->value;
    else if (state->function) {
        if (strcmp(name, "tap_tab") == 0) state->tap_tab = state->function;
        if (strcmp(name, "begin") == 0) state->begin = state->function;
        ++state->callbacks;
    }
    state->function = nullptr;
}
__declspec(dllexport) void __cdecl lua_rawseti(State*, int, int) {}

__declspec(dllexport) bool __cdecl verify_messages_module(LuaFunction open) {
    State state;
    return open(&state) == 1 && state.table && state.callbacks == 7 && state.tap_tab && state.shoulder_slots == 1 && state.trust_menu == 1 && state.reverse_tab == 1 &&
        state.process_id == GetCurrentProcessId() && state.begin && state.begin(&state) == 3 &&
        state.detail && strcmp(state.detail, "Validate native hook arguments") == 0 &&
        state.value == ERROR_INVALID_PARAMETER;
}
}
