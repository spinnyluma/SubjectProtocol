const Teams = game:GetService("Teams")

const ModeConfig = require("../../../Shared/Constants/ModeConfig")


local Config = {}
Config.modeObjectives = {
	[ModeConfig.modes.Idle.Name] = {
		[Teams.Guards] = {
			Objective = "Prevent the subjects from capturing the terminal"
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
			Objective = "Avoid getting detained by the subjects",
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
return Config
