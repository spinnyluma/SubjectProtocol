const ReflectionService = game:GetService("ReflectionService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const replicateSoundRE = ReplicatedStorage.Assets.Shared.Remotes.Events.ReplicateSound

const ClientSoundReplicationService = require("../../Services/SoundReplication/ClientSoundReplicationService")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const SoundConfig = require("../../Shared/Constants/Sound/SoundConfig")

local ClientSoundReplicationSystem = {}


local function PlaySound(soundConfig: SoundConfig.SoundConfig)
	const soundConfigIsValid = AssertHelper.InvalidArgAssert(
		type(soundConfig) == "table",
		soundConfig,
		"soundConfig",
		"ClientSoundReplicationSystem.PlaySound",
		"table"
	)
	if not soundConfigIsValid then return end
	
	const emittingPart = soundConfig.EmittingPart
	const emittingPosition = soundConfig.EmittingPosition
	if(not emittingPart
		and (not emittingPosition)) then return end
	print("palying sound")
	if(emittingPart) then
		ClientSoundReplicationService.PlaySoundFromPart(emittingPart, soundConfig)
	elseif(emittingPosition) then
		ClientSoundReplicationService.PlaySoundFromPosition(emittingPosition, soundConfig)
	end
end

function ClientSoundReplicationSystem.Initialize()
	replicateSoundRE.OnClientEvent:Connect(function(soundConfig: SoundConfig.SoundConfig)
		PlaySound(soundConfig)
	end)
end

return ClientSoundReplicationSystem
