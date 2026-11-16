-- A: chain glows on crossbar slot borders (2026-11-16). Pure colour/alpha
-- maths; ui.lua owns the images. All times are seconds.
--   burst:  the spell can Magic Burst: its element's colour, breathing
--           (1.2 s), quickening to 0.4 s in the window's last 1.5 s.
--   charge: a weaponskill will be able to close a skillchain once the window
--           opens: steady white that brightens as the window approaches.
--   open:   the skillchain window is open: blue/white electric flicker from
--           two out-of-step waves plus random one-frame white "arcs"; in
--           the last 1.5 s it quickens and fades out.
local M = {}

M.element_colors = {
    Fire = {255, 90, 40}, Ice = {130, 215, 255}, Wind = {90, 235, 120}, Earth = {230, 190, 70},
    Lightning = {185, 110, 255}, Water = {60, 125, 255}, Light = {255, 245, 205}, Dark = {150, 60, 205},
}
M.blue = {80, 170, 255}
M.white = {255, 255, 255}
M.arc_chance = .08
M.ending = 1.5

local two_pi = 2 * math.pi
local function mix(a, b, f)
    return math.floor(a[1] + (b[1] - a[1]) * f + .5), math.floor(a[2] + (b[2] - a[2]) * f + .5),
        math.floor(a[3] + (b[3] - a[3]) * f + .5)
end

-- t: clock; remaining: seconds left in the burst window.
function M.burst(element, t, remaining)
    local c = M.element_colors[element] or M.white
    local period = (remaining and remaining < M.ending) and .4 or 1.2
    local wave = .5 - .5 * math.cos(two_pi * t / period)
    return c[1], c[2], c[3], math.floor(140 + 90 * wave + .5)
end

-- remaining / total: seconds until the window opens, and the full wait.
function M.charge(remaining, total)
    local fraction = 1
    if total and total > 0 then fraction = 1 - math.max(0, math.min(remaining or 0, total)) / total end
    return 255, 255, 255, math.floor(60 + 160 * fraction + .5)
end

-- random: a function returning [0,1) (math.random; injectable for tests).
function M.open(t, remaining, random)
    random = random or math.random
    local ending = remaining and remaining < M.ending
    local speed = ending and 1.6 or 1
    local f = .5 + .25 * math.sin(two_pi * 7.3 * speed * t) + .15 * math.sin(two_pi * 13.1 * speed * t + 1.7)
    local fade = ending and math.max(0, remaining / M.ending) or 1
    if random() < M.arc_chance then
        return 255, 255, 255, math.floor(255 * fade + .5)
    end
    local r, g, b = mix(M.blue, M.white, f)
    return r, g, b, math.floor((150 + 90 * f) * fade + .5)
end

return M
