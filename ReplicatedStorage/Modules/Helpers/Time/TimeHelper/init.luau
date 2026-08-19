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
			local flag = callbackOnTick(timeElapsed)
			if(flag == TimeConfig.countdownFlags.CancelCountdown.Name) then
				return false
			end	
		end
		task.wait()
		currentTime = os.clock()
	end
	
	return true
end



--[[
	Counts down until a number of seconds is elapsed, ticking once per whole second.
	This function yields.

	@yields
	@param number numberOfSeconds The number of seconds to count down.
	@param function callbackOnTick The function to call on each second tick. Receives the seconds remaining (integer).
	@returns boolean Whether the countdown successfully counted down.
]]
function TimeHelper.CreateCountdownInSecondsPrecise(numberOfSeconds: number, callbackOnTick: (any?) -> (any?)): boolean
	local numberOfSecondsIsValid = AssertHelper.InvalidArgAssert(
		type(numberOfSeconds) == "number",
		numberOfSeconds,
		"numberOfSeconds",
		"TimeHelper.CreateCountdownInSecondsPrecise",
		"number"
	)
	if(not numberOfSecondsIsValid) then return false end

	local callbackOnTickIsValid = AssertHelper.InvalidArgAssert(
		type(callbackOnTick) == "function"
			or type(callbackOnTick) == "nil",
		callbackOnTick,
		"callbackOnTick",
		"TimeHelper.CreateCountdownInSecondsPrecise",
		"function?"
	)
	if(not callbackOnTickIsValid) then return false end

	local endTime = os.time() + numberOfSeconds
	local secondsRemaining = numberOfSeconds

	while secondsRemaining > 0 do
		if(callbackOnTick) then
			local flag = callbackOnTick(secondsRemaining)
			if(flag == TimeConfig.countdownFlags.CancelCountdown.Name) then
				return false
			end
		end

		local currentTime = os.time()
		local waitDuration = endTime - (secondsRemaining - 1) - currentTime
		if waitDuration > 0 then
			task.wait(waitDuration)
		end

		secondsRemaining = math.max(0, endTime - os.time())
	end

	return true
end


function TimeHelper.GetMinutesSecondsFromSeconds(seconds: number): string?
	local secondsIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(seconds) == "number",
		seconds,
		"seconds",
		"TimeHelper.GetMinutesSecondsFromSeconds",
		"number"
	)
	if(not secondsIsValid) then
		return nil
	end

	if(seconds < 0) then
		return "0:00"
	end
	local numberOfSecondsInMinute: number = 60

	local minutes = math.floor(seconds / numberOfSecondsInMinute)
	-- We modulo the current num of seconds because we only want the remaining seconds after obtaining the current amount
	-- of minutes
	seconds %= numberOfSecondsInMinute

	local timeString = ""

	-- We left-pad the number of seconds with zeros
	-- because we want to always display two numbers in the minutes position
	local minutesString = tostring(minutes)
	timeString ..= minutesString .. ":" .. string.format("%02i", seconds)

	return timeString
end


return TimeHelper
