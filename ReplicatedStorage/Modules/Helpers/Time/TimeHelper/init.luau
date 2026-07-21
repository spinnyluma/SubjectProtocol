local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Modules.Utilities.Promise)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local TimeConfig = require(script.Config)

local TimeHelper = {}


--[[
	Counts down until a number of seconds is elapsed.
	This function yields.
	
	@yields
	@param number numberOfSeconds The number of seconds to count down.
	@param function callbackAfterTick The function to call on each tick.
	@returns boolean Whether the countdown successfully counted down.
]]
function TimeHelper.CreateCountdownInSeconds(numberOfSeconds: number, callbackOnTick: (any?) -> (any?)): boolean
	local numberOfSecondsIsValid = AssertHelper.InvalidArgAssert(
		type(numberOfSeconds) == "number",
		numberOfSeconds,
		"numberOfSeconds",
		"TimeHelper.CreateCountdownInSeconds",
		"number"
	)
	if(not numberOfSecondsIsValid) then return false end
	
	local callbackAfterTickIsValid = AssertHelper.InvalidArgAssert(
		type(callbackOnTick) == "function"
			or type(callbackOnTick) == "nil",
		callbackOnTick,
		"callbackAfterTick",
		"TimeHelper.CreateCountdownInSeconds",
		"function?"
	)
	if(not callbackAfterTickIsValid) then return false end
	
	local endTime = os.clock() + numberOfSeconds
	
	local currentTime = os.clock()
	while (currentTime < endTime) do
		if(callbackOnTick) then
			local timeRemaining = endTime - currentTime
			local timeElapsed = numberOfSeconds - timeRemaining
			callbackOnTick(timeElapsed)
		end
		task.wait()
		currentTime = os.clock()
	end
	
	return true
end



return TimeHelper
