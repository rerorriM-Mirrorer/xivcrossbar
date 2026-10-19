-- Actual optional estimator with a controlled clock. Off must bypass timing,
-- sampling and pause work; on must handle overlapping and overdue pauses.
local now,reads=0,0
local tracker=require('libs/autoattack').new(function() reads=reads+1;return now end)
local function off_events()
    tracker:set_engaged(true,{2})
    tracker:gain_buff(6);tracker:lose_buff(6)
    tracker:add_pause('ws',2);tracker:remove_pause('ws')
    tracker:record_swing();assert(tracker:elapsed()==nil)
end
off_events();assert(reads==0 and #tracker.intervals==0 and not tracker:is_paused())
tracker:set_enabled(true);tracker:set_engaged(true)
now=2;tracker:record_swing();assert(tracker.estimate==nil)
now=8;tracker:record_swing();assert(tracker.estimate==6)
for i=1,12 do now=now+4;tracker:record_swing() end
assert(#tracker.intervals==10 and tracker.estimate==4)
assert(not tracker:set_enabled(true) and tracker.estimate==4,'idempotent on clears learning')

now=60;tracker:add_pause('ws',2)
now=61;tracker:add_pause('ja',2)
now=65;assert(tracker:elapsed()==6 and not tracker:is_paused())
-- Previous swing was 56; the union of pauses was 60..63, not 2+2 seconds.
tracker:record_swing();assert(tracker.intervals[#tracker.intervals]==6)
now=66;tracker:add_pause('ws',2)
now=67;tracker:add_pause('ws',2)
now=70;assert(tracker:elapsed()==2 and not tracker:is_paused())

tracker:set_engaged(false)
assert(tracker.estimate==nil and tracker:elapsed()==nil)
now=100;tracker:set_engaged(true,{2})
now=105;tracker:add_pause('ws',2)
now=108;assert(tracker:elapsed()==0 and tracker:is_paused())
now=110;tracker:lose_buff(2)
now=112;assert(tracker:elapsed()==2 and not tracker:is_paused())
tracker:record_swing();assert(tracker.estimate==nil)
now=116;tracker:record_swing();assert(tracker.estimate==4)

tracker:add_pause('ja',2)
tracker:set_enabled(false)
local before=reads
now=1000;off_events()
assert(reads==before and not tracker.engaged and tracker.estimate==nil)
assert(#tracker.intervals==0 and not next(tracker.pause_sources))
tracker:set_enabled(true);tracker:set_engaged(true)
assert(not tracker:is_paused() and tracker.estimate==nil)
now=1001;tracker:record_swing()
now=1005;tracker:record_swing();assert(tracker.estimate==4)
tracker:reset();assert(tracker.enabled and not tracker.engaged and tracker:elapsed()==nil)
assert(not require('libs/autoattack').schedule,'estimator owns no scheduled callbacks')
print('Autoattack disabled-work bypass, learning, rolling history, overlapping pauses, persistent buffs and fresh restart checks passed.')
