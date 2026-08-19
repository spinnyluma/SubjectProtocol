const CollectionService = game:GetService("CollectionService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Helpers = Modules.Helpers
const Shared = Modules.Shared
const ECS = Modules.ECS

const Debug = Helpers.Debug
const Time = Helpers.Time

const Constants = Shared.Constants

const CellImprisonment = Constants.CellImprisonment

const CellImprisonmentConfig = require(CellImprisonment.CellImprisonmentConfig)
const SystemManagerModule = require(ECS.SystemManagerModule)
const AssertHelper = require(Debug.AssertHelper)
const ModeConfig = require(Constants.ModeConfig)
const TimeHelper = require(Time.TimeHelper)
const Promise = require(Utilities.Promise)
const t = require(Utilities.t)

const ProximityInteractionSystemSignals = require("./ProximityInteractionSystem/Signals")
const ProximityInteractionSystemConfig = require("./ProximityInteractionSystem/Config")
const CellImprisonmentSystemConfig = require("@self/Config")
const NetworkService = require("../../Services/Network/NetworkService")
const ReplicaConfig = require("../../Constants/ReplicaConfig")
const SpawnService = require("../../Services/Spawn/SpawnService")
const CuffService = require("../../Services/Cuff/CuffService")
const Replica = require("../../Utilities/ReplicaServer")

const imprisonPlayerRE = ReplicatedStorage.Assets.Shared.Remotes.Events.CellImprisonment.ImprisonPlayer


local CellImprisonmentSystem = {}


const imprisonmentReplicas: {[Player]: Replica.Replica} = {}

const function ValidatePlayerToImprison(playerImprisoning: Player, playerToImprison: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(playerToImprison)
	if(not playerIsValid) then
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end
	
	if(playerImprisoning == playerToImprison) then
		return false
	end
	
	const globalCuffedPlayers = SystemManagerModule.GetGlobalGameState("CuffedPlayers")
	
	if(not globalCuffedPlayers) then
		return false
	end	
	
	const currentFacilityMode = SystemManagerModule.GetGlobalGameState("CurrentMode")
	if(currentFacilityMode ~= ModeConfig.modes.RoleReversal.Name) then return false end
	
	if(globalCuffedPlayers[playerImprisoning] ~= playerToImprison) then
		return false
	end
	
	return true
end

const function TeleportPlayerToJailCell(playerToImprison: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	
	const playerIsValid, playerInvalidityReason = playerIsValidFn(playerToImprison)
	if(not playerIsValid) then
		AssertHelper.Warn(playerInvalidityReason)
		return
	end
	
	const teleportPoints = CollectionService:GetTagged(CellImprisonmentConfig.TELEPORT_TAG_NAME)
	if #teleportPoints == 0 then return end

	const randomTeleport = teleportPoints[math.random(1, #teleportPoints)]
	const teleportPart = randomTeleport:FindFirstChild("Part")
	if not teleportPart then return end

	const character = playerToImprison.Character
	if not character then  return end

	character:PivotTo(teleportPart.CFrame)
	print("pivoted to")	
end

const function CreateImprisonPlayerReplica(player: Player): Replica.Replica?
	const playerIsValidFn = t.instanceIsA("Player")
	
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if(not playerIsValid) then
		AssertHelper.Warn(playerInvalidityReason)
		return nil
	end
	
	if(imprisonmentReplicas[player]) then
		return imprisonmentReplicas[player]
	end
	
	const imprisonmentReplica = Replica.New({
		Data = {
			Active = false,
			RespawnTime = CellImprisonmentSystemConfig.IMPRISONMENT_TIME
		},
		Tags = {
			Player = player
		},
		Token = ReplicaConfig.tokens.CellImprisonment.Token
	})
	
	imprisonmentReplicas[player] = imprisonmentReplica
	
	return imprisonmentReplica
end


const function CountdownRespawnTimer(replica: Replica.Replica)
	const replicaIsValid, replicaInvalidityReason = t.table(replica)
	if(not replicaIsValid) then
		AssertHelper.Warn(replicaInvalidityReason)
		return
	end
	const respawnTime = replica.Data.RespawnTime
	if(not respawnTime) then
		AssertHelper.Warn("[CellImprisonmentSystem] No RespawnTime in replica")
		return
	end
	
	replica:Set({"Active"}, true)
	
	
	TimeHelper.CreateCountdownInSecondsPrecise(respawnTime, function(secondsRemaining: number)
		print(secondsRemaining)
		replica:Set({"RespawnTime"}, secondsRemaining)
	end)
	
	replica:Set({"Active"}, false)
end

const function ResetImprisonmentReplica(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if(not playerIsValid) then
		AssertHelper.Warn(playerInvalidityReason)
		return
	end
	
	
	const imprisonmentReplica: Replica.Replica = imprisonmentReplicas[player]
	if(not imprisonmentReplica) then return end

	imprisonmentReplica:Set({"Active"}, false)
	imprisonmentReplica:Set({"RespawnTime"}, CellImprisonmentSystemConfig.IMPRISONMENT_TIME)
end

function CellImprisonmentSystem.Initialize()
	
	imprisonPlayerRE.OnServerEvent:Connect(function(player: Player, playerToImprison: Player)
		const playerIsValidFn = t.instanceIsA("Player")
		const playerToImprisonIsValid, playerToImprisonInvalidityReason = playerIsValidFn(playerToImprison)
		if(not playerToImprisonIsValid) then
			return
		end
		
		const playerImprisonValid = ValidatePlayerToImprison(player, playerToImprison)
		if(not playerImprisonValid) then return end
		
		NetworkService.SetPlayerNetworkOwnership(playerToImprison)
		const cufferPlayerEntryRemoved: boolean = CuffService.RemovePlayerFromInvolvedInCuffing(player)
		if(not cufferPlayerEntryRemoved) then 
			AssertHelper.Warn("[CellImprisonmentSystem] Failed to remove cuffer player entry")
			return 
		end
		
		CollectionService:AddTag(playerToImprison, CellImprisonmentConfig.IMPRISONED_TAG_NAME)
		
		TeleportPlayerToJailCell(playerToImprison)
		const replica = CreateImprisonPlayerReplica(playerToImprison)
		if(not replica) then return end
		Promise.try(function()
			replica:Subscribe(playerToImprison)

			CountdownRespawnTimer(replica)
			SpawnService.ReloadCharacterAndSpawnOnTeamSpawn(playerToImprison)
			replica:Unsubscribe(playerToImprison)
		end)
			:catch(function(err)
				AssertHelper.Warn(tostring(err))
			end)
		
	end)
	
	--ProximityInteractionSystemSignals.ProximityObjectsFound:Connect(function(interactionType: string,
	--	proximityObjects: {[Instance]: {Instance?}?})
	--	if(interactionType == ProximityInteractionSystemConfig.proximityInteractionTypes.T_CellImprisonment.Name) then

	--	end
	--end)
end


return CellImprisonmentSystem
