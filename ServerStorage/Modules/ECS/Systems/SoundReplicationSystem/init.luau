const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Modules = ReplicatedStorage.Modules

const Shared = Modules.Shared

const Constants = Shared.Constants

const Sound = Constants.Sound

const SoundConfig = require(Sound.SoundConfig)

local SoundReplicationSystemConfig = require("@self/Config")

const replicateSoundRE = ReplicatedStorage.Assets.Shared.Remotes.Events.ReplicateSound

local SoundReplicationSystem = {}

function SoundReplicationSystem.Initialize()
	
end

return SoundReplicationSystem
