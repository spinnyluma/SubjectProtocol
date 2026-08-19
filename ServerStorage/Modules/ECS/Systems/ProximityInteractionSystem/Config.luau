local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Config = {}

Config.parentTagNames = {
	T_Keycard = "T_SecurityDoor",
	T_Terminal = "T_Player",
	T_SafeZone = "T_Player",
	T_CellImprisonment = "T_Player"
}


Config.proximityInteractionTypes = {
	T_Keycard = {
		Name = "T_Keycard",
		Value = 0
	},
	T_Terminal = {
		Name = "T_Terminal",
		Value = 1
	},
	T_SafeZone = {
		Name = "T_SafeZone",
		Value = 2
	},
	T_CellImprisonment = {
		Name = "T_CellImprisonment",
		Value = 3
	}
}

Config.SYSTEM_TAG_NAME = "T_Proximity"
Config.INTERACTION_RADIUS_ATTR_NAME = "A_ProximityRadius"

return Config
