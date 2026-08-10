const ServerStorage = game:GetService("ServerStorage")
const toolsFolder = ServerStorage.Assets.Tools

local Config = {}

Config.tools = {
	Pipe = {
		Name = "Pipe",
		Value = 0,
		Tool = toolsFolder.Weapons.Melee.Pipe
	},
	SecurityDoorKeycard = {
		Name = "SecurityDoorKeycard",
		Value = 1,
		Tool = toolsFolder.Cards.SecurityDoorKeycard
	},
	Pistol = {
		Name = "Pistol",
		Value = 2,
		Tool = toolsFolder.Weapons.Ranged.Hitscan.Pistol
	}
}
return Config
