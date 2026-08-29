local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Modules = ReplicatedStorage.Modules

local Shared = Modules.Shared

local Constants = Shared.Constants

const Hint = Constants.Hint

const HintConfig = require(Hint.HintConfig)
local ModeConfig = require(Constants.ModeConfig)

local Config = {}

Config.MODE_COOLDOWN = 5

Config.modeObjectives = {
	[ModeConfig.modes.Idle.Name] = {
		[Teams.Guards] = {
			Objective = "Prevent the guards from capturing the terminal"
		},
		[Teams.Subjects] = {
			Objective = "Capture the terminal"
		}
	},
	[ModeConfig.modes.TurretOverride.Name] = {
		[Teams.Guards] = {
			Objective = "Shoot and survive the turrets"
		},
		[Teams.Subjects] = {
			Objective = "Take advantage of the turrets targeting the guards"
		}
	},
	[ModeConfig.modes.RoleReversal.Name] = {
		[Teams.Guards] = {
			Objective = "Avoid getting detained by the subjects"
		},
		[Teams.Subjects] = {
			Objective = "Detain the guards"
		}
	},
	[ModeConfig.modes.FacilityBombardment.Name] = {
		[Teams.Guards] = {
			Objective = "Take cover from the incoming bombs"
		},
		[Teams.Subjects] = {
			Objective = "Take cover from the incoming bombs"
		}
	}
}


Config.modeChangedHints = {
	[ModeConfig.modes.Idle.Name] = {
		Name = "Idle",
		Hint = "Attention. Facility systems restored.",
		HintColor = HintConfig.hintColors.Info.Name
	},
	[ModeConfig.modes.TurretOverride.Name] = {
		Name = "TurretOverride",
		Hint = "Attention. Turrets have been overridden.",
		HintColor = HintConfig.hintColors.Warning.Name
	},
	[ModeConfig.modes.RoleReversal.Name] = {
		Name = "RoleReversal",
		Hint = "Warning. Subjects are authorized to detain guards.",
		HintColor = HintConfig.hintColors.Warning.Name
		
	},
	[ModeConfig.modes.FacilityBombardment.Name] = {
		Name = "FacilityBombardment",
		Hint = "Warning. Weapon systems have been enabled.",
		HintColor = HintConfig.hintColors.Warning.Name
	},
	
		
}

return Config
