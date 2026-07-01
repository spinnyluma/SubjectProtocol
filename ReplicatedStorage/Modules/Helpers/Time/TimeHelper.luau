local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Modules.Utilities.Promise)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local TimeHelper = {}

--[[
	Counts down until a number of seconds is elapsed.
	This function yields.
	
	@yields
	@param number numberOfSeconds The number of seconds to count down.
	@returns boolean Whether the countdown successfully counted down.
]]
function TimeHelper.CreateCountdownInSeconds(numberOfSeconds: number): boolean
	local numberOfSecondsIsValid = AssertHelper.InvalidArgAssert(
		type(numberOfSeconds) == "number",
		numberOfSeconds,
		"numberOfSeconds",
		"TimeHelper.CreateCountdownInSeconds",
		"number"
	)
	if(not numberOfSecondsIsValid) then return false end
	
	local endTime = os.clock() + numberOfSeconds
	
	while (os.clock() < endTime) do
		task.wait()
	end
	
	return true
end

return TimeHelper
