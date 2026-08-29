const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Helpers = Modules.Helpers
const ECS = Modules.ECS

const Debug = Helpers.Debug

const SystemManagerModule = require(ECS.SystemManagerModule)
const AssertHelper = require(Debug.AssertHelper)
const t = require(Utilities.t)

local CuffHelper = {}

function CuffHelper.IsPlayerInvolvedInCuffing(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return true
	end


	const globalCuffedPlayers = SystemManagerModule.GetGlobalGameState("CuffedPlayers")
	if not globalCuffedPlayers then return false end

	const playerIsCuffing = globalCuffedPlayers[player]

	if not playerIsCuffing then 
		for _, cuffedPlayer in globalCuffedPlayers do
			if cuffedPlayer == player then
				return true
			end
		end
	else
		return true
	end

	return false
end



function CuffHelper.IsPlayerCuffed(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end

	const globalCuffedPlayers = SystemManagerModule.GetGlobalGameState("CuffedPlayers")
	if not globalCuffedPlayers then return false end

	-- globalCuffedPlayers maps cuffing players to cuffed players.
	-- A player is cuffed if they appear as a value in this table.
	for _, cuffedPlayer in globalCuffedPlayers do
		if cuffedPlayer == player then
			return true
		end
	end

	return false
end

return CuffHelper
