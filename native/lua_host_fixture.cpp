#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cstddef>
#include <cstring>

// A minimal Lua 5.1 export surface for the native module registration test.
using LuaFunction = int (__cdecl*)(void*);
struct State {
    std::ptrdiff_t value{};
    std::ptrdiff_t process_id{};
    LuaFunction function{};
    LuaFunction tap_tab{};
    unsigned callbacks{};
    bool table{};
};

extern "C" {
__declspec(dllexport) std::ptrdiff_t __cdecl lua_tointeger(State*, int) { return 0; }
__declspec(dllexport) const char* __cdecl lua_tolstring(State*, int, size_t*) { return nullptr; }
__declspec(dllexport) void __cdecl lua_pushinteger(State* state, std::ptrdiff_t value) { state->value = value; }
__declspec(dllexport) void __cdecl lua_createtable(State* state, int, int) { state->table = true; }
__declspec(dllexport) void __cdecl lua_pushcclosure(State* state, LuaFunction fn, int) { state->function = fn; }
__declspec(dllexport) void __cdecl lua_setfield(State* state, int, const char* name) {
    if (strcmp(name, "process_id") == 0) state->process_id = state->value;
    else if (state->function) {
        if (strcmp(name, "tap_tab") == 0) state->tap_tab = state->function;
        ++state->callbacks;
    }
    state->function = nullptr;
}
__declspec(dllexport) void __cdecl lua_rawseti(State*, int, int) {}

__declspec(dllexport) bool __cdecl verify_messages_module(LuaFunction open) {
    State state;
    return open(&state) == 1 && state.table && state.callbacks == 5 && state.tap_tab &&
        state.process_id == GetCurrentProcessId();
}
}
