local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
const Players = game:GetService("Players")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local DoorConfig = require(ReplicatedStorage.Modules.Shared.Constants.DoorConfig)

const ClientSoundReplicationService = require("../../Services/SoundReplication/ClientSoundReplicationService")
const ClientSoundService = require("../../Services/Sound/ClientSoundService")
const SoundConfig = require("../../Shared/Constants/Sound/SoundConfig")

local DoorStateSystem = {}

local DoorTweenInfo = TweenInfo.new(
	1,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In,
	0,
	false,
	0
)

const function PlaySecurityDoorSounds(securityDoor: Model)
	const securityDoorPivot: CFrame = securityDoor:GetPivot()
	const securityDoorPosition = securityDoorPivot.Position

	const baseSoundConfig = SoundConfig.clientSoundConfigs.Environment.MetalDoorOpen
	const baseKeycardSoundConfig = SoundConfig.clientSoundConfigs.Environment.KeycardUnlock
	ClientSoundReplicationService.PlaySoundFromPosition(securityDoorPosition, baseKeycardSoundConfig)
	ClientSoundReplicationService.PlaySoundFromPosition(securityDoorPosition, baseSoundConfig)
end

local function SetDoorSegmentState(segment: BasePart, state: boolean)
	local segmentIsValid = AssertHelper.InvalidArgAssert(
		typeof(segment) == "Instance"
		and segment:IsA("BasePart"),
		segment,
		"segment",
		"TweenDoorSegment",
		"BasePart"
	)
	if not segmentIsValid then return end
	local stateIsValid = AssertHelper.InvalidArgAssert(
		type(state) == "boolean",
		state,
		"state",
		"TweenDoorSegment",
		"boolean"
	)
	if not stateIsValid then return end
	local openDoorOffset: CFrame? = segment:GetAttribute(DoorConfig.OPEN_DOOR_OFFSET_ATTR_NAME) 

	local openDoorOffsetIsValid = AssertHelper.ExpectedValAssert(
		typeof(openDoorOffset) == "CFrame",
		openDoorOffset,
		"openDoorOffset",
		"CFrame"
	)
	if(state) then
		local tween = TweenService:Create(
			segment,
			DoorTweenInfo,
			{CFrame = segment.CFrame * openDoorOffset}
		)
		tween:Play()
	else
		local tween = TweenService:Create(
			segment,
			DoorTweenInfo,
			{CFrame = segment.CFrame * openDoorOffset:Inverse()}
		)
		tween:Play()

	end
	
end

local function InitializeDoorStateHandlers()
	local securityDoors = CollectionService:GetTagged(DoorConfig.SECURITY_DOOR_TAG_NAME)
	for _, door in securityDoors do
		door:GetAttributeChangedSignal(DoorConfig.DOOR_STATE_ATTR_NAME):Connect(function()
			local doorState: boolean? = door:GetAttribute(DoorConfig.DOOR_STATE_ATTR_NAME)
			local doorStateIsValid = AssertHelper.ExpectedValAssert(
				type(doorState) == "string",
				doorState,
				"newAttributeValue",
				"string"
			)
			if not doorStateIsValid then return end
			local upperSegment: BasePart? = door:FindFirstChild("UpperSegment")
			local lowerSegment: BasePart? = door:FindFirstChild("LowerSegment")
			local upperSegmentIsValid = AssertHelper.ExpectedValAssert(
				typeof(upperSegment) == "Instance"
					and upperSegment:IsA("BasePart"),
				upperSegment,
				"upperSegment",
				"BasePart"
			)
			if(not upperSegmentIsValid) then return end

			local lowerSegmentIsValid = AssertHelper.ExpectedValAssert(
				typeof(lowerSegment) == "Instance"
					and lowerSegment:IsA("BasePart"),
				lowerSegment,
				"lowerSegment",
				"BasePart"
			)
			if not (lowerSegmentIsValid) then return end
			if(doorState == DoorConfig.doorStates.Open.Name) then
				PlaySecurityDoorSounds(door)
				SetDoorSegmentState(upperSegment, true)
				SetDoorSegmentState(lowerSegment, true)
			elseif(doorState == DoorConfig.doorStates.Closing.Name) then
				SetDoorSegmentState(upperSegment, false)
				SetDoorSegmentState(lowerSegment, false)
			end
		end)
	end
end

function DoorStateSystem.Initialize()
	InitializeDoorStateHandlers()
end

return DoorStateSystem
