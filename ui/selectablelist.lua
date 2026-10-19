local ui_resources = require('ui/resources')
require("lists")
require("tables")
texts = require('texts')
images = require('images')

local selectable_list = {}
local unpack = unpack or table.unpack

local BORDER_PADDING = 10
local COLUMN_WIDTH = 180
local ROW_HEIGHT = 50
local page_assets = 'images/assets/menu/'

function selectable_list:setup(theme_options, base_x, base_y, max_width, max_height)
    ui_resources.clear(self.fields); ui_resources.clear(self.images)
    self.theme_options = theme_options
    self.frame_image_path = windower.addon_path..'/images/themes/' .. (theme_options.frame_theme:lower()) .. '/frame.png'
    self.base_x = base_x or 150
    self.base_y = base_y or 150
    local temp_width = max_width or (windower.get_windower_settings().ui_x_res - 300)
    local temp_height = max_height or (windower.get_windower_settings().ui_y_res - 300)
    -- Never produce a zero-capacity page (division/paging failures at small UI
    -- resolutions); four columns keep the existing labels from crowding rows.
    self.max_row = math.max(1, math.floor((temp_height - 2 * BORDER_PADDING) / ROW_HEIGHT))
    self.max_col = math.max(1, math.min(4, math.floor((temp_width - 2 * BORDER_PADDING) / COLUMN_WIDTH)))
    self.width = 2 * BORDER_PADDING + self.max_col * COLUMN_WIDTH
    self.height = 2 * BORDER_PADDING + self.max_row * ROW_HEIGHT
    self.normal_max_row,self.normal_max_col=self.max_row,self.max_col
    self.normal_base_x=self.base_x
    self.fields = L{}
    self.field_coords = {}
    self.selected_row = 1
    self.selected_col = 1
    self.images = L{}
    self.current_page = 1
    self.is_prev_button_showing = false
    self.is_next_button_showing = false

    windower.prim.create('selectablelist_selection_highlight')
    windower.prim.set_color('selectablelist_selection_highlight', 150, 101, 70, 41)
    windower.prim.set_position('selectablelist_selection_highlight', 0, 0)
    windower.prim.set_size('selectablelist_selection_highlight', COLUMN_WIDTH, ROW_HEIGHT)
    windower.prim.set_visibility('selectablelist_selection_highlight', false)

    windower.prim.create('prev_page_button')
    windower.prim.set_color('prev_page_button', 200, 0, 0, 0)
    windower.prim.set_position('prev_page_button', 0, 0)
    windower.prim.set_size('prev_page_button', COLUMN_WIDTH, ROW_HEIGHT)
    windower.prim.set_visibility('prev_page_button', false)

    windower.prim.create('next_page_button')
    windower.prim.set_color('next_page_button', 200, 0, 0, 0)
    windower.prim.set_position('next_page_button', 0, 0)
    windower.prim.set_size('next_page_button', COLUMN_WIDTH, ROW_HEIGHT)
    windower.prim.set_visibility('next_page_button', false)
    if self.cursor then self.cursor:destroy() end
    self.cursor = require('ui/animated_cursor').new(windower.addon_path .. page_assets .. 'cursor',
        {clock=require('socket').gettime or os.clock})
    if self.page_backgrounds then
        for _, object in pairs(self.page_backgrounds) do object:destroy() end
        for _, object in pairs(self.page_trigger_icons) do object:destroy() end
    end
    self.page_backgrounds, self.page_trigger_icons = {}, {}
    for _, direction in ipairs({'prev','next'}) do
        local bg = ui_resources.image({draggable=false})
        setup_image(bg, windower.addon_path .. page_assets .. 'page-button.png')
        bg:size(COLUMN_WIDTH,ROW_HEIGHT); bg:hide(); self.page_backgrounds[direction]=bg
        local icon = ui_resources.image({draggable=false})
        setup_image(icon, windower.addon_path .. page_assets .. (direction=='prev' and 'L2' or 'R2') .. '.png')
        icon:size(28,28); icon:hide(); self.page_trigger_icons[direction]=icon
    end
end

function selectable_list:reset_state()
    self.is_showing = false
    self.option_objects = {}
    if self.cursor then self.cursor:hide() end
    if self.page_backgrounds then
        for _,object in pairs(self.page_backgrounds) do object:hide() end
        for _,object in pairs(self.page_trigger_icons) do object:hide() end
    end
    self.current_page = 1
    self.current_options = L{}
    windower.prim.set_visibility('prev_page_button', false)
    windower.prim.set_visibility('next_page_button', false)
    for index, field in ipairs(self.fields) do
        field:destroy()
    end
    for index, image in ipairs(self.images) do
        image:destroy()
    end
    self.fields = L{}
    self.images = L{}
    self.field_coords = {}
    self.selected_row = 1
    self.selected_col = 1
end

function selectable_list:export_selection_state()
    return {page = self.current_page, row = self.selected_row, col = self.selected_col}
end

function selectable_list:import_selection_state(selection_state)
    self.current_page = selection_state.page
    self.selected_row = selection_state.row
    self.selected_col = selection_state.col
    self:highlight_selection()
end

function selectable_list:set_page(page)
    self.current_page = page
end

function selectable_list:turn_page(delta)
    local page=self.current_page+delta
    if page<1 or page>math.max(1,math.ceil(#self.current_options/(self.max_row*self.max_col))) then return end
    local row,col=self.selected_row,self.selected_col
    self.current_page=page;self:display_options(self.current_options)
    if row<=self.max_row then
        local distance=math.huge
        for r=1,self.max_row do
            for c=1,self.max_col do
                local d=math.abs(r-row)+math.abs(c-col)
                if self:is_valid_row_col(r,c) and d<distance then
                    distance=d;self.selected_row,self.selected_col=r,c
                end
            end
        end
    elseif delta>0 then
        self.selected_row,self.selected_col=self.max_row+1,self.is_next_button_showing and self.max_col or 1
    else self.selected_row,self.selected_col=self.max_row+1,self.is_prev_button_showing and 1 or self.max_col end
    self:highlight_selection()
end
function selectable_list:increment_page() self:turn_page(1) end
function selectable_list:decrement_page() self:turn_page(-1) end

function selectable_list:move_selection(dr, dc)
    local row, col = self.selected_row + dr, self.selected_col + dc
    while row >= 1 and row <= self.max_row+1 and col >= 1 and col <= self.max_col do
        if self:is_valid_row_col(row,col) then
            self.selected_row,self.selected_col=row,col
            self:highlight_selection(); return
        end
        row,col=row+dr,col+dc
    end
end

function selectable_list:increment_row() self:move_selection(1,0) end
function selectable_list:decrement_row() self:move_selection(-1,0) end
function selectable_list:increment_col() self:move_selection(0,1) end
function selectable_list:decrement_col() self:move_selection(0,-1) end

function selectable_list:hide()
    self.is_showing = false
    if self.cursor then self.cursor:hide() end
    self:page_highlight(nil)
    if self.page_backgrounds then
        for _,object in pairs(self.page_backgrounds) do object:hide() end
        for _,object in pairs(self.page_trigger_icons) do object:hide() end
    end
    windower.prim.set_visibility('selectablelist_selection_highlight', false)
    windower.prim.set_visibility('prev_page_button', false)
    windower.prim.set_visibility('next_page_button', false)
    for index, field in ipairs(self.fields) do
        field:hide()
    end
    for index, image in ipairs(self.images) do
        image:hide()
    end
end

function selectable_list:show()
end

function selectable_list:create_text(text_string, row, col)
    local text = ui_resources.text({flags = {draggable = false}})
    require('ui/render_trace').track(text,nil,'selector','caption')
    text:bg_alpha(0)
    text:bg_visible(false)
    text:font(self.theme_options.font)
    text:size(self.theme_options.font_size + 2)
    text:color(self.theme_options.font_color_red, self.theme_options.font_color_green, self.theme_options.font_color_blue)
    text:stroke_alpha(self.theme_options.font_stroke_alpha)
    text:stroke_color(self.theme_options.font_stroke_color_red, self.theme_options.font_stroke_color_green, self.theme_options.font_stroke_color_blue)
    text:stroke_width(self.theme_options.font_stroke_width)

    local x, y = self:get_pos(row, col)
    text:pos(x + 50, y + 18)
    text:text(text_string)
    text:show()
    return text
end

function selectable_list:highlight_selection()
    local x,y=self:get_pos(self.selected_row,self.selected_col)
    local selected=self:get_selected_option()
    local unavailable = selected and selected.disabled
    windower.prim.set_color('selectablelist_selection_highlight', unavailable and 110 or 150, unavailable and 96 or 101, unavailable and 20 or 70, unavailable and 28 or 41)
    windower.prim.set_position('selectablelist_selection_highlight',x-(unavailable and 0 or 2),y-(unavailable and 0 or 2))
    windower.prim.set_visibility('selectablelist_selection_highlight', selected~=nil and selected.id~='PREV' and selected.id~='NEXT')
    for _,entry in ipairs(self.option_objects or {}) do
        local active=entry.row==self.selected_row and entry.col==self.selected_col
        local lifted=active and not entry.disabled
        for _,object in ipairs(entry.objects) do
            object.ref:pos(object.x+(lifted and -2 or 0),object.y+(lifted and -2 or 0))
        end
        if entry.caption then
            if entry.disabled then entry.caption:color(255,149,151)
            elseif active then entry.caption:color(255,216,112)
            else entry.caption:color(self.theme_options.font_color_red,self.theme_options.font_color_green,self.theme_options.font_color_blue) end
        end
    end
    if self.cursor then
        if selected and not selected.disabled then self.cursor:pos(x-30,y+13);self.cursor:show()
        else self.cursor:hide() end
    end
    self:update_page_colors()
end

function selectable_list:page_highlight(direction)
    if self.page_pressed_direction==direction then return end
    self.page_pressed_direction=direction;self.page_color_frame=0
    self:update_page_colors()
end

function selectable_list:update_page_colors()
    local entry=self:get_selected_option()
    for _,direction in ipairs({'prev','next'}) do
        local active=self.page_pressed_direction~=nil and (self.page_pressed_direction and 'next' or 'prev')==direction
        local selected=entry and entry.id==(direction=='prev' and 'PREV' or 'NEXT')
        local rgb={57,57,83}
        if active or selected then rgb=(self.page_color_frame or 0)==0 and {101,70,41} or {132,87,48} end
        if self.page_backgrounds then self.page_backgrounds[direction]:color(unpack(rgb)) end
        local caption=self.page_captions and self.page_captions[direction]
        if caption then
            if active or selected then caption:color(255,216,112)
            else caption:color(self.theme_options.font_color_red,self.theme_options.font_color_green,self.theme_options.font_color_blue) end
        end
    end
end

function selectable_list:draw_page_button(direction,row,col)
    local x,y=self:get_pos(row,col)
    windower.prim.set_visibility(direction .. '_page_button',false)
    local bg,icon=self.page_backgrounds[direction],self.page_trigger_icons[direction]
    bg:pos(x,y);bg:show();icon:pos(x+4,y+11);icon:show()
    local text=self:create_text(direction=='prev' and 'Previous Page' or 'Next Page',row,col)
    self.fields:append(text);self.page_captions[direction]=text
    self.option_objects[#self.option_objects+1]={row=row,col=col,objects={
        {ref=bg,x=x,y=y},{ref=icon,x=x+4,y=y+11},{ref=text,x=x+50,y=y+18}}}
end

function selectable_list:draw_prev_page_button(row,col) self:draw_page_button('prev',row,col) end
function selectable_list:draw_next_page_button(row,col) self:draw_page_button('next',row,col) end

function selectable_list:get_pos(row, col)
    local x = self.base_x + BORDER_PADDING + (col - 1) * COLUMN_WIDTH
    local y = self.base_y + BORDER_PADDING + (row - 1) * ROW_HEIGHT
    return x, y
end

function selectable_list:get_row_col_from_pos(x, y)
    local row = math.floor((y - (self.base_y + BORDER_PADDING)) / ROW_HEIGHT) + 1
    local col = math.floor((x - (self.base_x + BORDER_PADDING)) / COLUMN_WIDTH) + 1
    return row, col
end

function selectable_list:get_row_col(index)
    local row = math.ceil((index + 1) / self.max_col)
    local col = (index % self.max_col) + 1
    return row, col
end

function selectable_list:display_options(options, presentation)
    self.max_row,self.max_col=self.normal_max_row,self.normal_max_col
    self.base_x=self.normal_base_x
    if presentation == 'review' then
        self.max_row,self.max_col=3,3
        self.base_x=self.review_base_x or self.base_x
    end
    self.width=2*BORDER_PADDING+self.max_col*COLUMN_WIDTH
    self.height=2*BORDER_PADDING+self.max_row*ROW_HEIGHT
    -- A shorter child list (for example spell targets) cannot inherit a page
    -- beyond its contents. Keep valid pages for page turns and explicit Back.
    local last_page=math.max(1,math.ceil(#options/(self.max_row*self.max_col)))
    local current_page=math.max(1,math.min(self.current_page,last_page))
    self:reset_state()
    self.is_showing = true
    self.page_captions = {}
    self.current_options = options
    self.current_page = current_page
    local first_row = (self.current_page - 1) * self.max_row + 1
    local last_row = self.current_page * self.max_row
    local entries_to_skip = (self.current_page - 1) * self.max_row * self.max_col + 1

    local newlines = 0
    local col_offset = 0

    local count = 0
    for i, value in ipairs(options) do
        count = count + 1
        local option_id = value.id
        local option_caption = value.name

        local data = value.data

        local abs_row, abs_col = self:get_row_col(i - 1)
        if (first_row <= abs_row and abs_row <= last_row) then
            local row, col = self:get_row_col(i - entries_to_skip)
            row = row + newlines
            if (option_caption == 'newline') then
                newlines = newlines + 1
                col_offset = col % self.max_col
            else
                col = col - col_offset
                if (row == self.selected_row and col == self.selected_col) then
                    self:highlight_selection()
                end
                local caption=self:create_text(option_caption,row,col)
                self.fields:append(caption)

                local icon = ui_resources.image({draggable = false})
                local icon_path = windower.addon_path .. value.icon
                local x, y = self:get_pos(row, col)
                x = x + 5
                y = y + 5
                setup_image(icon, icon_path)
                local icon_offset = value.icon_offset or 0
                icon:pos(x + icon_offset, y + icon_offset)
                self.images:append(icon)

                local frame = ui_resources.image({draggable = false})
                setup_image(frame, self.frame_image_path)
                frame:pos(x, y)
                self.images:append(frame)
                local tx,ty=self:get_pos(row,col)
                self.option_objects[#self.option_objects+1]={row=row,col=col,caption=caption,disabled=value.disabled,objects={
                    {ref=caption,x=tx+50,y=ty+18},{ref=icon,x=x+icon_offset,y=y+icon_offset},{ref=frame,x=x,y=y}}}

                -- populate the "collision" map for dpad navigation
                local field_col = self.field_coords[col] or {}
                field_col[row] = {id=option_id, text=option_caption, data=data,
                    icon=data and data.icon_path or value.name, disabled=value.disabled, disabled_focusable=value.disabled_focusable}
                if value.disabled then
                    self.fields[#self.fields]:color(255,149,151)
                    icon:alpha(90); frame:alpha(90)
                end
                self.field_coords[col] = field_col
            end
        end
    end

    if (count > self.current_page * self.max_row * self.max_col) then
        self.is_next_button_showing = true
        local row = self.max_row + 1
        local col = self.max_col

        self:draw_next_page_button(row,col)

        -- populate the "collision" map for dpad navigation
        local field_col = self.field_coords[self.max_col] or {}
        field_col[row] = {['id'] = 'NEXT', ['text'] = 'Next Page'}
        self.field_coords[col] = field_col
    else
        self.is_next_button_showing = false
    end

    if (self.current_page > 1) then
        self.is_prev_button_showing = true
        local row = self.max_row + 1
        local col = 1

        self:draw_prev_page_button(row,col)

        -- populate the "collision" map for dpad navigation
        local field_col = self.field_coords[col] or {}
        field_col[row] = {['id'] = 'PREV', ['text'] = 'Previous Page'}
        self.field_coords[col] = field_col
    else
        self.is_prev_button_showing = false
    end
    if not self:is_valid_row_col(self.selected_row,self.selected_col) then
        for row=1,self.max_row+1 do
            for col=1,self.max_col do
                if self:is_valid_row_col(row,col) then
                    self.selected_row,self.selected_col=row,col
                    self:highlight_selection(); return
                end
            end
        end
        windower.prim.set_visibility('selectablelist_selection_highlight',false)
    end
    self:highlight_selection()
end

function selectable_list:get_selected_option()
    local column = self.field_coords[self.selected_col]
    return column and column[self.selected_row]
end

function selectable_list:submit_selected_option()
    local option = self:get_selected_option()
    -- The caller owns transitions; validation must not destroy a visible list.
    if not option or option.disabled then return {id='DISABLED'} end
    return option
end

function selectable_list:is_valid_row_col(row, col)
    local column = self.field_coords and self.field_coords[col]
    local option = column and column[row]
    return option ~= nil and (not option.disabled or option.disabled_focusable == true)
end

function setup_image(image, path)
    image:path(path)
    image:repeat_xy(1, 1)
    image:draggable(false)
    image:fit(true)
    image:alpha(255)
    image:show()
end

windower.register_event('mouse', function(type, x, y, delta, blocked)
    if blocked then
        return
    end

    if (selectable_list.is_showing and not selectable_list.suspended) then
        -- Mouse drag (0) or left click (1)
        if (type == 0 or type == 1) then
            local row, col = selectable_list:get_row_col_from_pos(x, y)
            if (selectable_list:is_valid_row_col(row, col)) then
                selectable_list.selected_row = row
                selectable_list.selected_col = col
                selectable_list:highlight_selection()
                return true
            end
        -- Mouse left release
        elseif type == 2 then
        end
    end
end)

windower.register_event('prerender',function()
    if selectable_list.is_showing then
        if selectable_list.cursor then selectable_list.cursor:update() end
        if selectable_list.page_pressed_direction~=nil and (selectable_list.page_color_frame or 0)<1 then
            selectable_list.page_color_frame=1;selectable_list:update_page_colors()
        end
    end
end)
windower.register_event('unload',function()
    if selectable_list.cursor then selectable_list.cursor:destroy() end
    for _,group in ipairs({selectable_list.page_backgrounds or {},selectable_list.page_trigger_icons or {}}) do
        for _,object in pairs(group) do object:destroy() end
    end
end)
return selectable_list
