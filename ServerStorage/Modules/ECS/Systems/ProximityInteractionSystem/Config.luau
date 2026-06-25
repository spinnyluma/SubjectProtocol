local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Config = {}

Config.parentTagNames = {
	T_Keycard = "T_SecurityDoor",
	T_Terminal = "T_Player"
}


Config.proximityInteractionTypes = {
	T_Keycard = {
		Name = "T_Keycard",
		Value = 0
	},
	T_Terminal = {
		Name = "T_Terminal",
		Value = 1
	}
}

Config.SYSTEM_TAG_NAME = "T_Proximity"
Config.INTERACTION_RADIUS_ATTR_NAME = "A_ProximityRadius"

return Config
