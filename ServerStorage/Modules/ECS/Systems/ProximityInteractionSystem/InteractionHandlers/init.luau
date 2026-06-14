local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)


local InteractionHandlersConfig = require(script.Config)
local DoorConfig = require(ReplicatedStorage.Modules.Shared.Constants.DoorConfig)

local InteractionHandlers = {}


function InteractionHandlers.HandleKeycardReaderQueried(trigger: BasePart)
	local triggerIsValid = AssertHelper.InvalidArgAssert(
		typeof(trigger) == "Instance"
		and trigger:IsA("BasePart"),
		trigger,
		"reader",
		"HandleKeycardReaderQueried",
		"BasePart"
	)
	
	if not triggerIsValid then
		return
	end
	
	local securityDoor: Model = trigger.Parent.Parent
	local securityDoorIsModel = AssertHelper.ExpectedValAssert(
		typeof(securityDoor) == "Instance"
		and securityDoor:IsA("Model"),
		securityDoor,
		"securityDoor",
		"HandleKeycardReaderQueried",
		"Model"
	)
	if not securityDoorIsModel then
		return
	end
	
	local doorStateAttribute: boolean? = securityDoor:GetAttribute(DoorConfig.DOOR_STATE_ATTR_NAME)
	local doorStateAttributeIsValid = AssertHelper.ExpectedValAssert(
		type(doorStateAttribute) == "string",
		doorStateAttribute,
		"doorStateAttribute",
		"HandleKeycardReaderQueried",
		"boolean"
	)
	if not doorStateAttributeIsValid then return end
	--[[
		Return from the function 
		Because we don't want to open the door again	
	]]
	if(doorStateAttribute == DoorConfig.doorStates.Closing.Name
		or doorStateAttribute == DoorConfig.doorStates.Open.Name) then return end

	local openDurationAttribute: number? = securityDoor:GetAttribute(InteractionHandlersConfig.OPEN_DURATION_ATTR_NAME)
	local openDurationAttributeIsValid = AssertHelper.ExpectedValAssert(
		type(openDurationAttribute) == "number",
		openDurationAttribute,
		"openDurationAttribute",
		"HandleKeycardReaderQueried",
		"number"
	)
	if not openDurationAttributeIsValid then return end
	
	local closingDurationAttribute = securityDoor:GetAttribute(DoorConfig.CLOSING_DURATION_ATTR_NAME)
	local closingDurationAttributeIsValid = AssertHelper.ExpectedValAssert(
		type(closingDurationAttribute) == "number",
		closingDurationAttribute,
		"closingDurationAttribute",
		"HandleKeycardReaderQueried",
		"number"
	)
	if not closingDurationAttributeIsValid then return end
	securityDoor:SetAttribute(DoorConfig.DOOR_STATE_ATTR_NAME, "Open")
	task.delay(openDurationAttribute, function()
		securityDoor:SetAttribute(DoorConfig.DOOR_STATE_ATTR_NAME, "Closing")
		task.delay(closingDurationAttribute, function()
			securityDoor:SetAttribute(DoorConfig.DOOR_STATE_ATTR_NAME, "Closed")
		end)	
	end)
end

return InteractionHandlers
