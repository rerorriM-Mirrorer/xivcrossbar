-- Fresh-process saved settings use lowercase XML keys. Execute Windower's
-- actual merge function against the declared shape, not a copy of our loader.
local function copy(t)local d={};for k,v in pairs(t)do d[k]=type(v)=='table' and copy(v) or v end;return d end
table.copy=copy;_meta={T={}}
local merge=require('tests/fixtures/windower_config_merge')
local Banks=require('companion_banks')
local settings={CompanionBanks=Banks.defaults(),L1={Slot1={Alias='Original',Command='input /echo preserved'},X=41,Y=72}}
Banks.ensure(settings)
assert(settings.CompanionBanks.L1.Closed.Slot4.Key=='ctrl+i' and settings.CompanionBanks.LeftPanel.X==41)
settings.CompanionBanks.L1L2.Closed.Slot1.Command=''
settings.CompanionBanks.L1.Menu.Slot1={Alias='Custom menu',Kind='command',Command='input /echo context',Key='',Hold=false}
settings.CompanionBanks.R1R2.Closed.Slot8={Alias='Test',Kind='command',Command='input /check',Key='',Hold=false}
settings.CompanionBanks.RightPanel.X=547
local function xml_keys(t)local d={};for k,v in pairs(t)do d[k:lower()]=type(v)=='table' and xml_keys(v) or v=='' and {} or v end;return d end
local fresh={CompanionBanks=Banks.defaults(),L1={Slot1={Alias='Original',Command='input /echo preserved'}}}
merge(fresh,xml_keys(settings))
assert(fresh.CompanionBanks.L1.Menu.Slot1.Alias=='Custom menu')
assert(fresh.CompanionBanks.R1R2.Closed.Slot8.Command=='input /check')
local _,migrated=Banks.ensure(fresh);assert(not migrated)
assert(fresh.CompanionBanks.L1L2.Closed.Slot1.Command=='','cleared migration slot was reseeded after fresh config load')
assert(fresh.CompanionBanks.RightPanel.X==547)
assert(fresh.CompanionBanks.L1.Closed.Slot4.Key=='ctrl+i')
assert(type(fresh.CompanionBanks.R1.Closed.Slot4.Hold)=='boolean' and fresh.CompanionBanks.R1.Closed.Slot4.Hold)
assert(fresh.CompanionBanks.l1==nil and fresh.CompanionBanks.L1.menu==nil,'unknown lowercased keys survived')
print('Actual Windower config merge: complete default shape, lowercase XML reload, typed entries, cleared-slot preservation, legacy import and saved panel positions passed.')
