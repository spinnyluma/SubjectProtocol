local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Modules.Utilities.t)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local SystemManagerModule = require(ReplicatedStorage.Modules.ECS.SystemManagerModule)

local CuffService = {}

function CuffService.RemovePlayerFromInvolvedInCuffing(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")

	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if(not playerIsValid) then
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end

	const globalCuffedPlayers = SystemManagerModule.GetGlobalGameState("CuffedPlayers")
	if(not globalCuffedPlayers) then return false end
	globalCuffedPlayers[player] = nil

	for cuffer, cuffedPlayer in globalCuffedPlayers do
		if(cuffedPlayer == player) then
			globalCuffedPlayers[cuffer] = nil
		end
	end
	return true
end

return CuffService