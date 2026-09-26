local mod = get_mod("VersusMode")
local definitions = mod:io_dofile("VersusMode/scripts/mods/VersusMode/ui/versus_roster_view_definitions")

VersusModeRosterView = class("VersusModeRosterView", "BaseView")

local SELECTED_BACKGROUND = { 235, 63, 83, 53 }
local NORMAL_BACKGROUND = { 220, 31, 43, 40 }
local HOVER_BACKGROUND = { 235, 48, 61, 51 }
local SELECTED_FRAME = { 255, 135, 207, 108 }
local NORMAL_FRAME = { 210, 83, 105, 87 }
local ERROR_COLOR = { 255, 255, 105, 90 }
local READY_COLOR = { 255, 120, 235, 145 }
local NORMAL_COLOR = { 255, 200, 207, 195 }

VersusModeRosterView.init = function(self, settings)
    VersusModeRosterView.super.init(self, definitions, settings)
end

VersusModeRosterView.on_enter = function(self)
    VersusModeRosterView.super.on_enter(self)

    self._lobby_mode = mod.infected_lobby_planning_active and mod.infected_lobby_planning_active() or false
    self._selected = {}
    self._roster = {}
    self._refresh_at = 0

    for i = 1, definitions.max_rows do
        local widget = self._widgets_by_name["row_" .. i]

        widget.content.hotspot.pressed_callback = callback(self, "cb_toggle_row", i)
    end

    self._widgets_by_name.apply_button.content.hotspot.pressed_callback = callback(self, "cb_apply")
    self._widgets_by_name.clear_button.content.hotspot.pressed_callback = callback(self, "cb_restore_all")
    self._widgets_by_name.close_button.content.hotspot.pressed_callback = callback(self, "cb_close")

    self._widgets_by_name.title.content.text = mod:localize(
        self._lobby_mode and "infected_lobby_title" or "versus_roster_title"
    )
    self._widgets_by_name.subtitle.content.text = mod:localize(
        self._lobby_mode and "infected_lobby_subtitle" or "versus_roster_subtitle"
    )
    self._widgets_by_name.apply_button.content.text = mod:localize(
        self._lobby_mode and "infected_lobby_save" or "versus_roster_apply"
    )
    self._widgets_by_name.clear_button.content.text = mod:localize(
        self._lobby_mode and "infected_lobby_clear" or "versus_roster_restore_all"
    )
    self._widgets_by_name.close_button.content.text = mod:localize("versus_roster_close")

    self:_refresh_roster(true)
end

VersusModeRosterView._selected_count = function(self)
    local count = 0

    for _, selected in pairs(self._selected) do
        if selected then
            count = count + 1
        end
    end

    return count
end

VersusModeRosterView._set_status = function(self, text, kind)
    local widget = self._widgets_by_name.status

    widget.content.text = text or ""
    widget.style.text.text_color = kind == "error" and ERROR_COLOR or kind == "ready" and READY_COLOR or NORMAL_COLOR
end

VersusModeRosterView._refresh_row_styles = function(self)
    for i = 1, definitions.max_rows do
        local widget = self._widgets_by_name["row_" .. i]
        local content = widget.content

        if content.visible then
            local selected = self._selected[content.token] == true
            local hovered = content.hotspot.is_hover == true

            content.text = string.format("%s  %s    —    %s", selected and "[X]" or "[ ]", content.player_name, content.player_kind)
            widget.style.background.color = content.selectable == false and { 210, 38, 38, 38 }
                or selected and SELECTED_BACKGROUND
                or hovered and HOVER_BACKGROUND
                or NORMAL_BACKGROUND
            widget.style.frame.color = selected and SELECTED_FRAME or NORMAL_FRAME
            widget.style.text.text_color = content.selectable == false and { 255, 145, 145, 140 } or NORMAL_COLOR
        end
    end

    local selected_count = self:_selected_count()
    local count_widget = self._widgets_by_name.selection_count
    local all_players_selected = #self._roster > 0 and selected_count >= #self._roster

    count_widget.content.text = mod:localize("versus_roster_selected_count", selected_count)
    count_widget.style.text.text_color = all_players_selected and ERROR_COLOR or READY_COLOR
end

VersusModeRosterView._refresh_roster = function(self, reset_selection)
    local roster = self._lobby_mode
        and mod.infected_lobby_snapshot
        and mod.infected_lobby_snapshot()
        or mod.versus_roster_snapshot and mod.versus_roster_snapshot()
        or {}
    local present = {}

    self._roster = roster

    for i = 1, #roster do
        present[roster[i].token] = true
    end

    if reset_selection then
        table.clear(self._selected)

        for i = 1, #roster do
            self._selected[roster[i].token] = roster[i].infected == true
        end
    else
        for token in pairs(self._selected) do
            if not present[token] then
                self._selected[token] = nil
            end
        end
    end

    for i = 1, definitions.max_rows do
        local widget = self._widgets_by_name["row_" .. i]
        local entry = roster[i]

        widget.content.visible = entry ~= nil
        widget.content.hotspot.disabled = entry == nil or entry.selectable == false
        widget.content.token = entry and entry.token or nil
        widget.content.player_name = entry and entry.name or ""
        widget.content.player_kind = entry and entry.kind or ""
        widget.content.selectable = entry and entry.selectable ~= false or false
    end

    if self._lobby_mode and mod.infected_lobby_plan_locked and mod.infected_lobby_plan_locked() then
        self:_set_status(mod:localize("infected_lobby_error_locked"), "error")
    elseif #roster == 0 then
        self:_set_status(mod:localize(
            self._lobby_mode and "infected_lobby_no_players" or "versus_roster_no_candidates"
        ), "error")
    end

    self:_refresh_row_styles()
end

VersusModeRosterView.cb_toggle_row = function(self, index)
    local widget = self._widgets_by_name["row_" .. index]
    local token = widget.content.token

    if not token or widget.content.selectable == false then
        self:_set_status(mod:localize("versus_roster_client_not_ready"), "error")

        return
    end

    if not self._selected[token] and self:_selected_count() + 1 >= #self._roster then
        self:_set_status(mod:localize("versus_roster_error_survivor_required"), "error")

        return
    end

    self._selected[token] = not self._selected[token]
    self:_set_status(mod:localize(
        self._lobby_mode and "infected_lobby_selection_changed" or "versus_roster_selection_changed"
    ))
    self:_refresh_row_styles()
end

VersusModeRosterView.cb_apply = function(self)
    local applied, message

    if self._lobby_mode then
        applied, message = mod.apply_infected_lobby_selection(self._selected)
    else
        applied, message = mod.apply_versus_roster_selection(self._selected)
    end

    self:_set_status(message, applied and "ready" or "error")

    if applied and self._lobby_mode then
        -- The saved plan is now host-owned. Closing the planner prevents its
        -- half-second roster refresh from observing Realms' transient loading
        -- rows and treating selected peers as departures.
        self:cb_close()

        return
    end

    self:_refresh_roster(applied)
end

VersusModeRosterView.cb_restore_all = function(self)
    local restored, message

    if self._lobby_mode then
        restored, message = mod.clear_infected_lobby_selection()
    else
        restored, message = mod.clear_versus_roster()
    end

    self:_set_status(message, restored and "ready" or "error")
    self:_refresh_roster(restored)
end

VersusModeRosterView.cb_close = function(self)
    Managers.ui:close_view(self.view_name)
end

VersusModeRosterView._on_back_pressed = function(self)
    self:cb_close()
end

VersusModeRosterView.update = function(self, dt, t, input_service)
    local pass_input, pass_draw = VersusModeRosterView.super.update(self, dt, t, input_service)

    if t >= self._refresh_at then
        self._refresh_at = t + 0.5
        self:_refresh_roster(false)
    else
        self:_refresh_row_styles()
    end

    return pass_input, pass_draw
end

return VersusModeRosterView
