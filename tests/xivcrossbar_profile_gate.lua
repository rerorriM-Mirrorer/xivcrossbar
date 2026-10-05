-- Contributing author: A. Login may report an old server until the player
-- entity is in-world; never write a fresh hotbar under that transient path.
local now = 0
local profile = require('profile_gate').new(function() return now end, 0.75)
local player = {id = 101, name = 'Myrr'}
local entity = {id = 101, name = 'Myrr'}
local asura = {logged_in = true, server = 1, zone = 100}
local fenrir = {logged_in = true, server = 3, zone = 100}
local known = {en = 'Fenrir'}

-- The login callback alone is not proof of an established server.
assert(profile:observe({logged_in = true, server = 1, zone = 0}, player, nil, known) == nil)
assert(profile:observe(asura, player, nil, known) == nil)
assert(profile:observe(asura, player, {id = 101, name = 'Someone else'}, known) == nil)
assert(profile:observe(asura, player, entity, nil) == nil)
assert(profile:observe(asura, player, entity, known) == nil)
now = 0.4
assert(profile:observe(asura, player, entity, known) == nil)

-- A change before the world-ready pair settles abandons the stale profile.
now = 0.5
assert(profile:observe(fenrir, player, entity, known) == nil)
now = 1.24
assert(profile:observe(fenrir, player, entity, known) == nil)
now = 1.25
local server, name = profile:observe(fenrir, player, entity, known)
assert(server == 3 and name == 'Myrr')
assert(profile:observe(fenrir, player, entity, known) == nil)

-- A later correction must offer the new profile exactly once to the host,
-- which reloads its UI before reading the corrected path.
now = 2
assert(profile:observe(asura, player, entity, known) == nil)
now = 2.75
server, name = profile:observe(asura, player, entity, known)
assert(server == 1 and name == 'Myrr')
assert(profile:observe(asura, player, entity, known) == nil)
profile:reset()
now = 3
assert(profile:observe(fenrir, player, entity, known) == nil)
print('PASS: in-world server settles before profile creation and corrections are detected')
