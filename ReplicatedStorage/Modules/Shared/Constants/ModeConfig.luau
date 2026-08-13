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
	FacilityBombardment = {
		Name = "FacilityBombardment",
		UserFriendlyName = "Facility Bombardment",
		Value = 2
	}
}

ModeConfig.modeDescriptions = {
	[ModeConfig.modes.Idle.Name] = {
		Description = "The idle mode state.",
		Value = 0
	},
	[ModeConfig.modes.TurretOverride.Name] = {
		Description = "Turrets will target guards for a specific period of time.",
		Value = 1
	},
	[ModeConfig.modes.FacilityBombardment.Name] = {
		Description = "Grenades will launch throughout the facility for a specific period of time.",
		Value = 2
	}
}

ModeConfig.NUMBER_OF_MODES = 3
ModeConfig.MODE_VOTE_TIME = 2

ModeConfig.MODE_DURATION = 10
return ModeConfig
