-- Capability sets are ordinary editable environments. Add only absent sets;
-- never move actions or fill the player's occupied (or intentionally empty) slots.
local M={}
local defs={
 {key='white-magic',name='White Magic',kind='WhiteMagic'},
 {key='black-magic',name='Black Magic',kind='BlackMagic'},
 {key='blue-magic',name='Blue Magic',kind='BlueMagic'},
 {key='songs',name='Songs',kind='BardSong'},
 {key='ninjutsu',name='Ninjutsu',kind='Ninjutsu'},
 {key='summoning',name='Summoning',kind='SummonerPact'},
 {key='geomancy',name='Geomancy',kind='Geomancy'},
 {key='trusts',name='Trusts',kind='Trust'},
 {key='job-abilities',name='Job Ability'},
 {key='weapon-skills',name='Weaponskill'},
 {key='blood-pact-rage',name='Rage',job=15},
 {key='blood-pact-ward',name='Ward',job=15},
 {key='ready',name='Ready',job=9},
 {key='phantom-rolls',name='Phantom Rolls',job=17},
 {key='quick-draw',name='Quick Draw',job=17},
 {key='stratagems',name='Stratagems',job=20},
 {key='dances',name='Dances',job=19},
 {key='rune-enchantments',name='Rune Enchantments',job=22},
 {key='wards',name='Wards',job=22},
 {key='effusions',name='Effusions',job=22},
 {key='pet-commands',name='Pet',jobs={[9]=true,[14]=true,[15]=true,[18]=true}},
}
function M.available(player,spells,known)
    player=player or {};local kinds={}
    for id,spell in pairs(spells or {})do
        for _,pair in ipairs({{player.main_job_id,player.main_job_level},{player.sub_job_id,player.sub_job_level}})do
            local level=spell.levels and spell.levels[pair[1]]
            if level and level<=(pair[2] or 0) and (spell.type~='Trust' or (known or {})[id]) then kinds[spell.type]=true end
        end
    end
    local out={}
    for _,d in ipairs(defs)do
        if (d.kind and kinds[d.kind]) or (d.job and (player.main_job_id==d.job or player.sub_job_id==d.job))
                or (d.jobs and (d.jobs[player.main_job_id] or d.jobs[player.sub_job_id]))
                or (not d.kind and not d.job and not d.jobs and player.main_job_id) then out[#out+1]=d end
    end
    return out
end
function M.ensure(hotbar,player,spells,known,count)
    local added = 0
    for _,d in ipairs(M.available(player,spells,known)) do
        if not hotbar[d.key] then
            local bar={name=d.name}
            hotbar[d.key]=bar
            for i=1,count do bar['hotbar_'..i]={slot_9={}} end
            added = added + 1
        end
    end
    return added
end
return M
