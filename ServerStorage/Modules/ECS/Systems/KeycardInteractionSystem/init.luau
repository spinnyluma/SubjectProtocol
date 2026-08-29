local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
const Players = game:GetService("Players")

const Modules = ReplicatedStorage.Modules

const Shared = Modules.Shared

const Constants = Shared.Constants

const Sound = Constants.Sound

local ProximitySignals = require(ReplicatedStorage.Modules.ECS.Systems.ProximityInteractionSystem.Signals)
local ProximityConfig = require(ReplicatedStorage.Modules.ECS.Systems.ProximityInteractionSystem.Config)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
const SoundConfig = require(Sound.SoundConfig)
local DoorConfig = require(ReplicatedStorage.Modules.Shared.Constants.DoorConfig)

local KeycardConfig = require(script.Config)

const SoundReplicationService = require("../../Services/Sound/SoundReplicationService")

local KeycardInteractionSystem = {}




local function InitiateKeycardInteraction(
	interactionType: string,
	querySource: Instance,
	instancesFound: {Instance?}
)
	local interactionTypeIsValid = AssertHelper.InvalidArgAssert(
		type(interactionType) == "string",
		interactionType,
		"interactionType",
		"string",
		"InitiateKeycardInteraction"
	)
	if(not interactionTypeIsValid) then return end
	local querySourceIsValid = AssertHelper.InvalidArgAssert(
		typeof(querySource) == "Instance",
		querySource,
		"querySource",
		"Instance",
		"InitiateKeycardInteraction"
	)
	if(not querySourceIsValid) then return end
	local instancesFoundIsValid = AssertHelper.InvalidArgAssert(
		type(instancesFound) == "table",
		instancesFound,
		"instancesFound",
		"table",
		"InitiateKeycardInteraction"
	)
	if(not instancesFoundIsValid) then return end
	for _, securityDoor in instancesFound do
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

		local openDurationAttribute: number? = securityDoor:GetAttribute(KeycardConfig.OPEN_DURATION_ATTR_NAME)
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
	
end

function KeycardInteractionSystem.Initialize()
	ProximitySignals.ProximityObjectsFound:Connect(function(interactionType: string,
		proximityObjects: {[Instance]: {Instance}?}
	)
		for proximityObject, objectsFound in proximityObjects do
			if(interactionType == ProximityConfig.proximityInteractionTypes.T_Keycard.Name) then
				InitiateKeycardInteraction(interactionType, proximityObject, objectsFound)
			end		
		end
		
	end)	
end

return KeycardInteractionSystem
