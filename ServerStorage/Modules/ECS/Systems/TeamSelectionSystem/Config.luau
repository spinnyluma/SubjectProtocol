const Teams = game:GetService("Teams")
const ServerStorage = game:GetService("ServerStorage")

const Tools = ServerStorage.Assets.Tools

local Config = {}

const securityDoorKeycard = Tools.Cards.SecurityDoorKeycard
const pistol = Tools.Weapons.Ranged.Hitscan.Pistol
Config.teamOnSpawnTools = {
	[Teams.Guards] = {securityDoorKeycard, pistol}
}

return Config
