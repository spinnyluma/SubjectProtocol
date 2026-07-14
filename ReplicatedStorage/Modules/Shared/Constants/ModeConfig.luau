local ModeConfig = {}

export type Mode = keyof<typeof(ModeConfig.modes)>

ModeConfig.modes = {
	Idle = {
		Name = "Idle",
		UserFriendlyName = "Idle",
		Value = 0
	},
	TurretOverride = {
		Name = "TurretOverride",
		UserFriendlyName = "Turret Override",
		Value = 1
	},
}

ModeConfig.modeDescriptions = {
	[ModeConfig.modes.Idle.Name] = {
		Description = "The idle mode state.",
		Value = 0
	},
	[ModeConfig.modes.TurretOverride.Name] = {
		Description = "Turrets will target guards.",
		Value = 1
	}
}

ModeConfig.NUMBER_OF_MODES = 3
ModeConfig.MODE_VOTE_TIME = 2

ModeConfig.MODE_DURATION = 30
return ModeConfig
