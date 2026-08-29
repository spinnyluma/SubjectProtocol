const ReplicatedStorage = game:GetService("ReplicatedStorage")

const particle2dFolder = ReplicatedStorage.Assets.Emitter.Particle2D


local Config = {}

Config.SYSTEM_TAG_NAME = "T_Particle2d"
Config.PARTICLE_2D_NAME_ATTR_NAME = "A_Particle2dName"
Config.particleEmitterNames = {
	Lightning = {
		Name = "Lightning",
		Value = 0,
		Particles = particle2dFolder.Lightning:GetChildren(),
	}
}

return Config
