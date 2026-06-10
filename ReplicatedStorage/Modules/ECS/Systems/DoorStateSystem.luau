local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local AssertModule = require(ReplicatedStorage.Modules.Utilities.Debug.AssertModule)
local DoorConfig = require(ReplicatedStorage.Modules.Shared.Constants.DoorConfig)

local DoorStateSystem = {}

local DoorTweenInfo = TweenInfo.new(
	1,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In,
	0,
	false,
	0
)

local function SetDoorSegmentState(segment: BasePart, state: boolean)
	local segmentIsValid = AssertModule.InvalidArgAssert(
		typeof(segment) == "Instance"
		and segment:IsA("BasePart"),
		segment,
		"segment",
		"TweenDoorSegment",
		"BasePart"
	)
	if not segmentIsValid then return end
	local stateIsValid = AssertModule.InvalidArgAssert(
		type(state) == "boolean",
		state,
		"state",
		"TweenDoorSegment",
		"boolean"
	)
	if not stateIsValid then return end
	local openDoorOffset: CFrame? = segment:GetAttribute(DoorConfig.OPEN_DOOR_OFFSET_ATTR_NAME) 

	local openDoorOffsetIsValid = AssertModule.ExpectedValAssert(
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
			local doorStateIsValid = AssertModule.ExpectedValAssert(
				type(doorState) == "string",
				doorState,
				"newAttributeValue",
				"string"
			)
			if not doorStateIsValid then return end
			local upperSegment: BasePart? = door:FindFirstChild("UpperSegment")
			local lowerSegment: BasePart? = door:FindFirstChild("LowerSegment")
			local upperSegmentIsValid = AssertModule.ExpectedValAssert(
				typeof(upperSegment) == "Instance"
					and upperSegment:IsA("BasePart"),
				upperSegment,
				"upperSegment",
				"BasePart"
			)
			if(not upperSegmentIsValid) then return end

			local lowerSegmentIsValid = AssertModule.ExpectedValAssert(
				typeof(lowerSegment) == "Instance"
					and lowerSegment:IsA("BasePart"),
				lowerSegment,
				"lowerSegment",
				"BasePart"
			)
			if not (lowerSegmentIsValid) then return end
			if(doorState == DoorConfig.doorStates.Open.Name) then
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
