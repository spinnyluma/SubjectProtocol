const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Helpers = Modules.Helpers

const Debug = Helpers.Debug
const Time = Helpers.Time

const AssertHelper = require(Debug.AssertHelper)
const TimeHelper = require(Time.TimeHelper)
const Promise = require(Utilities.Promise)
const t = require(Utilities.t)

local FirerateService = {}

local fireRateThreads: {[Model]: thread} = {}

const function RemoveFirerateEndTime(weapon: Model)
	const modelIsValidFn = t.instanceIsA("Model")
	const weaponIsValid, weaponInvalidReason = modelIsValidFn(weapon)
	if not weaponIsValid then
		AssertHelper.Warn(weapon)
		return
	end
	
	const fireRateThread = fireRateThreads[weapon]
	if not fireRateThread then
		return
	end
	
	print(fireRateThreads)
	fireRateThreads[weapon] = nil
	print(fireRateThreads)
end

function FirerateService.AddFirerateStartTime(weapon: Model, startTime: number, fireRate: number)
	const modelIsValidFn = t.instanceIsA("Model")
	const weaponIsValid, weaponInvalidReason = modelIsValidFn(weapon)
	if not weaponIsValid then
		AssertHelper.Warn(weaponInvalidReason)
		return
	end
	
	
	const startTimeIsValid, startTimeInvalidReason = t.number(startTime)
	if(not startTimeIsValid) then
		AssertHelper.Warn(startTimeInvalidReason)
		return
	end
	
	const fireRateIsValid, fireRateInvalidReason = t.number(fireRate)
	if(not fireRateIsValid) then
		AssertHelper.Warn(fireRateInvalidReason)
		return
	end
	
	fireRateThreads[weapon] = startTime - fireRate * 0.20
	
	weapon.Destroying:Once(function()
		RemoveFirerateEndTime(weapon)
	end)
end


function FirerateService.IsWeaponInCooldown(weapon: Model, fireRate: number)
	const modelIsValidFn = t.instanceIsA("Model")
	const weaponIsValid, weaponInvalidReason = modelIsValidFn(weapon)
	if not weaponIsValid then
		AssertHelper.Warn(weapon)
		return
	end
	
	const lastFireTime = fireRateThreads[weapon]
	if not lastFireTime then
		return false
	end
	
	local currentTime = workspace:GetServerTimeNow()
	
	local timeSinceLastFire = currentTime - lastFireTime
	const fireRateLeniency = fireRate * 0.20
	return timeSinceLastFire < fireRate - fireRateLeniency
end

return FirerateService
