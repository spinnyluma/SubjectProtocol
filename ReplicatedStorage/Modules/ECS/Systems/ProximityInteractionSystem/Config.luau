local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Config = {}

Config.parentTagNames = {
	T_Keycard = "T_SecurityDoor",
	T_Terminal = "T_Player",
	T_SafeZone = "T_Player",
	T_CellImprisonment = "T_Player",
	T_Shop = "T_Player",
	T_ShopClose = "T_Player"
}

Config.spatialQueryRunContexts = {
	Client = {
		Name = "Client",
		Value = 0
	},
	Server = {
		Name = "Server",
		Value = 1
	},
	Shared = {
		Name = "Shared",
		Value = 2
	}
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
	},
	T_Shop = {
		Name = "T_Shop",
		Value = 4
	}
}

Config.SYSTEM_TAG_NAME = "T_Proximity"
Config.INTERACTION_RADIUS_ATTR_NAME = "A_ProximityRadius"
Config.SPATIAL_QUERY_RUN_CONTEXT_ATTR_NAME = "A_SpatialQueryRunContext"

return Config
