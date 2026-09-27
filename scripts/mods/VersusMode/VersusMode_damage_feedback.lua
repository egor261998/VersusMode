-- Observe native damage returns; never change combat calculations.
return function(mod, env)
    local feedback = { events = {}, pending = {}, elapsed = 0 }
    local capture
    function feedback:time() return env.now() end
    local function amount(value)
        return type(value) == "number" and value == value and value > 0 and value < math.huge and value or 0
    end

    function feedback:receive(unit, health, toughness)
        local owner = env.local_owner()
        if not owner then return end
        if owner ~= self.owner then self.events = {}; self.owner = owner end
        local now = env.now()
        for _, item in ipairs({ { "health", amount(health) }, { "toughness", amount(toughness) } }) do
            local kind, value = item[1], item[2]
            if value > 0 then
                local merged = false
                for i = #self.events, 1, -1 do
                    local event = self.events[i]
                    if event.unit == unit and event.kind == kind and now - event.started < 0.15 then
                        event.value = event.value + value
                        merged = true
                        break
                    end
                end
                if not merged then
                    if #self.events >= 48 then table.remove(self.events, 1) end
                    self.events[#self.events + 1] = { unit = unit, kind = kind, value = value, started = now }
                end
            end
        end
    end

    function feedback:record(state, unit, health, toughness)
        health, toughness = amount(health), amount(toughness)
        if health == 0 and toughness == 0 then return end
        if env.is_local(state) then
            self:receive(unit, health, toughness)
            return
        end
        -- One packet per target per 0.1 seconds, including shotgun pellet hits.
        for _, event in ipairs(self.pending) do
            if event.state == state and event.unit == unit then
                event.health, event.toughness = event.health + health, event.toughness + toughness
                return
            end
        end
        if #self.pending >= 64 then table.remove(self.pending, 1) end
        self.pending[#self.pending + 1] = { state = state, unit = unit, health = health, toughness = toughness }
    end

    function feedback:update(dt)
        local now = env.now()
        for i = #self.events, 1, -1 do
            if now < self.events[i].started or now - self.events[i].started >= 1.2 then table.remove(self.events, i) end
        end
        local owner = env.local_owner()
        if owner ~= self.owner then self.events = {}; self.owner = owner end
        self.elapsed = self.elapsed + dt
        if self.elapsed >= 0.1 then
            self.elapsed = 0
            if #self.pending > 0 then
                local pending = self.pending
                self.pending = {}
                for _, event in ipairs(pending) do pcall(env.send, event) end
            end
        end
    end

    mod:hook(require("scripts/extension_systems/toughness/player_unit_toughness_extension"), "add_damage", function(func, self, ...)
        local actual = func(self, ...)
        if capture and self._unit == capture.unit then capture.toughness = capture.toughness + amount(actual) end
        return actual
    end)
    mod:hook(require("scripts/utilities/attack/damage"), "deal_damage", function(func, unit, breed, attacker, owner, ...)
        local ok, state = pcall(env.attacker, unit, attacker, owner, breed)
        local previous = capture
        local current = ok and state and { unit = unit, toughness = 0 } or nil
        capture = current
        local actual = func(unit, breed, attacker, owner, ...)
        capture = previous
        if current then pcall(feedback.record, feedback, state, unit, actual, current.toughness) end
        return actual
    end)
    return feedback
end
