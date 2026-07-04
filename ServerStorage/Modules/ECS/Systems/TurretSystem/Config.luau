local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModeConfig = require(ReplicatedStorage.Modules.Shared.Constants.ModeConfig)
local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)


local Config = {}

Config.TURRET_DAMAGE = 10

Config.modeToTurretTargetedTeams = {
	[ModeConfig.modes.Idle.Name] = {},
	[ModeConfig.modes.TurretOverride.Name] = {TeamConfig.teams.Subjects.Team}
}

return Config
