local mod = get_mod("VersusMode")
local definitions

VersusModeSpawnView = class("VersusModeSpawnView", "BaseView")

VersusModeSpawnView.init = function(self, settings)
    definitions = mod._view_definitions.versus_mode_spawn_view
    VersusModeSpawnView.super.init(self, definitions, settings)
end

VersusModeSpawnView.on_enter = function(self)
    VersusModeSpawnView.super.on_enter(self)
    self._choices = mod.spawn_picker_choices()
    local available = {}
    for i, entry in ipairs(self._choices) do
        if mod.spawn_picker_cooldown(entry) == 0 then available[#available + 1] = i end
    end
    self._selected = #available > 0 and available[math.random(#available)] or nil
    self._heartbeat_at = 0
    self._hovered = nil
    self._selection_submitted = false
    self._pending_choice = nil
    self._pending_elapsed = 0
    local widgets = self._widgets_by_name
    widgets.title.content.text = mod:localize("spawn_picker_title")
    widgets.hint.content.text = mod:localize("spawn_picker_hint")
    widgets.cancel.content.text = mod:localize("spawn_picker_cancel")
    widgets.cancel.content.hotspot.pressed_callback = callback(self, "cb_close")
    if mod.training_available() then
        widgets.hint.content.text = mod:localize("training_picker_hint")
        widgets.cancel.content.text = mod:localize("training_return")
        widgets.cancel.content.hotspot.pressed_callback = callback(self, "cb_training_return")
    end
    for i = 1, definitions.max_cards do
        local widget = widgets["enemy_" .. i]
        local entry = self._choices[i]
        widget.content.visible = entry ~= nil
        widget.content.hotspot.disabled = entry == nil or mod.spawn_picker_cooldown(entry) > 0
        widget.content.text = entry and entry.label or ""
        widget.content.portrait = entry and entry.portrait or widget.content.portrait
        widget.content.portrait_breed = entry and entry.portrait_breed
        -- Capture this card's identity, never the changing hover selection.
        local card_choice = entry
        widget.content.hotspot.pressed_callback = function()
            self:cb_choose_entry(card_choice)
        end
    end
    mod.spawn_picker_hold(true)
end

VersusModeSpawnView.cb_choose_entry = function(self, entry)
    if not entry or self._selection_submitted or mod.spawn_picker_cooldown(entry) > 0 then
        return
    end
    self._selection_submitted = true
    if mod.spawn_picker_select(entry) then
        self._pending_choice = { name = entry.name, variant_id = entry.variant_id }
        self._pending_elapsed = 0
        self._widgets_by_name.hint.content.text = mod:localize("spawn_picker_pending", entry.label)
    else
        self._selection_submitted = false
        self._widgets_by_name.hint.content.text = mod:localize("spawn_picker_failed")
    end
end

VersusModeSpawnView.cb_close = function(self)
    Managers.ui:close_view(self.view_name)
end

VersusModeSpawnView.cb_training_return = function(self)
    mod.training_return()
    self:cb_close()
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
    if self._pending_choice then
        if mod.spawn_picker_matches(self._pending_choice) then
            self._pending_choice = nil
            self:cb_close()
            return pass_input, pass_draw
        end
        self._pending_elapsed = self._pending_elapsed + dt
        if self._pending_elapsed >= 5 then
            self._pending_choice = nil
            self._selection_submitted = false
            self._widgets_by_name.hint.content.text = mod:localize("spawn_picker_unconfirmed")
        end
    end
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
        if self._widgets_by_name["enemy_" .. i].content.hotspot.is_hover
            and mod.spawn_picker_cooldown(self._choices[i]) == 0 then
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
        local remaining = mod.spawn_picker_cooldown(self._choices[i])
        local blocked = remaining > 0
        widget.content.hotspot.disabled = blocked or self._selection_submitted
        widget.content.cooldown = blocked and mod:localize("spawn_picker_cooldown", math.ceil(remaining))
            or mod:localize("spawn_picker_ready")
        widget.style.cooldown.text_color = blocked and { 255, 255, 130, 100 } or { 255, 155, 235, 115 }
        local selected = i == self._selected
        widget.style.background.color = blocked and { 230, 55, 30, 30 }
            or selected and { 245, 63, 93, 53 } or { 230, 31, 43, 40 }
        widget.style.frame.color = selected and { 255, 155, 235, 115 } or { 255, 83, 105, 87 }
    end
    return pass_input, pass_draw
end

return VersusModeSpawnView
