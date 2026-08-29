const ReflectionService = game:GetService("ReflectionService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
const SoundConfig = require(ReplicatedStorage.Modules.Shared.Constants.Sound.SoundConfig)

const DictionaryHelper = require("../../Helpers/Table/DictionaryHelper")
const t = require("../../Utilities/t")

local ClientSoundReplicationService = {}

function ClientSoundReplicationService.SetUpSoundFromSoundConfig(soundConfig: SoundConfig.SoundConfig)
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
	if(soundConfig.Children) then
		const soundChildren = soundConfig.Children
		for className, propertyValues in soundChildren do
			const reflectedClass = ReflectionService:GetClass(className)
			

			if not reflectedClass then 
				AssertHelper.Warn(`Class name ${className} is invalid`)
				continue
			end

			const permits = reflectedClass.Permits
			if not permits then 
				continue 
			end
			const permitsNew = permits.New
			if(not permitsNew) then
				AssertHelper.Warn(`Class name ${className} does not have a new constructor`)
				continue
			end
			const newInstance = Instance.new(className)
			for name, value in propertyValues do
				
				if(newInstance[name] ~= nil) then
					newInstance[name] = value
				end
				
			end
			newInstance.Parent = sound
		end
		
	end
	for _, propertyTable in soundProperties do
		
		const propertyName = propertyTable.Name
		const propertyValue = soundConfig[propertyName]
		if(not soundConfig[propertyName]) then continue end
		if(propertyName == "SoundId") then
			sound.SoundId = "rbxassetid://"..propertyValue
		elseif(sound[propertyName] ~= nil) then
			sound[propertyName] = propertyValue

		elseif(propertyName == "Children") then
			
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

	const sound = ClientSoundReplicationService.SetUpSoundFromSoundConfig(soundConfig)
	if not sound then return end

	sound.Parent = part
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function ClientSoundReplicationService.PlaySoundFromPosition(position: Vector3, soundConfig: SoundConfig.SoundConfig): Attachment?
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

	const sound = ClientSoundReplicationService.SetUpSoundFromSoundConfig(soundConfig)
	if not sound then
		attachment:Destroy()
		return
	end

	sound.Parent = attachment
	attachment.Name = "SoundAttachment"
	attachment.Parent = workspace
	sound:Play()

	sound.Ended:Once(function()
		sound:Destroy()
		attachment:Destroy()
	end)
	return attachment
end

return ClientSoundReplicationService
