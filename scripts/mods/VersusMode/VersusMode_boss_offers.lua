-- Host-owned reservations. UI replies never select a unit supplied by a client.
return function(env)
    local offers = { serial = 0 }

    function offers:close_local()
        if self.popup_id ~= nil and Managers.event then
            Managers.event:trigger("event_remove_ui_popup", self.popup_id)
        end
        self.popup_id = nil
        self.local_offer = nil
    end

    function offers:receive(payload)
        if payload.kind == "boss_offer_cancel" then
            if type(payload.offer_id) == "number" then
                self.last_id = math.max(self.last_id or 0, payload.offer_id)
            end
            if self.local_offer and self.local_offer.id == payload.offer_id then self:close_local() end
            return
        end
        if type(payload.offer_id) ~= "number" or type(payload.breed) ~= "string"
            or type(payload.remaining) ~= "number" or payload.remaining <= 0
            or not env.local_eligible() then return end
        if self.last_id and payload.offer_id <= self.last_id then return end
        self:close_local()
        self.last_id = payload.offer_id
        self.local_offer = { id = payload.offer_id, until_t = env.now() + math.min(15, payload.remaining) }
        local id = payload.offer_id
        local function reply(accepted)
            if not self.local_offer or self.local_offer.id ~= id then return end
            self:close_local()
            env.reply(id, accepted)
        end
        Managers.event:trigger("event_show_ui_popup", {
            title_text_unlocalized = env.text("boss_offer_title"),
            description_text_unlocalized = env.text("boss_offer_description", env.label(payload.breed)),
            options = {
                { text = env.text("boss_offer_yes"), no_localization = true, close_on_pressed = true,
                    callback = function() reply(true) end },
                { text = env.text("boss_offer_no"), no_localization = true, close_on_pressed = true, hotkey = "back",
                    callback = function() reply(false) end },
            },
        }, function(id) self.popup_id = id end)
    end

    function offers:cancel()
        local active = self.active
        self.active = nil
        if active then
            env.send(active.role, { kind = "boss_offer_cancel", offer_id = active.id })
        end
    end

    function offers:reset()
        self:cancel()
        self:close_local()
        self.last_id = nil
    end

    function offers:answer(role, id, accepted)
        local active = self.active
        if not active or active.role ~= role or active.id ~= id or type(accepted) ~= "boolean" then return false end
        local valid = env.enabled() and env.now() < active.until_t
            and env.role_eligible(role) and env.boss_eligible(active.entry) and env.capacity()
        self:cancel()
        if not accepted or not valid then return false end
        -- Consume the offer before possession; repeated or simultaneous replies cannot reuse it.
        return env.possess(active.entry, role) == true
    end

    function offers:update(pending)
        if self.local_offer and (not env.local_eligible() or env.now() >= self.local_offer.until_t) then
            self:close_local()
        end
        if not env.host() then return end
        -- Cleanup must also run while disabled or at the controlled-boss cap.
        if pending then
            for unit in pairs(pending) do
                if not env.alive(unit) then pending[unit] = nil end
            end
        end
        if not env.enabled() then self:cancel(); return end
        local active = self.active
        if active then
            if not pending or pending[active.entry.unit] ~= active.entry or env.now() >= active.until_t
                or not env.role_eligible(active.role) or not env.boss_eligible(active.entry) or not env.capacity() then
                self:cancel()
            else
                -- Prevent automatic reinforcement spawning while the decision is pending.
                active.role.spawn_picker_until = env.now() + 1
                if env.now() >= active.send_at then
                    active.send_at = env.now() + 1
                    env.send(active.role, { kind = "boss_offer", offer_id = active.id,
                        breed = active.entry.breed.name, remaining = active.until_t - env.now() })
                end
                return
            end
        end
        if not pending or not env.capacity() then return end
        local selected, recipient
        for unit, entry in pairs(pending) do
            if not env.alive(unit) then
                pending[unit] = nil
            elseif env.boss_eligible(entry) then
                entry.offered_roles = entry.offered_roles or setmetatable({}, { __mode = "k" })
                for _, role in pairs(env.roles()) do
                    if not entry.offered_roles[role] and env.role_eligible(role)
                        and (not selected or entry.queued_at < selected.queued_at) then
                        selected, recipient = entry, role
                    end
                end
            end
        end
        if selected then
            selected.offered_roles[recipient] = true
            self.serial = self.serial + 1
            self.active = { id = self.serial, entry = selected, role = recipient,
                until_t = env.now() + 15, send_at = env.now() + 1 }
            recipient.spawn_picker_until = env.now() + 1
            env.send(recipient, { kind = "boss_offer", offer_id = self.serial,
                breed = selected.breed.name, remaining = 15 })
        end
    end

    return offers
end
