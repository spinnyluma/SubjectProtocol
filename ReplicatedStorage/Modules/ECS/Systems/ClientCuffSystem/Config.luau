local Config = {}

Config.constraintTypes = {
	AlignPosition = {
		Name = "AlignPosition",
		Value = 0
	},
	AlignOrientation = {
		Name = "AlignOrientation",
		Value = 1
	}
}

Config.cuffStates = {
	["Cuffing"] = {
		Name = "Cuffing",
		Value = 0
	},
	["Idle"] = {
		Name = "Idle",
		Value = 1
		
	}
}

return Config
