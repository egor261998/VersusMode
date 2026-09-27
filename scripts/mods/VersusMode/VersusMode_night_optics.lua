-- Adapted from Wobin/Preysight (https://github.com/Wobin/Preysight).
local mod = get_mod("VersusMode")

local ShadingEnvironment = ShadingEnvironment
local Managers = Managers

local optics = {}

local _installed = false
local _weight = 0
local _target = 0
local _blur = 0.1
local _greyscale = 1.0
local _blend_in = 1.0
local _blend_out = 0.6

local _surge_peak = 1.0
local _surge_attack = 0.12
local _surge_decay = 0.9
local _surge_blur = 0.35

local _intro_peak = 2.2
local _intro_attack = 0.10
local _intro_decay = 1.3
local _intro_blur = 0.6

local _surge = 0
local _surge_t = -1
local _surge_intro = false
local _intro_pending = true

local function surge_params()
	if _surge_intro then
		return _intro_peak, _intro_attack, _intro_decay, _intro_blur
	end

	return _surge_peak, _surge_attack, _surge_decay, _surge_blur
end

local function apply(shading_env)
	if _weight <= 0 then
		return
	end

	if _greyscale > 0 then
		ShadingEnvironment.set_scalar(shading_env, "grey_scale_enabled", 1)
		ShadingEnvironment.set_scalar(shading_env, "grey_scale_amount", _greyscale * _weight)
	end

	local _, _, _, blur = surge_params()
	local blur_amount = (_blur + blur * _surge) * _weight
	if blur_amount > 0 then
		ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_enabled", 1)
		ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_amount", blur_amount)
	end
end

local function step_surge(dt)
	if _surge_t < 0 then
		return
	end

	local _, attack, decay = surge_params()

	_surge_t = _surge_t + dt

	if _surge_t < attack then
		_surge = attack > 0 and _surge_t / attack or 1

		return
	end

	local decayed = _surge_t - attack

	if decay <= 0 or decayed >= decay then
		_surge = 0
		_surge_t = -1
		_surge_intro = false

		return
	end

	_surge = 1 - decayed / decay
end

optics.install = function(mod)
	if _installed then
		return
	end

	mod:hook(CLASS.CameraManager, "shading_callback", function(func, self, world, shading_env, viewport, default_resource, ...)
		func(self, world, shading_env, viewport, default_resource, ...)

		if Managers.ui and Managers.ui:has_active_view() then
			return
		end

		apply(shading_env)
	end)

	_installed = true
end

optics.update = function(dt)
	_weight = mod._night_vision.ramp.step(_weight, _target, dt, _blend_in, _blend_out)

	step_surge(dt)
end

optics.set_target = function(target)
	if target > 0 and _target <= 0 then
		_surge = 0
		_surge_t = 0
		_surge_intro = _intro_pending
		_intro_pending = false
	end

	_target = target
end

optics.set_surge = function(peak, attack, decay, blur)
	_surge_peak = peak
	_surge_attack = attack
	_surge_decay = decay
	_surge_blur = blur
end

optics.set_intro_surge = function(peak, attack, decay, blur)
	_intro_peak = peak
	_intro_attack = attack
	_intro_decay = decay
	_intro_blur = blur
end

optics.arm_intro = function()
	_intro_pending = true
end

optics.intro_pending = function()
	return _intro_pending
end

optics.weight = function()
	return _weight
end

optics.set_tuning = function(exposure, blur, greyscale, blend_in, blend_out)
	_blur = blur
	_greyscale = greyscale
	_blend_in = blend_in
	_blend_out = blend_out
end

optics.reset = function()
    _weight = 0
    _target = 0
    _surge = 0
    _surge_t = -1
end

return optics
