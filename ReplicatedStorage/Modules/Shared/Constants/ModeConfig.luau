const Teams = game:GetService("Teams")

local ModeConfig = {}

export type Mode = keyof<typeof(ModeConfig.modes)>

ModeConfig.modes = {
	Idle = {
		Name = "Idle",
		UserFriendlyName = "Normal",
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
	},
	RoleReversal = {
		Name = "RoleReversal",
		UserFriendlyName = "Role Reversal",
		Value = 3
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
	},
	[ModeConfig.modes.RoleReversal.Name] = {
		Description = "Subjects are allowed to cuff guards and place them in jail cells.",
		Value = 3
	}
}

ModeConfig.NUMBER_OF_MODES = 3
ModeConfig.MODE_VOTE_TIME = 10

ModeConfig.MODE_DURATION = 120
return ModeConfig
