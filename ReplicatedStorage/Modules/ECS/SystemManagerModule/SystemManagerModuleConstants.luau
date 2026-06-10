local SystemManagerModuleConstants = {}

SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_TYPES = {
	["Periodic"] = {
		["Name"] = "Periodic",
		["Value"] = 0
	},
	-- Starts the system every "amount of time" in a task.defer callback.
	["PeriodicDefer"] = {
		["Name"] = "PeriodicDefer",
		["Value"] = 1
	},
	--[[
		Starts updating the system every "amount of time" after a signal has been fired to start the system.
		If the "StopSystem" signal is fired, this system will stop updating every frame.
	]]
	["OnSystemStartSignalPeriodic"] = {
		["Name"] = "OnSystemStartSignalPeriodic",
		["Value"] = 2
	},
	["OnSystemStartSignalPeriodicDefer"] = {
		["Name"] = "OnSystemStartSignalPeriodicDefer",
		["Value"] = 3
	},
	-- Used for initialization purposes, or creating systems that keep track of events.
	["Static"] = {
		["Name"] = "Static",
		["Value"] = 4
	}
}


export type SystemUpdateIntervalType = keyof<typeof(SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_TYPES)>

SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_TYPE_ATTR = "A_SystemUpdateIntervalType"
SystemManagerModuleConstants.SYSTEM_UPDATE_INTERVAL_ATTR = "A_SystemUpdateInterval"

SystemManagerModuleConstants.SYSTEM_TAG_MEMBER_VARIABLE_NAME = "SYSTEM_TAG_NAME"
SystemManagerModuleConstants.COMPONENTS_TO_ADD_VARIABLE_NAME = "componentsToAdd"
SystemManagerModuleConstants.COMPONENT_PROPERTY_INFO_VARIABLE_NAME = "COMPONENT_PROPERTY_INFO"

SystemManagerModuleConstants.COMPONENT_TABLE_KEYS = {
	["Data"] = {
		["Name"] = "Data",
		["Value"] = 0
	},
	["DataIndexToEntity"] = {
		["Name"] = "DataIndexToEntity",
		["Value"] = 1
	},
	["EntityToDataIndex"] = {
		["Name"] = "EntityToDataIndex",
		["Value"] = 2
	}
}

export type ComponentTableKey = keyof<typeof(SystemManagerModuleConstants.COMPONENT_TABLE_KEYS)>

--[[
	Contains components and game state information.
]]
export type World = {
	["Components"]: {[string]: {[string]: {any?}}?},
	["GameState"]: {[string]: any?}
}
return SystemManagerModuleConstants
