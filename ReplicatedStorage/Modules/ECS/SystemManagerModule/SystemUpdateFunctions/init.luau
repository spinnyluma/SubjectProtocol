local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertModule = require(ReplicatedStorage.Modules.Utilities.Debug.AssertModule)
local ModuleLoader = require(ReplicatedStorage.Modules.Framework.ModuleLoader)
local SystemManagerModuleConstants = require(ReplicatedStorage
	.Modules
	.ECS
	.SystemManagerModule
	.SystemManagerModuleConstants)
local FastSignal = require(ReplicatedStorage.Modules.Framework.FastSignal)
local SystemUpdateFunctionsConstants = require(script.SystemUpdateFunctionsConstants)


-- TODO: fix the errors in this script

local SystemUpdateFunctions = {}
SystemUpdateFunctions.updateThreads = {}

function SystemUpdateFunctions.GetUpdateThread(systemName: string): thread?
	local systemNameIsValid: boolean? = AssertModule.Assert(
		`Invalid argument to SystemUpdateFunctions.GetUpdateThread. string expected for systemName, got {systemName}`,
		type(systemName) == "string"
	)
	
	if(not systemNameIsValid) then
		return
	end
	
	local updateThread: thread? = SystemUpdateFunctions.updateThreads[systemName]
	return updateThread
end

function SystemUpdateFunctions.StartUpdateThread()
	
end



function SystemUpdateFunctions.StartDeferredUpdateThread(systemModule: ModuleScript)
	local systemModuleIsValid: boolean? = AssertModule.Assert(
		`Invalid argument to SystemUpdateFunctions.StartDeferredUpdateThread. table expected for systemModule, got {systemModule}`,
		typeof(systemModule) == "Instance"
		and systemModule:IsA("ModuleScript")
	)
	if(not systemModuleIsValid) then
		return
	end
	
	local systemName: string = systemModule.Name
	local existentUpdateThread: thread? = SystemUpdateFunctions.GetUpdateThread(systemName)
	local systemUpdateThreadExists: boolean = existentUpdateThread ~= nil
	if(systemUpdateThreadExists) then
		AssertModule.Warn(`System with name {systemName} is already running an update thread`)
		return
	end
	local requiredSystemModule: ModuleScript? = ModuleLoader.Get(systemName)

	local requiredSystemModuleIsValid: boolean? = AssertModule.Assert(
		`table expected for requiredSystemModule, got {requiredSystemModule}`,
		type(requiredSystemModule) == "table"
	)
	if(not requiredSystemModuleIsValid) then
		return
	end
	
	local systemUpdateInterval: number? = systemModule:GetAttribute(SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_ATTR)
	local systemUpdateIntervalIsValid: boolean? = AssertModule.Assert(
		`number expected for systemUpdateInterval, got {systemUpdateInterval}`,
		type(systemUpdateInterval) == "number"
	)
	if(not systemUpdateIntervalIsValid) then
		return
	end
	
	
	
	local deferredUpdateThread: thread = task.defer(function()

		if(not requiredSystemModule.Update) then
			AssertModule.Warn(`Update function expected for {requiredSystemModule}, got {requiredSystemModule.Update}`)
			return
		end
		local systemManagerModule: {any?}? = ModuleLoader.Get("SystemManagerModule")
		local systemManagerModuleIsValid: boolean? = AssertModule.Assert(
			`table expected for systemManagerModule, got {systemManagerModule}`,
			type(systemManagerModule) == "table"
		)
		if(not systemManagerModuleIsValid) then
			return
		end
		local systemUpdateDeltaTime: number = 0
		while true do
			requiredSystemModule.Update(systemManagerModule, systemUpdateDeltaTime)
			systemUpdateDeltaTime = task.wait(systemUpdateInterval)
		end
	end)
	
	SystemUpdateFunctions.updateThreads[systemName] = deferredUpdateThread
end

function SystemUpdateFunctions.StopUpdateThread(systemName: string): boolean
	local systemUpdateThread: thread? = SystemUpdateFunctions.GetUpdateThread(systemName)
	
	local systemUpdateThreadIsValid: boolean = type(systemUpdateThread) == "thread"
	
	if(not systemUpdateThreadIsValid) then
		return false
	end
	
	task.cancel(systemUpdateThread)
	SystemUpdateFunctions.updateThreads[systemName] = nil
	return true
end

local function SystemStartPeriodicDeferStopUpdate(systemModuleName: string)
	local systemModuleNameIsValid: boolean? = AssertModule.InvalidArgAssert(
		type(systemModuleName) == "string",
		systemModuleName,
		"systemModuleName",
		"SystemStartPeriodicDeferStopUpdate",
		"string"
	)
	if(not systemModuleNameIsValid) then
		return
	end
	
	local systemModule: {[string]: any?}? = ModuleLoader.Get(systemModuleName)
	local systemModuleIsValid: boolean? = AssertModule.ExpectedValAssert(
		type(systemModule) == "table",
		systemModuleName,
		"systemModuleName",
		"table"
	)
	if(not systemModuleIsValid) then
		return
	end
	
	local systemStopFunc: () -> ()? = systemModule.Stop
	local systemStopFuncIsValid: boolean = type(systemStopFunc) == "function"
	if(not systemStopFuncIsValid) then
		return
	end
	
	systemStopFunc()
end


local function OnSystemStartSignalPeriodicDeferUpdateInit(systemModuleToInitialize: ModuleScript)
	local systemModuleToInitializeIsValid: boolean? = AssertModule.Assert(
		`Invalid argument to OnSystemStartSignalPeriodicDeferUpdateInit. ModuleScript expected for systemModuleToInitialize, got {systemModuleToInitialize}`,
		typeof(systemModuleToInitialize) == "Instance"
			and systemModuleToInitialize:IsA("ModuleScript")
	)
	if(not systemModuleToInitializeIsValid) then
		return
	end
	
	local startSystemSignalConnection: FastSignal.ScriptConnection = SystemUpdateFunctionsConstants.startSystemSignal:Connect(function(systemModuleName: string)
		if(systemModuleToInitialize.Name == systemModuleName) then
			SystemUpdateFunctions.StartDeferredUpdateThread(systemModuleToInitialize)
		end
	end)
	
	local stopSystemSignalConnection: FastSignal.ScriptConnection = SystemUpdateFunctionsConstants.stopSystemSignal:Connect(function(systemModuleName: string)
		if(systemModuleToInitialize.Name == systemModuleName) then
			SystemUpdateFunctions.StopUpdateThread(systemModuleName)
			
			SystemStartPeriodicDeferStopUpdate(systemModuleName)
		end
	end)
	
	local moduleName: string = systemModuleToInitialize.Name
	
end



local function PeriodicDeferUpdateInit(systemModuleToInitialize: ModuleScript)
	local systemModuleToInitializeIsValid: boolean? = AssertModule.Assert(
		`Invalid argument to PeriodicDeferUpdateInit. ModuleScript expected for systemModuleToInitialize, got {systemModuleToInitialize}`,
		typeof(systemModuleToInitialize) == "Instance"
			and systemModuleToInitialize:IsA("ModuleScript")
	)
	if(not systemModuleToInitializeIsValid) then
		return
	end
	
	SystemUpdateFunctions.StartDeferredUpdateThread(systemModuleToInitialize)
end

local function PeriodicUpdateInit(systemModuleToInitialize: ModuleScript)
	local systemModuleToInitializeIsValid: boolean? = AssertModule.InvalidArgAssert(
		typeof(systemModuleToInitialize) == "Instance"
		and systemModuleToInitialize:IsA("ModuleScript"),
		systemModuleToInitialize,
		"systemModuleToInitialize",
		"PeriodicUpdateInit",
		"ModuleScript"
	)
	if(not systemModuleToInitializeIsValid) then
		return
	end
	
	task.spawn(function()
		local updateInterval: number = systemModuleToInitialize:GetAttribute(SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_ATTR)
		local updateIntervalIsValid: boolean? = AssertModule.ExpectedValAssert(
			type(updateInterval) == "number",
			updateInterval,
			"updateInterval",
			"number"
		)
		if(not updateIntervalIsValid) then
			return
		end
		
		local timeSinceLastUpdate = 0
		local cachedModule = ModuleLoader.Get(systemModuleToInitialize.Name)
		local cachedModuleIsValid: boolean? = AssertModule.ExpectedValAssert(
			type(cachedModule) == "table",
			cachedModule,
			"cachedModule",
			"table"
		)
		if(not cachedModuleIsValid) then
			return
		end
		
		local updateFunc: () -> ()? = cachedModule.Update
		local updateFuncIsValid: boolean? = AssertModule.ExpectedValAssert(
			type(updateFunc) == "function",
			updateFunc,
			"updateFunc",
			"function"
		)
		if(not updateFuncIsValid) then
			return
		end
		
		while true do
			if(timeSinceLastUpdate < updateInterval) then
				timeSinceLastUpdate += task.wait()
			else
				updateFunc(timeSinceLastUpdate)
				timeSinceLastUpdate = 0
			end
		end
		
	end)
end

local updateSystemInitFunctions = {
	[SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_TYPES.Periodic.Name] = PeriodicUpdateInit,
	[SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_TYPES.PeriodicDefer.Name] = PeriodicDeferUpdateInit,
	[SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_TYPES.OnSystemStartSignalPeriodicDefer.Name] = OnSystemStartSignalPeriodicDeferUpdateInit
	
}


function SystemUpdateFunctions.GetUpdateSystemInitFunction(systemUpdateIntervalType: SystemManagerModuleConstants.SystemUpdateIntervalType): ((ModuleScript) -> ())?
	local systemUpdateIntervalTypeIsValid: boolean? = AssertModule.Assert(
		`Invalid argument to SystemUpdateFunctions.GetUpdateSystemInitFunction. SystemManagerModuleConstants.SystemUpdateIntervalType expected for systemUpdateIntervalType, got {systemUpdateIntervalType}`,
		SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_TYPES[systemUpdateIntervalType] ~= nil
	)
	if(not systemUpdateIntervalTypeIsValid) then
		return nil
	end
	
	return updateSystemInitFunctions[systemUpdateIntervalType]
end

return SystemUpdateFunctions
