local mod = get_mod("VersusMode")
local definitions = mod:io_dofile("VersusMode/scripts/mods/VersusMode/ui/versus_spawn_view_definitions")

VersusModeSpawnView = class("VersusModeSpawnView", "BaseView")

VersusModeSpawnView.init = function(self, settings)
    VersusModeSpawnView.super.init(self, definitions, settings)
end

VersusModeSpawnView.on_enter = function(self)
    VersusModeSpawnView.super.on_enter(self)
    self._choices = mod.spawn_picker_choices()
    self._selected = #self._choices > 0 and math.random(#self._choices) or nil
    self._heartbeat_at = 0
    self._hovered = nil
    local widgets = self._widgets_by_name
    widgets.title.content.text = mod:localize("spawn_picker_title")
    widgets.hint.content.text = mod:localize("spawn_picker_hint")
    widgets.confirm.content.text = mod:localize("spawn_picker_confirm")
    widgets.cancel.content.text = mod:localize("spawn_picker_cancel")
    widgets.confirm.content.hotspot.pressed_callback = callback(self, "cb_confirm")
    widgets.cancel.content.hotspot.pressed_callback = callback(self, "cb_close")
    widgets.confirm.content.hotspot.disabled = self._selected == nil
    for i = 1, 8 do
        local widget = widgets["enemy_" .. i]
        local entry = self._choices[i]
        widget.content.visible = entry ~= nil
        widget.content.hotspot.disabled = entry == nil
        widget.content.text = entry and entry.label or ""
        widget.content.portrait = entry and entry.portrait or widget.content.portrait
        widget.content.hotspot.pressed_callback = callback(self, "cb_choose", i)
    end
    mod.spawn_picker_hold(true)
end

VersusModeSpawnView.cb_choose = function(self, index)
    if self._choices[index] then
        self._selected = index
        self:cb_confirm()
    end
end

VersusModeSpawnView.cb_confirm = function(self)
    if mod.spawn_picker_select(self._choices[self._selected]) then
        self:cb_close()
    else
        self._widgets_by_name.hint.content.text = mod:localize("spawn_picker_failed")
    end
end

VersusModeSpawnView.cb_close = function(self)
    Managers.ui:close_view(self.view_name)
end

VersusModeSpawnView._on_back_pressed = function(self)
    self:cb_close()
end

VersusModeSpawnView.on_exit = function(self)
    mod.spawn_picker_hold(false)
    VersusModeSpawnView.super.on_exit(self)
end

VersusModeSpawnView.update = function(self, dt, t, input_service)
    local pass_input, pass_draw = VersusModeSpawnView.super.update(self, dt, t, input_service)
    if not mod.spawn_picker_available() then
        self:cb_close()
        return pass_input, pass_draw
    end
    if t >= self._heartbeat_at then
        mod.spawn_picker_hold(true)
        self._heartbeat_at = t + 2
    end
    local hovered
    for i = 1, #self._choices do
        if self._widgets_by_name["enemy_" .. i].content.hotspot.is_hover then
            hovered = i
        end
    end
    -- Do not replace the random default until the mouse enters another card.
    if self._hover_initialized and hovered and hovered ~= self._hovered then
        self._selected = hovered
    end
    self._hover_initialized = true
    self._hovered = hovered
    for i = 1, #self._choices do
        local widget = self._widgets_by_name["enemy_" .. i]
        local selected = i == self._selected
        widget.style.background.color = selected and { 245, 63, 93, 53 } or { 230, 31, 43, 40 }
        widget.style.frame.color = selected and { 255, 155, 235, 115 } or { 255, 83, 105, 87 }
    end
    return pass_input, pass_draw
end

return VersusModeSpawnView
