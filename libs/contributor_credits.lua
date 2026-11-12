-- Supplied contributor names/portraits; retain established role credits.
local M={entries={
    {name='Programming/Art\nAliekber',person='Aliekber',icon='aliekber'},
    {name='Based on XIVHotbar by\nSirEdeonX',person='SirEdeonX',icon='edeon'},
    {name='Skillchains\nIvaar',person='Ivaar',icon='ivaar'},
    {name='Skillchains updates\nposimagi',person='posimagi',icon='posimagi'},
    {name='MountRoulette\nXurion',person='Xurion',icon='xurion'},
    {name='IconExtractor\nRubenator',person='Rubenator',icon='rubenator'},
    {name='Beta Testing\nJinxs',person='Jinxs',icon='jinxs'},
    {name='Beta Testing\nMartel',person='Martel',icon='martel'},
    {name='Community contribution\nAeliya',person='Aeliya',icon='aeliya'},
    {name='Community contribution\nAkirane',person='Akirane',icon='akirane'},
    {name='Community contribution\nBlueSummersC',person='BlueSummersC',icon='bluesummersc'},
    {name='Community contribution\nqEagleStrikerp',person='qEagleStrikerp',icon='qeaglestrikerp'},
    {name='Community contribution\nFionaBrightgrass',person='FionaBrightgrass',icon='fionabrightgrass'},
    {name='Community contribution\nFrostTrunks / Zuberj',person='FrostTrunks / Zuberj',icon='frosttrunks'},
    {name='Community contribution\nGrayFox2510',person='GrayFox2510',icon='grayfox2510'},
    {name='Community contribution\nHunterHog / Rhulkr',person='HunterHog / Rhulkr',icon='hunterhog'},
    {name='Community contribution\nIcyDeath',person='IcyDeath',icon='icydeath'},
    {name='Community contribution\nSylvebits / Sylve',person='Sylvebits / Sylve',icon='sylvebits'},
    {name='Community contribution\nXerevNonori',person='XerevNonori',icon='xerevnonori'},
    {name='Development\nA',person='A',icon='a'},
}}
M.icon_names={}
for _,entry in ipairs(M.entries) do M.icon_names[entry.icon]=entry.person end
return M
