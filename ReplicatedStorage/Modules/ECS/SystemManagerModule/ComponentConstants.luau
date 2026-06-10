local ComponentConstants = {}


export type ComponentPropertyInfo = {[string]: {[string]: string | number}}
--[[
	Types which dictate how or when a component gets removed.
]]
ComponentConstants.ON_REMOVE_COMPONENT_TRIGGER_TYPES = {
	["Instant"] = {
		["Name"] = "Instant",
		["Value"] = 0
	},
	-- Removes a component after a certain period of time
	["Timed"] = {
		["Name"] = "Timed",
		["Value"] = 1
	},
	--[[
		Waits until a system or function manually removes the component
	]]
	["Manual"] = {
		["Name"] = "Manual",
		["Value"] = 2
	}
}


ComponentConstants.COMPONENT_PROPERTIES_KEYS = {
	["RemoveComponentTriggerType"] = {
		["Name"] = "RemoveComponentTriggerType",
		["Value"] = 0
	},
	["TimedTime"] = {
		["Name"] = "TimedTime",
		["Value"] = 1
	}
}
return ComponentConstants
