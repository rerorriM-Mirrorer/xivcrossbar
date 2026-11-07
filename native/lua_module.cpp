// Windower's Lua 5.1 ABI is exported by the already-loaded LuaCore.dll.
// Resolve only the calls used here, without loading a second Lua runtime.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cstddef>

struct lua_State;
extern "C" unsigned __cdecl xb_begin(unsigned, unsigned, unsigned, unsigned, const char*);
extern "C" void __cdecl xb_off();
extern "C" unsigned __cdecl xb_detach();
extern "C" unsigned __cdecl xb_poll(unsigned, int*, unsigned, unsigned*);

namespace {
using LuaFunction = int (__cdecl*)(lua_State*);
struct Api {
    std::ptrdiff_t (__cdecl* integer)(lua_State*, int);
    const char* (__cdecl* string)(lua_State*, int, size_t*);
    void (__cdecl* push)(lua_State*, std::ptrdiff_t);
    void (__cdecl* table)(lua_State*, int, int);
    void (__cdecl* closure)(lua_State*, LuaFunction, int);
    void (__cdecl* field)(lua_State*, int, const char*);
    void (__cdecl* index)(lua_State*, int, int);
} api;

template<typename T>
bool resolve(HMODULE host, T& function, const char* name) {
    function = reinterpret_cast<T>(GetProcAddress(host, name));
    return function != nullptr;
}

int begin(lua_State* L) {
    const unsigned result = xb_begin(static_cast<unsigned>(api.integer(L, 1)),
        static_cast<unsigned>(api.integer(L, 2)), static_cast<unsigned>(api.integer(L, 3)),
        static_cast<unsigned>(api.integer(L, 4)), api.string(L, 5, nullptr));
    api.push(L, result);
    return 1;
}
int pid(lua_State* L) { api.push(L, GetCurrentProcessId()); return 1; }
int off(lua_State*) { xb_off(); return 0; }
int detach(lua_State* L) { api.push(L, xb_detach()); return 1; }
int poll(lua_State* L) {
    int edges[256]{};
    unsigned status[8]{};
    const auto count = xb_poll(static_cast<unsigned>(api.integer(L, 1)), edges, 256, status);
    api.table(L, count, 0);
    for (unsigned i = 0; i < count; ++i) {
        api.push(L, edges[i]);
        api.index(L, -2, i + 1);
    }
    api.table(L, 8, 0);
    for (int i = 0; i < 8; ++i) {
        api.push(L, status[i]);
        api.index(L, -2, i + 1);
    }
    return 2;
}
}

extern "C" __declspec(dllexport) int __cdecl luaopen_xb_gamepad(lua_State* L) {
    const HMODULE host = GetModuleHandleW(L"LuaCore.dll");
    if (!host || !resolve(host, api.integer, "lua_tointeger") ||
        !resolve(host, api.string, "lua_tolstring") || !resolve(host, api.push, "lua_pushinteger") ||
        !resolve(host, api.table, "lua_createtable") || !resolve(host, api.closure, "lua_pushcclosure") ||
        !resolve(host, api.field, "lua_setfield") || !resolve(host, api.index, "lua_rawseti")) return 0;
    api.table(L, 0, 5);
    api.closure(L, begin, 0); api.field(L, -2, "begin");
    api.closure(L, pid, 0); api.field(L, -2, "pid");
    api.closure(L, off, 0); api.field(L, -2, "off");
    api.closure(L, detach, 0); api.field(L, -2, "detach");
    api.closure(L, poll, 0); api.field(L, -2, "poll");
    return 1;
}
