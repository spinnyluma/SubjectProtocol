local ReplicatedStorage = game:GetService("ReplicatedStorage")



local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)

local Config = {}

export type TracerParams = {
	Team: Team?
}


Config.DAMAGEABLE_TAG_NAME = "T_Damageable"

Config.HEALTH_ATTR_NAME = "A_Health"

Config.MAX_HEALTH_ATTR_NAME = "A_MaxHealth"
return Config
