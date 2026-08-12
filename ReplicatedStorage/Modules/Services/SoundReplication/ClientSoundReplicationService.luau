const ReflectionService = game:GetService("ReflectionService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
const SoundConfig = require(ReplicatedStorage.Modules.Shared.Constants.Sound.SoundConfig)

local ClientSoundReplicationService = {}

local function SetUpSoundFromSoundConfig(soundConfig: SoundConfig.SoundConfig)
	const soundConfigIsValid = AssertHelper.InvalidArgAssert(
		type(soundConfig) == "table",
		soundConfig,
		"soundConfig",
		"ClientSoundReplicationService.SetUpSoundFromSoundConfig",
		"table"
	)
	if not soundConfigIsValid then return end

	local sound = Instance.new("Sound")

	local soundProperties = ReflectionService:GetPropertiesOfClass("Sound", {
		ExcludeInherited = true
	})

	for _, propertyTable in soundProperties do
		const propertyName = propertyTable.Name
		const propertyValue = soundConfig[propertyName]
		if(not soundConfig[propertyName]) then continue end
		if(propertyName == "SoundId") then
			sound.SoundId = "rbxassetid://"..propertyValue
		else
			sound[propertyName] = propertyValue

		end
	end
	return sound
end

function ClientSoundReplicationService.PlaySoundFromPart(part: BasePart, soundConfig: SoundConfig.SoundConfig)
	const partIsValid = AssertHelper.InvalidArgAssert(
		typeof(part) == "Instance" and part:IsA("BasePart"),
		part,
		"part",
		"ClientSoundReplicationService.PlaySoundFromPart",
		"BasePart"
	)
	if not partIsValid then return end

	const soundConfigIsValid = AssertHelper.InvalidArgAssert(
		type(soundConfig) == "table",
		soundConfig,
		"soundConfig",
		"ClientSoundReplicationService.PlaySoundFromPart",
		"table"
	)
	if not soundConfigIsValid then return end

	const sound = SetUpSoundFromSoundConfig(soundConfig)
	if not sound then return end

	sound.Parent = part
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function ClientSoundReplicationService.PlaySoundFromPosition(position: Vector3, soundConfig: SoundConfig.SoundConfig)
	const positionIsValid = AssertHelper.InvalidArgAssert(
		typeof(position) == "Vector3",
		position,
		"position",
		"ClientSoundReplicationService.PlaySoundFromPosition",
		"Vector3"
	)
	if not positionIsValid then return end

	const soundConfigIsValid = AssertHelper.InvalidArgAssert(
		type(soundConfig) == "table",
		soundConfig,
		"soundConfig",
		"ClientSoundReplicationService.PlaySoundFromPosition",
		"table"
	)
	if not soundConfigIsValid then return end

	const attachment = Instance.new("Attachment")
	attachment.WorldCFrame = CFrame.new(position)

	const sound = SetUpSoundFromSoundConfig(soundConfig)
	if not sound then
		attachment:Destroy()
		return
	end

	sound.Parent = attachment
	attachment.Parent = workspace
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
		attachment:Destroy()
	end)
end

return ClientSoundReplicationService
