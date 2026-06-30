local ModeConfig = {}

export type Mode = keyof<typeof(ModeConfig.modes)>

ModeConfig.modes = {
	["TurretOverride"] = {
		Name = "TurretOverride",
		UserFriendlyName = "Turret Override",
		Value = 0
	}
}

ModeConfig.modeDescriptions = {
	[ModeConfig.modes.TurretOverride.Name] = {
		Description = "Turrets will target guards.",
		Value = 0
	}
}

ModeConfig.NUMBER_OF_MODES = 3

return ModeConfig
