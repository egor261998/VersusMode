-- Server-owned timers survive action cancellation and native behavior restarts.
return function(setting)
    local balance = {}
    function balance.number(id, fallback, minimum, maximum)
        local value = setting(id)
        if type(value) ~= "number" or value ~= value then value = fallback end
        return math.max(minimum, math.min(maximum, value))
    end

    function balance.shotgun(state)
        local name = state.breed and state.breed.name
        return name == "renegade_shocktrooper" or name == "cultist_shocktrooper"
    end

    function balance.remaining(state, attack, t)
        local remaining = state.balance_cancel_t
            and state.balance_cancel_t + balance.number("attack_cancel_delay", 1, 0, 5) - t or 0
        if state.breed.is_boss and setting("enable_boss_attack_delay") ~= false and state.balance_boss_end_t then
            remaining = math.max(remaining, state.balance_boss_end_t + balance.number("boss_attack_delay", 1, 0, 10) - t)
        end
        if attack and attack.shotgun_combat_range == "close" and balance.shotgun(state) then
            if state.balance_reload_t then
                local reload = state.balance_reload_t + balance.number("shotgun_reload_duration", 3, 1, 10) - t
                if reload > 0 then
                    remaining = math.max(remaining, reload)
                else
                    state.balance_reload_t = nil
                    state.balance_shots = 0
                end
            end
            if state.balance_shot_t then
                remaining = math.max(remaining, state.balance_shot_t + balance.number("shotgun_shot_delay", 1, 0.5, 5) - t)
            end
        end
        if attack and attack.grenadier_path == "far" and state.balance_bomb_t then
            remaining = math.max(remaining, state.balance_bomb_t + balance.number("bomber_throw_delay", 3, 0, 15) - t)
        end
        return math.max(0, remaining)
    end

    function balance.shot(state, t)
        if not balance.shotgun(state) then return end
        -- Reset an elapsed magazine even if the final shot was cancelled.
        if state.balance_reload_t and t >= state.balance_reload_t + balance.number("shotgun_reload_duration", 3, 1, 10) then
            state.balance_reload_t = nil
            state.balance_shots = 0
        end
        state.balance_shot_t = t
        state.balance_shots = (state.balance_shots or 0) + 1
        if state.balance_shots >= math.floor(balance.number("shotgun_magazine_size", 6, 1, 20)) then
            state.balance_reload_t = t
        end
    end

    function balance.finished(state, t)
        if state.breed.is_boss and state.attack_deadline and state.requested_attack then
            state.balance_boss_end_t = t
        end
    end

    function balance.player_cc_profile(profile, attack_type)
        return profile and (profile.is_push == true or profile.suppression_type == "ability" or attack_type == "push") or false
    end

    return balance
end
