-- Exercise the complete UI module and its real geometry with mock drawing APIs.
local cases, created, screen, primitives = 0, 0, {}, {}
local function object(kind)
    created=created+1
    local o={kind=kind, values={}, visible=false}
    return setmetatable(o,{__index=function(_,key)
        return function(self,...)
            local args={...}
            if key=='show' then self.visible=true
            elseif key=='hide' then self.visible=false
            elseif key=='destroy' then self.destroyed=true
            elseif key=='extents' then return #(self.values.text or '')*(self.values.size or 10)*.5,10
            elseif #args==0 then
                local value=self.values[key]
                if type(value)=='table' then return table.unpack(value) end
                return value
            else self.values[key]=#args==1 and args[1] or args end
        end
    end})
end
images={new=function() return object('image') end}
texts={new=function() return object('text') end}
windower={addon_path='addon/',register_event=function() end,
    get_windower_settings=function() return screen end,
    ffxi={get_player=function() return {buffs={},main_job_id=9} end},
    prim=setmetatable({},{__index=function(_,method)
        return function(name,...)
            primitives[name]=primitives[name] or {}
            primitives[name][method]={...}
        end
    end})}
package.loaded['ui/item_icons']={}
package.loaded['libs/kebab_casify']=function(name) return name end
package.loaded['resources/crossbar_abilities']={}
package.loaded['resources/crossbar_spells']={}
package.loaded['player']={}
package.loaded['socket']={gettime=function() return 5 end}
config={load=function(value) return value end}
math.round=function(n) return math.floor(n+.5) end
local defaults=require('defaults')
local theme=require('theme')
local function equal(a,b,message) assert(a==b,(message or '')..': '..tostring(a)..' ~= '..tostring(b)) end
local resolutions={{960,540},{1280,720},{1600,900},{1920,1080},{2560,1440},{3840,2160}}
for _,res in ipairs(resolutions) do
 for _,scale in ipairs({.6,1,1.5}) do
  for _,count in ipairs({2,4,6}) do
   for _,alt in ipairs({false,true}) do
    screen={ui_x_res=res[1],ui_y_res=res[2]}
    defaults.iscompact=false;defaults.UseAltLayout=alt;defaults.Hotbar.Number=count
    defaults.CrossbarScale=scale;defaults.Style.OffsetX=37;defaults.Style.OffsetY=-23
    package.loaded.ui=nil
    local ui=require('ui')
    local options=theme.apply(defaults)
    options.button_layout='playstation'
    ui:setup(options,{})
    ui.public_visible=true
    ui.chooser_open=true
    ui.geometry:set_opacity(.43)
    ui.geometry.fade.active=true;ui.geometry.fade.target=1;ui.geometry.fade.started=3
    local fade=ui.geometry.fade
    local old={}
    for h,bar in ipairs(ui.hotbars) do
     old[h]={}
     for i=1,8 do
      local x,y=ui:get_slot_x(h,i),ui:get_slot_y(h,i)
      local m=ui.geometry.surfaces[bar.slot_icon[i]]
      old[h][i]={m.x,m.y,bar.slot_icon[i],x,y}
      bar.slot_recast[i]:pos(x+7,y+15);bar.slot_recast[i]:size(13,25)
      bar.slot_recast[i]:path('preserved-crop');bar.slot_recast[i]:alpha(91)
      bar.slot_text[i]:center(x+20,y+40)
      bar.slot_text[i]:text('Alias')
     end
    end
    ui:trigger_feedback(1,3)
    local before=created
    equal(ui:set_compact(true),true,'switch on')
    equal(created,before,'no new drawing objects')
    equal(ui.geometry.scale,scale,'scale')
    equal(ui.geometry.opacity,.43,'opacity')
    equal(ui.geometry.fade,fade,'fade object')
    equal(fade.started,3,'fade timing')
    equal(ui.pos_x,res[1]/2-240+37,'saved X offset')
    equal(ui.pos_y,res[2]-120-23,'saved Y offset')
    for h,bar in ipairs(ui.hotbars) do
     for i=1,8 do
      local x,y=ui:get_slot_x(h,i),ui:get_slot_y(h,i)
      local m=ui.geometry.surfaces[bar.slot_icon[i]]
      equal(bar.slot_icon[i],old[h][i][3],'surface identity')
      equal(m.x,x,'icon X');equal(m.y,y,'icon Y')
      local crop=ui.geometry.surfaces[bar.slot_recast[i]]
      equal(crop.x,x+7,'crop offset X');equal(crop.y,y+15,'crop offset Y')
      equal(crop.width,13,'crop width');equal(crop.height,25,'crop height')
      equal(crop.alpha,91,'crop alpha');equal(bar.slot_recast[i]:path(),'preserved-crop','crop artwork')
      equal(ui.geometry.surfaces[bar.slot_text[i]].center_y,y+40,'label center')
     end
    end
    local anchorX,anchorBottom=ui:get_set_chooser_anchor()
    local hint=ui.geometry.surfaces[ui.environment_selector_icon]
    local rect=ui.geometry:rect(hint.x,hint.y,40,40)
    equal(anchorX,rect.x,'chooser X');equal(anchorBottom,rect.y+rect.height,'chooser Y')
    equal(ui:set_compact(true),false,'idempotent on')
    equal(ui:set_compact(false),true,'switch off')
    equal(created,before,'repeated toggle allocation')
    for h,bar in ipairs(ui.hotbars) do
     for i=1,8 do
      local m=ui.geometry.surfaces[bar.slot_icon[i]]
      equal(m.x,old[h][i][1],'return X');equal(m.y,old[h][i][2],'return Y')
     end
    end
    equal(ui.environment_selector_text:visible(),false,'chooser-open hint stays hidden')
    ui.public_visible=false;ui:set_compact(true);ui:set_compact(false)
    equal(ui.action_binder_icon:visible(),false,'hidden bar stays hidden')
    cases=cases+1
   end
  end
 end
end
print(cases..' compact layout scenarios passed across six resolutions and three scales.')
