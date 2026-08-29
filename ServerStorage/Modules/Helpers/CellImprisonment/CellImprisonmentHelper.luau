const ServerStorage = game:GetService("ServerStorage")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Modules = ReplicatedStorage.Modules

const ECS = Modules.ECS
const Helpers = Modules.Helpers

const Debug = Helpers.Debug

const AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
const t = require(Modules.Utilities.t)
const CellImprisonmentSystem = require(ServerStorage.Modules.ECS.Systems.CellImprisonmentSystem)

local CellImprisonmentHelper = {}

function CellImprisonmentHelper.IsPlayerImprisoned(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end

	const imprisonmentReplica = CellImprisonmentSystem.imprisonmentReplicas[player]
	if not imprisonmentReplica then
		return false
	end

	return imprisonmentReplica.Data.Active == true
end

return CellImprisonmentHelper
