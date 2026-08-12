const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Modules = ReplicatedStorage.Modules

const Helpers = Modules.Helpers
const Shared = Modules.Shared

const Debug = Helpers.Debug

const Constants = Shared.Constants

const Sound = Constants.Sound

const AssertHelper = require(Debug.AssertHelper)
const SoundConfig = require(Sound.SoundConfig)

local SoundReplicationService = {}

const replicateSoundRE = ReplicatedStorage.Assets.Shared.Remotes.Events.ReplicateSound


function SoundReplicationService.ReplicateSound(players: {Player}, 
	soundConfig: SoundConfig.SoundConfig	
)
	const playersIsValid = AssertHelper.InvalidArgAssert(
		type(players) == "table",
		players,
		"players",
		"SoundReplicationService.ReplicateSound",
		"table"
	)
	if(not players) then return end
	
	const soundConfigIsValid = AssertHelper.InvalidArgAssert(
		type(soundConfig) == "table",
		soundConfig,
		"soundConfig",
		"SoundReplicationService.ReplicateSound",
		"table"
	)
	if(not soundConfig) then return end
	
	for _, player in players do
		replicateSoundRE:FireClient(player, soundConfig)

	end
end

return SoundReplicationService
