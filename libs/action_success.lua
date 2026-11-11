-- A: one requested action, followed by an observed result. Never infer success
-- from send_command, recast changes, or another actor's action packet.
local M={}; M.__index=M
local function key(s)return tostring(s or ''):lower():gsub('[^%w]','')end
local function find(rows,name)
    for id,row in pairs(rows or {})do
        if key(row.en or row.name)==key(name) then return row.id or id end
    end
end
function M.new(options)return setmetatable({options=options},M)end
function M:cancel()self.pending=nil end
function M:request(action,before,bar,slot,context)
    self:cancel()
    if not action then return end
    local o=self.options
    action=o.resolve(action,before) or action
    local p={bar=bar,slot=slot,context=context,actor=before.player and before.player.id,
        before=before,expires=o.clock()+3}
    local name=key(action.action)
    if action.trust_dismiss then
        p.kind,p.trust='return',key((action.action:match('^refa "(.-)"$') or action.trust_spell_name):gsub('%s*%(UC%)',''))
    elseif action.type=='a' then
        p.kind='engage'
        p.engaged=name=='on' or (name~='off' and not before.engaged)
        if before.engaged==p.engaged then return end
    elseif (action.type=='pet' or action.type=='ja') and name=='release' then
        if not before.pet then return end
        p.kind='release'
        p.id=find(o.resources.job_abilities,'Release')
    elseif action.type=='pet' and (name=='assault' or name=='retreat') then
        p.kind,p.engaged='pet',name=='assault'
        if before.pet_engaged==p.engaged then return end
    else
        local rows,category
        if action.type=='ma' then rows,category=o.resources.spells,4
        elseif action.type=='ws' then rows,category=o.resources.weapon_skills,3
        elseif action.type=='ja' then rows,category=o.resources.job_abilities,6
        end
        if not rows then return end
        p.id=find(rows,action.action);if not p.id then return end
        p.kind,p.category='action',category
    end
    self.pending=p
end
function M:current()
    local p=self.pending
    if p and (self.options.clock()>p.expires or self.options.context()~=p.context) then self:cancel();return end
    return p
end
function M:finish(p)
    self:cancel()
    self.options.emit(p.bar,p.slot)
end
function M:action(act)
    local p=self:current()
    if not p or act.actor_id~=p.actor then return end
    if act.category==8 and act.param==28787 then self:cancel();return end
    if act.category==8 and p.category==4 then
        local target=act.targets and act.targets[1]
        local cast=target and target.actions and target.actions[1]
        if cast and cast.param then
            if cast.param~=p.id then self:cancel();return end
            p.expires=self.options.clock()+30
        end
    end
    if p.kind=='release' and p.id and act.category==6 and act.param==p.id then self:finish(p);return end
    if p.kind=='action' and (act.category==p.category or p.category==6 and (act.category==14 or act.category==15)) then
        if act.param==p.id then self:finish(p)
        else self:cancel() end
    end
end
function M:tick(state)
    local p=self:current();if not p then return end
    if not state.player or state.player.id~=p.actor then self:cancel();return end
    local done=p.kind=='engage' and state.engaged==p.engaged
        or p.kind=='release' and not state.pet
        or p.kind=='pet' and state.pet_id==p.before.pet_id and state.pet_engaged==p.engaged and state.pet
        or p.kind=='return' and p.before.trust.trusts[p.trust] and not state.trust.trusts[p.trust]
    if done then self:finish(p) end
end
return M
