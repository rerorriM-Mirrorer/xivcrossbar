-- Capability sets are ordinary editable environments. Add only absent sets;
-- never move actions or fill the player's occupied (or intentionally empty) slots.
local M={}
local defs={
 {key='white-magic',name='White Magic',kind='WhiteMagic',icon='whm'},
 {key='black-magic',name='Black Magic',kind='BlackMagic',icon='blm'},
 {key='blue-magic',name='Blue Magic',kind='BlueMagic',icon='blu'},
 {key='songs',name='Songs',kind='BardSong',icon='brd'},
 {key='ninjutsu',name='Ninjutsu',kind='Ninjutsu',icon='nin'},
 {key='summoning',name='Summoning',kind='SummonerPact',icon='smn'},
 {key='geomancy',name='Geomancy',kind='Geomancy',icon='geo'},
 {key='trusts',name='Trusts',kind='Trust',icon='trust'},
 {key='job-abilities',name='Job Abilities',icon='ja'},
 {key='weapon-skills',name='Weapon Skills',icon='ws'},
 {key='blood-pact-rage',name='Blood Pact: Rage',job=15,icon='bpr'},
 {key='blood-pact-ward',name='Blood Pact: Ward',job=15,icon='bpw'},
 {key='ready',name='Ready',job=9,icon='bst'},
 {key='phantom-rolls',name='Phantom Rolls',job=17,icon='cor'},
 {key='quick-draw',name='Quick Draw',job=17,icon='cor'},
 {key='stratagems',name='Stratagems',job=20,icon='sch'},
 {key='dances',name='Dances',job=19,icon='dnc'},
 {key='rune-enchantments',name='Rune Enchantments',job=22,icon='run'},
 {key='wards',name='Wards',job=22,icon='run'},
 {key='effusions',name='Effusions',job=22,icon='run'},
 {key='pet-commands',name='Pet Commands',jobs={[9]=true,[14]=true,[15]=true,[18]=true},icon='pet'},
}
local paths={bst='jobs/BST',cor='jobs/COR',sch='jobs/SCH',dnc='jobs/DNC',run='jobs/RUN',whm='jobs/WHM',blm='jobs/BLM',blu='jobs/BLU',brd='jobs/BRD',nin='jobs/NIN',smn='jobs/SMN',geo='jobs/GEO',trust='trust/yoran-oran',ja='jobs/WAR',ws='weaponskills/sword/savage-blade',bpr='fallback/abilities/00173',bpw='fallback/abilities/00174',pet='mounts/crab'}
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
    for _,d in ipairs(M.available(player,spells,known))do
        if not hotbar[d.key] then
            local bar={name=d.name};hotbar[d.key]=bar
            for i=1,count do bar['hotbar_'..i]={slot_9={}} end
        end
    end
end
function M.icon(key,base,exists)
    for _,d in ipairs(defs)do
        if d.key==key then
            local path='images/'..base..'/'..paths[d.icon]..'.png'
            if exists(path)then return path end
            -- Category artwork is shipped in the default pack even if a custom
            -- pack omits it. A common gear is the final existing fallback.
            path='images/icons/default/'..paths[d.icon]..'.png'
            if exists(path)then return path end
            return 'images/'..base..'/custom_actions.png'
        end
    end
end
return M
