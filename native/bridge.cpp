#define WIN32_LEAN_AND_MEAN
#define DIRECTINPUT_VERSION 0x0800
#include <windows.h>
#include <dinput.h>
#include <dinputd.h>
#include <xinput.h>
#include <MinHook.h>
#include <array>
#include <cstddef>
#include <cstring>
#include <mutex>
#include <utility>
#include "ownership.hpp"
#include "pad_state.hpp"

static_assert(sizeof(void*) == 4, "Windower 4 requires an x86 DLL");
namespace {
using XboxRead = DWORD (WINAPI*)(DWORD, XINPUT_STATE*);
using DirectRead = HRESULT (STDMETHODCALLTYPE*)(IDirectInputDevice8A*, DWORD, void*);
using DirectBuffered = HRESULT (STDMETHODCALLTYPE*)(IDirectInputDevice8A*, DWORD, DIDEVICEOBJECTDATA*, DWORD*, DWORD);
// Five system XInput DLLs, each with public GetState and optional GetStateEx.
constexpr unsigned max_xbox_hooks = 10;
struct XboxHook {
    XboxRead original{};
    XINPUT_GAMEPAD previous{};
    DWORD source_packet{}, visible_packet{};
    bool initialized{};
};
std::array<XboxHook, max_xbox_hooks> xbox_hooks;
thread_local bool xbox_nested;

DirectRead direct_original;
DirectBuffered buffered_original;
std::mutex guard;
xb::Ownership ownership, buffered_ownership;
unsigned buffered_raw;
DIDEVICEOBJECTDATA buffered_hat{};
bool buffered_hat_pending;
std::array<int, 256> events{};
unsigned head, count, generation, mode, device, raw, suppressed, calls, buffered_calls, unsupported;
unsigned backend, last_context;
bool menu, native_menu, fightpad, r1_chooser, overflow, buffered_seen, probe_ready;
GUID joystick;
ULONGLONG heartbeat, last_sample;

void reset() {
    ownership.reset();
    buffered_ownership.reset();
    buffered_raw = 0;
    buffered_hat_pending = false;
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
        buffered_ownership.reset();
        buffered_raw = 0;
        buffered_hat_pending = false;
        suppressed = 0;
        return 0;
    }
    if ((mode == 1 || mode == 3) && !probe_ready && !(buttons & xb::controls)) {
        probe_ready = true;
        buffered_ownership.apply(0, 2, menu, native_menu);
    }
    const auto result = ownership.apply(buttons, mode == 3 ? 2 : mode, menu, native_menu, 0, mode == 3 ? now : 0);
    suppressed = result.suppressed;
    if (mode == 3) return suppressed;
    // Releases precede presses; simultaneous triggers precede face/D-pad.
    for (int i = 0; i < 12; ++i)
        if (result.up & (1u << i)) enqueue(-(i + 1));
    for (int i : {10, 11, 0, 1, 2, 3, 4, 5, 6, 7})
        if (result.down & (1u << i)) enqueue(i + 1);
    if (overflow) { reset(); return 0; }
    return suppressed;
}

template<unsigned Hook>
DWORD WINAPI xbox_read(DWORD index, XINPUT_STATE* state) {
    auto& hook = xbox_hooks[Hook];
    // One system XInput export can call another. Observe the outermost read.
    if (xbox_nested) return hook.original(index, state);
    xbox_nested = true;
    const DWORD result = hook.original(index, state);
    xbox_nested = false;
    std::lock_guard lock(guard);
    if (backend != 1 || index != device) return result;
    if (result != ERROR_SUCCESS || !state) {
        hook.initialized = false;
        if (last_sample) { reset(); last_sample = 0; }
        return result;
    }
    auto& pad = state->Gamepad;
    const unsigned mask = observe(xb::read_xbox(pad.wButtons, pad.bLeftTrigger, pad.bRightTrigger, r1_chooser));
    for (unsigned i = 0; i < 10; ++i)
        if (mask & (1u << i)) pad.wButtons &= static_cast<WORD>(~xb::xbox_button(i, r1_chooser));
    if (mask & 0x400) pad.bLeftTrigger = 0;
    if (mask & 0x800) pad.bRightTrigger = 0;
    if (!mode && !hook.initialized) return result;
    // A context change or D-pad handoff can change the filtered state without
    // changing the hardware packet number. Notify consumers of that change.
    if (!hook.initialized) hook.visible_packet = state->dwPacketNumber;
    else if (hook.source_packet != state->dwPacketNumber ||
        memcmp(&hook.previous, &pad, sizeof pad) != 0) ++hook.visible_packet;
    hook.source_packet = state->dwPacketNumber;
    hook.previous = pad;
    hook.initialized = true;
    state->dwPacketNumber = hook.visible_packet;
    return result;
}

template<std::size_t... I>
constexpr auto xbox_entries(std::index_sequence<I...>) {
    return std::array<XboxRead, sizeof...(I)>{xbox_read<I>...};
}
constexpr auto xbox_detours = xbox_entries(std::make_index_sequence<max_xbox_hooks>{});
constexpr const char* xbox_modules[] = {
    "xinput1_4.dll", "xinput1_3.dll", "xinput9_1_0.dll", "xinput1_2.dll", "xinput1_1.dll"
};

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
        if (!probe_ready && heartbeat && SUCCEEDED(result)) {
            DIJOYSTATE2 current{};
            auto hr = direct_original(object, sizeof current, &current);
            if (FAILED(hr)) hr = direct_original(object, sizeof(DIJOYSTATE), &current);
            if (SUCCEEDED(hr)) observe(xb::read_joystick(current.rgdwPOV[0], current.rgbButtons, fightpad));
        }
        // Neutralize matching records, retaining timestamps,
        // sequence numbers, queue lengths and DIGDD_PEEK semantics.
        constexpr DWORD legacy_size = offsetof(DIDEVICEOBJECTDATA, uAppData);
        DWORD foreground = 0;
        GetWindowThreadProcessId(GetForegroundWindow(), &foreground);
        if ((mode != 1 && mode != 3) || !probe_ready || !heartbeat || GetTickCount64() - heartbeat > 500 ||
            foreground != GetCurrentProcessId() || FAILED(result) || !data || !entries ||
            *entries > capacity || (size != legacy_size && size != sizeof(DIDEVICEOBJECTDATA)))
            return result;
        last_sample = GetTickCount64();
        ++calls;
        auto* bytes = reinterpret_cast<unsigned char*>(data);
        auto stream = buffered_ownership;
        unsigned state = buffered_raw;
        auto hat = buffered_hat;
        bool hat_pending = buffered_hat_pending;
        const auto now = GetTickCount64();
        for (DWORD i = 0; i < *entries; ++i) {
            auto* record = bytes + i * size;
            DWORD offset, value;
            memcpy(&offset, record, sizeof offset);
            memcpy(&value, record + sizeof offset, sizeof value);
            DIDEVICEOBJECTINSTANCEA info{};
            info.dwSize = sizeof(info);
            if (FAILED(object->GetObjectInfo(&info, offset, DIPH_BYOFFSET))) continue;
            const auto instance = DIDFT_GETINSTANCE(info.dwType);
            const auto type = DIDFT_GETTYPE(info.dwType);
            if ((type & DIDFT_POV) && instance == 0) {
                const std::uint8_t neutral[32]{};
                state = (state & ~0xfu) | xb::read_joystick(value, neutral, fightpad);
                const auto mask = mode == 1 ? xb::up : stream.apply(state, 2, menu, native_menu, 0, now).suppressed;
                if (mode == 3) memcpy(&hat, record, size);
                const auto filtered = xb::filter_hat(value, mask);
                hat_pending = mode == 3 && filtered != value;
                value = filtered;
            } else if (type & DIDFT_BUTTON) {
                const auto* map = fightpad ? xb::fightpad : xb::dualsense;
                unsigned bit = 0;
                for (unsigned j = 0; j < sizeof(xb::logical_buttons) / sizeof(*xb::logical_buttons); ++j)
                    if (instance == map[j]) bit = 1u << xb::logical_buttons[j];
                if (!bit) continue;
                state = (state & ~bit) | ((value & 0x80u) ? bit : 0);
                const auto mask = mode == 1 ? xb::circle : stream.apply(state, 2, menu, native_menu, 0, now).buffered_mask();
                if (mask & bit) value &= ~0x80u;
            } else continue;
            memcpy(record + sizeof offset, &value, sizeof value);
        }
        if (mode == 3 && hat_pending && *entries < capacity && result == DI_OK) {
            const auto mask = stream.apply(state, 2, menu, native_menu, 0, now).suppressed;
            if (!(mask & state & xb::directions)) {
                hat.dwTimeStamp = GetTickCount();
                memcpy(bytes + (*entries)++ * size, &hat, size);
                hat_pending = false;
            }
        }
        if (!(flags & DIGDD_PEEK)) {
            buffered_hat = hat;
            buffered_hat_pending = hat_pending;
            buffered_ownership = stream;
            buffered_raw = state;
        }
    }
    return result;
}

struct Enumeration { GUID instance; unsigned count; };
BOOL CALLBACK choose_device(const DIDEVICEINSTANCEA* info, void* context) {
    auto& pick = *static_cast<Enumeration*>(context);
    if (!pick.count++) pick.instance = info->guidInstance;
    return pick.count == 1 ? DIENUM_CONTINUE : DIENUM_STOP;
}

void* targets[max_xbox_hooks];
unsigned target_count;
bool hooks_enabled;

bool set_hooks(bool enabled) {
    for (unsigned i = 0; i < target_count; ++i) {
        const auto result = enabled ? MH_QueueEnableHook(targets[i]) : MH_QueueDisableHook(targets[i]);
        if (result != MH_OK) return false;
    }
    if (MH_ApplyQueued() != MH_OK) return false;
    hooks_enabled = enabled;
    return true;
}
bool install(unsigned kind, unsigned index, const char* module) {
    const auto mh = MH_Initialize();
    if (mh != MH_OK && mh != MH_ERROR_ALREADY_INITIALIZED) return false;
    if (kind == 1) {
        for (auto name : xbox_modules) {
            if (strcmp(module, "auto") != 0 && _stricmp(module, name) != 0) continue;
            const auto loaded = GetModuleHandleA(name);
            if (!loaded) continue;
            const LPCSTR entries[] = {"XInputGetState", MAKEINTRESOURCEA(100)};
            for (auto entry : entries) {
                auto* target = reinterpret_cast<void*>(GetProcAddress(loaded, entry));
                if (!target) continue;
                bool duplicate = false;
                for (unsigned i = 0; i < target_count; ++i)
                    if (targets[i] == target) duplicate = true;
                if (duplicate) continue;
                const auto i = target_count;
                const auto created = MH_CreateHook(target, reinterpret_cast<void*>(xbox_detours[i]),
                    reinterpret_cast<void**>(&xbox_hooks[i].original));
                if (created == MH_ERROR_UNSUPPORTED_FUNCTION) continue;
                if (created != MH_OK) {
                    while (target_count) MH_RemoveHook(targets[--target_count]);
                    return false;
                }
                targets[target_count++] = target;
            }
        }
        if (!target_count) return false;
    } else {
        const auto loaded = GetModuleHandleA("dinput8.dll");
        if (!loaded) return false;
        using Create = HRESULT (WINAPI*)(HINSTANCE, DWORD, REFIID, LPVOID*, LPUNKNOWN);
        const auto factory = reinterpret_cast<Create>(GetProcAddress(loaded, "DirectInput8Create"));
        IDirectInput8A* direct = nullptr;
        if (!factory || FAILED(factory(GetModuleHandle(nullptr), DIRECTINPUT_VERSION,
            IID_IDirectInput8A, reinterpret_cast<void**>(&direct), nullptr))) return false;
        IDirectInputJoyConfig8* config = nullptr;
        DIJOYCONFIG selected{};
        selected.dwSize = sizeof selected;
        bool found = false;
        if (SUCCEEDED(direct->QueryInterface(IID_IDirectInputJoyConfig8,
            reinterpret_cast<void**>(&config)))) {
            found = config->GetConfig(index, &selected, DIJC_GUIDINSTANCE) == DI_OK;
            config->Release();
        }
        // Enumeration order is not a Windows joystick ID. The only safe
        // fallback is the single attached controller in the default slot.
        if (!found && index == 0) {
            Enumeration pick{};
            if (SUCCEEDED(direct->EnumDevices(DI8DEVCLASS_GAMECTRL, choose_device, &pick, DIEDFL_ATTACHEDONLY)) &&
                pick.count == 1) {
                selected.guidInstance = pick.instance;
                found = true;
            }
        }
        IDirectInputDevice8A* probe = nullptr;
        if (found) direct->CreateDevice(selected.guidInstance, &probe, nullptr);
        direct->Release();
        if (!probe) return false;
        joystick = selected.guidInstance;
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
    return true;
}
}

extern "C" {
__declspec(dllexport) unsigned __cdecl xb_begin(unsigned kind, unsigned index, unsigned experiment,
    unsigned fight, const char* module) {
    if ((kind != 1 && kind != 2) || (experiment < 1 || experiment > 3) ||
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
    } else if (installed_kind != kind || (kind == 2 && installed_device != index) ||
        strcmp(installed_module.data(), module) != 0) return 2;
    if (!hooks_enabled && !set_hooks(true)) return 0;
    std::lock_guard lock(guard);
    reset();
    backend = kind; device = index; fightpad = fight == 1; r1_chooser = fight == 2;
    for (auto& hook : xbox_hooks) hook.initialized = false;
    overflow = false;
    mode = experiment;
    heartbeat = 0; // Wait for the addon to publish the first input context.
    last_context = 0;
    return 1;
}
__declspec(dllexport) void __cdecl xb_off() {
    std::lock_guard lock(guard);
    mode = 0;
    reset();
}
__declspec(dllexport) unsigned __cdecl xb_detach() {
    xb_off();
    // Restore target entry points without freeing trampolines. A callback
    // already in flight may still need its original-function trampoline.
    return !target_count || set_hooks(false);
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
    else {
        // A lost reader lease gives ownership back to the game. Rearm
        // from neutral while observing, before allowing capture again.
        if (context == 4 && last_context != 4) reset();
        heartbeat = now;
    }
    last_context = context;
    menu = context == 2;
    native_menu = context == 3 || context == 4;
    status[0] = generation; status[1] = calls; status[2] = raw; status[3] = suppressed;
    status[4] = buffered_calls; status[5] = unsupported; status[6] = overflow; status[7] = probe_ready;
    unsigned delivered = 0;
    while (count && delivered < capacity) {
        output[delivered++] = events[head];
        head = (head + 1) % events.size();
        --count;
    }
    return delivered;
}
}
