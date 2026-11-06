#define WIN32_LEAN_AND_MEAN
#define DIRECTINPUT_VERSION 0x0800
#include <windows.h>
#include <dinput.h>
#include <xinput.h>
#include <MinHook.h>
#include <array>
#include <cstddef>
#include <cstring>
#include <mutex>
#include "ownership.hpp"
#include "pad_state.hpp"

static_assert(sizeof(void*) == 4, "Windower 4 requires an x86 DLL");
namespace {
using XboxRead = DWORD (WINAPI*)(DWORD, XINPUT_STATE*);
using DirectRead = HRESULT (STDMETHODCALLTYPE*)(IDirectInputDevice8A*, DWORD, void*);
using DirectBuffered = HRESULT (STDMETHODCALLTYPE*)(IDirectInputDevice8A*, DWORD, DIDEVICEOBJECTDATA*, DWORD*, DWORD);
XboxRead xbox_original;
DirectRead direct_original;
DirectBuffered buffered_original;
std::mutex guard;
xb::Ownership ownership;
std::array<int, 256> events{};
unsigned head, count, generation, mode, device, raw, suppressed, calls, buffered_calls, unsupported;
unsigned backend;
bool menu, native_menu, fightpad, overflow, buffered_seen, probe_ready;
GUID joystick;
ULONGLONG heartbeat, last_sample;

void reset() {
    ownership.reset();
    probe_ready = false;
    head = count = raw = suppressed = 0;
    ++generation;
}
void enqueue(int edge) {
    if (count == events.size()) { overflow = true; return; }
    events[(head + count++) % events.size()] = edge;
}
unsigned observe(unsigned buttons) {
    ++calls;
    raw = buttons;
    const auto now = GetTickCount64();
    if (last_sample && now - last_sample > 500) reset();
    last_sample = now;
    DWORD foreground = 0;
    GetWindowThreadProcessId(GetForegroundWindow(), &foreground);
    if (!mode || !heartbeat || foreground != GetCurrentProcessId() || now - heartbeat > 500 ||
        (mode == 2 && buffered_seen) || overflow) {
        if (suppressed || count) reset();
        ownership.reset();
        probe_ready = false;
        suppressed = 0;
        return 0;
    }
    if (mode == 1 && !(buttons & xb::controls)) probe_ready = true;
    const auto result = ownership.apply(buttons, mode, menu, native_menu);
    suppressed = result.suppressed;
    // Releases precede presses; simultaneous triggers precede face/D-pad.
    for (int i = 0; i < 12; ++i)
        if (result.up & (1u << i)) enqueue(-(i + 1));
    for (int i : {10, 11, 0, 1, 2, 3, 4, 5, 6, 7})
        if (result.down & (1u << i)) enqueue(i + 1);
    if (overflow) { reset(); return 0; }
    return suppressed;
}

DWORD WINAPI xbox_read(DWORD index, XINPUT_STATE* state) {
    const DWORD result = xbox_original(index, state);
    std::lock_guard lock(guard);
    if (backend != 1 || index != device) return result;
    if (result != ERROR_SUCCESS || !state) {
        if (last_sample) { reset(); last_sample = 0; }
        return result;
    }
    auto& pad = state->Gamepad;
    const unsigned mask = observe(xb::read_xbox(pad.wButtons, pad.bLeftTrigger, pad.bRightTrigger));
    for (unsigned i = 0; i < 8; ++i)
        if (mask & (1u << i)) pad.wButtons &= static_cast<WORD>(~xb::xbox[i]);
    if (mask & 0x400) pad.bLeftTrigger = 0;
    if (mask & 0x800) pad.bRightTrigger = 0;
    return result;
}

bool is_selected(IDirectInputDevice8A* object) {
    DIDEVICEINSTANCEA info{};
    info.dwSize = sizeof(info);
    return SUCCEEDED(object->GetDeviceInfo(&info)) && IsEqualGUID(info.guidInstance, joystick);
}
HRESULT STDMETHODCALLTYPE direct_read(IDirectInputDevice8A* object, DWORD size, void* state) {
    const HRESULT result = direct_original(object, size, state);
    std::lock_guard lock(guard);
    if (backend != 2 || !mode || !is_selected(object)) return result;
    if (size != sizeof(DIJOYSTATE) && size != sizeof(DIJOYSTATE2)) {
        ++unsupported;
        if (last_sample) { reset(); last_sample = 0; }
        return result;
    }
    if (FAILED(result) || !state) {
        if (last_sample) { reset(); last_sample = 0; }
        return result;
    }
    // DIJOYSTATE and DIJOYSTATE2 share offsets through the first 32 buttons.
    auto* bytes = static_cast<unsigned char*>(state);
    DWORD pov;
    static_assert(offsetof(DIJOYSTATE, rgdwPOV) == offsetof(DIJOYSTATE2, rgdwPOV));
    static_assert(offsetof(DIJOYSTATE, rgbButtons) == offsetof(DIJOYSTATE2, rgbButtons));
    auto* hat = bytes + offsetof(DIJOYSTATE, rgdwPOV);
    auto* buttons = bytes + offsetof(DIJOYSTATE, rgbButtons);
    memcpy(&pov, hat, sizeof pov);
    const unsigned mask = observe(xb::read_joystick(pov, buttons, fightpad));
    pov = xb::filter_hat(pov, mask);
    memcpy(hat, &pov, sizeof pov);
    xb::filter_joystick(buttons, mask, fightpad);
    return result;
}

HRESULT STDMETHODCALLTYPE direct_buffered(IDirectInputDevice8A* object, DWORD size,
    DIDEVICEOBJECTDATA* data, DWORD* entries, DWORD flags) {
    const DWORD capacity = entries ? *entries : 0;
    const HRESULT result = buffered_original(object, size, data, entries, flags);
    std::lock_guard lock(guard);
    if (backend == 2 && mode && is_selected(object)) {
        ++buffered_calls;
        if (!buffered_seen) {
            buffered_seen = true;
            if (mode == 2) reset();
        }
        // Probe only: neutralize matching records, retaining timestamps,
        // sequence numbers, queue lengths and DIGDD_PEEK semantics.
        constexpr DWORD legacy_size = offsetof(DIDEVICEOBJECTDATA, uAppData);
        DWORD foreground = 0;
        GetWindowThreadProcessId(GetForegroundWindow(), &foreground);
        if (mode != 1 || !probe_ready || !heartbeat || GetTickCount64() - heartbeat > 500 ||
            foreground != GetCurrentProcessId() || FAILED(result) || !data || !entries ||
            *entries > capacity || (size != legacy_size && size != sizeof(DIDEVICEOBJECTDATA)))
            return result;
        auto* bytes = reinterpret_cast<unsigned char*>(data);
        for (DWORD i = 0; i < *entries; ++i) {
            auto* record = bytes + i * size;
            DWORD offset, value;
            memcpy(&offset, record, sizeof offset);
            memcpy(&value, record + sizeof offset, sizeof value);
            DIDEVICEOBJECTINSTANCEA info{};
            info.dwSize = sizeof(info);
            if (FAILED(object->GetObjectInfo(&info, offset, DIPH_BYOFFSET))) continue;
            if ((DIDFT_GETTYPE(info.dwType) & DIDFT_POV) && DIDFT_GETINSTANCE(info.dwType) == 0)
                value = xb::filter_hat(value, xb::up);
            else if ((DIDFT_GETTYPE(info.dwType) & DIDFT_BUTTON) &&
                DIDFT_GETINSTANCE(info.dwType) == (fightpad ? xb::fightpad[2] : xb::dualsense[2]))
                value &= ~0x80u;
            else continue;
            memcpy(record + sizeof offset, &value, sizeof value);
        }
    }
    return result;
}

struct Enumeration { unsigned remaining; GUID instance; bool found; };
BOOL CALLBACK choose_device(const DIDEVICEINSTANCEA* info, void* context) {
    auto& pick = *static_cast<Enumeration*>(context);
    if (pick.remaining--) return DIENUM_CONTINUE;
    pick.instance = info->guidInstance;
    pick.found = true;
    return DIENUM_STOP;
}

void* targets[2];
unsigned target_count;
bool install(unsigned kind, unsigned index, const char* module) {
    const auto mh = MH_Initialize();
    if (mh != MH_OK && mh != MH_ERROR_ALREADY_INITIALIZED) return false;
    if (kind == 1) {
        const auto loaded = GetModuleHandleA(module);
        if (!loaded) return false;
        targets[0] = reinterpret_cast<void*>(GetProcAddress(loaded, "XInputGetState"));
        if (!targets[0] || MH_CreateHook(targets[0], reinterpret_cast<void*>(xbox_read),
            reinterpret_cast<void**>(&xbox_original)) != MH_OK) return false;
        target_count = 1;
    } else {
        const auto loaded = GetModuleHandleA("dinput8.dll");
        if (!loaded) return false;
        using Create = HRESULT (WINAPI*)(HINSTANCE, DWORD, REFIID, LPVOID*, LPUNKNOWN);
        const auto factory = reinterpret_cast<Create>(GetProcAddress(loaded, "DirectInput8Create"));
        IDirectInput8A* direct = nullptr;
        if (!factory || FAILED(factory(GetModuleHandle(nullptr), DIRECTINPUT_VERSION,
            IID_IDirectInput8A, reinterpret_cast<void**>(&direct), nullptr))) return false;
        Enumeration pick{index, {}, false};
        direct->EnumDevices(DI8DEVCLASS_GAMECTRL, choose_device, &pick, DIEDFL_ATTACHEDONLY);
        IDirectInputDevice8A* probe = nullptr;
        if (pick.found) direct->CreateDevice(pick.instance, &probe, nullptr);
        direct->Release();
        if (!probe) return false;
        joystick = pick.instance;
        auto** methods = *reinterpret_cast<void***>(probe);
        targets[0] = methods[9];  // IDirectInputDevice8::GetDeviceState
        targets[1] = methods[10]; // IDirectInputDevice8::GetDeviceData
        probe->Release();
        if (MH_CreateHook(targets[0], reinterpret_cast<void*>(direct_read),
            reinterpret_cast<void**>(&direct_original)) != MH_OK) return false;
        if (MH_CreateHook(targets[1], reinterpret_cast<void*>(direct_buffered),
            reinterpret_cast<void**>(&buffered_original)) != MH_OK) {
            MH_RemoveHook(targets[0]);
            return false;
        }
        target_count = 2;
    }
    // Keep the DLL resident after Lua reload. Dormant detours pass through.
    HMODULE pinned = nullptr;
    if (!GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_PIN,
        reinterpret_cast<LPCSTR>(&install), &pinned)) return false;
    for (unsigned i = 0; i < target_count; ++i)
        if (MH_QueueEnableHook(targets[i]) != MH_OK) return false;
    return MH_ApplyQueued() == MH_OK;
}
}

extern "C" {
__declspec(dllexport) unsigned __cdecl xb_begin(unsigned kind, unsigned index, unsigned experiment,
    unsigned fight, const char* module) {
    if ((kind != 1 && kind != 2) || (experiment != 1 && experiment != 2) ||
        index >= (kind == 1 ? 4u : 16u) || !module) return 0;
    // Called only on Windower's Lua thread. Install without holding the
    // callback mutex so suspended input threads cannot deadlock installation.
    static unsigned installed_kind, installed_device;
    static std::array<char, 32> installed_module{};
    if (!installed_kind) {
        if (!install(kind, index, module)) return 0;
        installed_kind = kind;
        installed_device = index;
        strncpy_s(installed_module.data(), installed_module.size(), module, _TRUNCATE);
    } else if (installed_kind != kind || installed_device != index ||
        strcmp(installed_module.data(), module) != 0) return 2;
    std::lock_guard lock(guard);
    reset();
    backend = kind; device = index; fightpad = fight != 0;
    overflow = false;
    mode = experiment;
    heartbeat = GetTickCount64();
    return 1;
}
__declspec(dllexport) void __cdecl xb_off() {
    std::lock_guard lock(guard);
    mode = 0;
    reset();
}
__declspec(dllexport) unsigned __cdecl xb_poll(unsigned context, int* output, unsigned capacity, unsigned* status) {
    std::lock_guard lock(guard);
    const auto now = GetTickCount64();
    if ((heartbeat && now - heartbeat > 500) || (last_sample && now - last_sample > 500)) {
        reset();
        last_sample = 0;
        if (heartbeat && now - heartbeat > 500) heartbeat = 0;
    }
    if (context == 0) { if (heartbeat) reset(); heartbeat = 0; }
    else { heartbeat = now; }
    menu = context == 2;
    native_menu = context == 3;
    status[0] = generation; status[1] = calls; status[2] = raw; status[3] = suppressed;
    status[4] = buffered_calls; status[5] = unsupported; status[6] = overflow;
    unsigned delivered = 0;
    while (count && delivered < capacity) {
        output[delivered++] = events[head];
        head = (head + 1) % events.size();
        --count;
    }
    return delivered;
}
}
