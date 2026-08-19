local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Debug
	.AssertHelper
)
local TimeHelper = require(ReplicatedStorage.Modules.Helpers.Time.TimeHelper)
local TimeConfig = require(ReplicatedStorage.Modules.Helpers.Time.TimeHelper.Config)

local AnimationHelper = {}

--[[
	Loads an animation onto an Animator and waits for it to finish loading.
	
	@param Animator animator The Animator to load the animation onto.
	@param number|string animationId The animation asset ID. Accepts a numeric ID or a full "rbxassetid://..." string.
	@param number? timeout The maximum time in seconds to wait for the animation to load. Defaults to 5.
	@returns AnimationTrack? The loaded animation track, or nil if loading failed or timed out.
]]
function AnimationHelper.LoadAnimation(animator: Animator, animationId: number | string, timeout: number?): AnimationTrack?
	local animatorIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(animator) == "Instance"
			and animator:IsA("Animator"),
		animator,
		"animator",
		"AnimationHelper.LoadAnimation",
		"Animator"
	)
	if(not animatorIsValid) then
		return nil
	end

	local animationIdIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(animationId) == "number" or type(animationId) == "string",
		animationId,
		"animationId",
		"AnimationHelper.LoadAnimation",
		"number|string"
	)
	if(not animationIdIsValid) then
		return nil
	end

	local animation: Animation = Instance.new("Animation")
	if(type(animationId) == "number") then
		animation.AnimationId = `rbxassetid://{animationId}`
	else
		animation.AnimationId = animationId
	end

	local timeoutIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(timeout) == "number" or type(timeout) == "nil",
		timeout,
		"timeout",
		"AnimationHelper.LoadAnimation",
		"number?"
	)
	if(not timeoutIsValid) then
		return nil
	end

	local maxWait: number = timeout or math.huge

	local track: AnimationTrack = animator:LoadAnimation(animation)

	-- Wait until the animation has finished loading (Length becomes non-zero).
	local loaded: boolean = false
	TimeHelper.CreateCountdownInSeconds(maxWait, function()
		if(track.Length > 0) then
			loaded = true
			return TimeConfig.countdownFlags.CancelCountdown.Name
		end
	end)

	if(not loaded) then
		AssertHelper.Warn(`Animation failed to load within {maxWait} seconds.`)
		return nil
	end

	return track
end

return AnimationHelper