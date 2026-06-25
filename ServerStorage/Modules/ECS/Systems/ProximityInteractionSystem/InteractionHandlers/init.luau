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
	
	
end

return InteractionHandlers
