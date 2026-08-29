const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")
const Players = game:GetService("Players")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities

const AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
const t = require(Utilities.t)

const PlayerDataServiceSignals = require("../../Services/PlayerData/PlayerDataService/Signals")
const PlayerDataService = require("../../Services/PlayerData/PlayerDataService")
const ReplicaConfig = require("../../Constants/ReplicaConfig")
const ProfileStore = require("../../Utilities/ProfileStore")
const Replica = require("../../Utilities/ReplicaServer")

const playerReplicas: {[Player]: typeof(Replica)} = {}

local checkPlayer = t.instanceIsA("Player")

local function CreatePlayerStatsReplica(player: Player)
	local playerIsValid, playerInvalidReason = checkPlayer(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidReason)
		return
	end

	const profile = PlayerDataService.GetProfile(player)
	
	if not profile then
		return
	end
	
	if(not Replica.ReadyPlayers[player]) then
		return
	end
	
	const tokens = profile.Data.Tokens
	const tokensIsValid, tokensInvalidReason = t.number(tokens)
	if not tokensIsValid then
		AssertHelper.Warn(tokensInvalidReason)
		return
	end
	
	const titles = profile.Data.Items.Titles
	const titlesIsValid, titlesInvalidReason = t.table(titles)
	if not titlesIsValid then
		AssertHelper.Warn(titlesInvalidReason)
		return
	end
	
	const replica = Replica.New({
		Token = ReplicaConfig.tokens.PlayerStats.Token,
		Tags = {UserId = player.UserId},
		Data = {
			Tokens = tokens,
			Items = {
				Titles = titles
			}
		},
	})

	playerReplicas[player] = replica
	
	replica:Subscribe(player)
end

local function DestroyPlayerStatsReplica(player: Player)
	local playerIsValid, playerInvalidReason = checkPlayer(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidReason)
		return
	end

	const replica = playerReplicas[player]
	if replica then
		replica:Destroy()
		playerReplicas[player] = nil
	end
end

local PlayerStatsSystem = {}

function PlayerStatsSystem.GetReplica(player: Player)
	local playerIsValid, playerInvalidReason = checkPlayer(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidReason)
		return nil
	end
	return playerReplicas[player]
end

function PlayerStatsSystem.SetTokens(player: Player, newTokens: number)
	local playerIsValid, playerInvalidReason = checkPlayer(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidReason)
		return false
	end
	local tokensIsValid, tokensInvalidReason = t.number(newTokens)
	if not tokensIsValid then
		AssertHelper.Warn(tokensInvalidReason)
		return false
	end
	if newTokens ~= newTokens then
		AssertHelper.Warn("unexpected NaN value")
		return false
	end
	const replica = playerReplicas[player]
	if not replica then
		AssertHelper.Warn(`[PlayerStatsSystem] No replica for {player.Name}`)
		return false
	end
	replica:Set({"Tokens"}, newTokens)
	return true
end

function PlayerStatsSystem.SetItemOwned(player: Player, itemType: string, itemName: string)
	local playerIsValid, playerInvalidReason = checkPlayer(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidReason)
		return false
	end
	local itemTypeIsValid, itemTypeInvalidReason = t.string(itemType)
	if not itemTypeIsValid then
		AssertHelper.Warn(itemTypeInvalidReason)
		return false
	end
	local itemNameIsValid, itemNameInvalidReason = t.string(itemName)
	if not itemNameIsValid then
		AssertHelper.Warn(itemNameInvalidReason)
		return false
	end
	const replica = playerReplicas[player]
	if not replica then
		AssertHelper.Warn(`[PlayerStatsSystem] No replica for {player.Name}`)
		return false
	end
	const path = {"Items", itemType, "Owned", itemName}
	replica:Set(path, true)
	return true
end

function PlayerStatsSystem.SetEquipped(player: Player, itemType: string, itemName: string?)
	local playerIsValid, playerInvalidReason = checkPlayer(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidReason)
		return false
	end
	local itemTypeIsValid, itemTypeInvalidReason = t.string(itemType)
	if not itemTypeIsValid then
		AssertHelper.Warn(itemTypeInvalidReason)
		return false
	end
	if itemName ~= nil then
		local itemNameIsValid, itemNameInvalidReason = t.string(itemName)
		if not itemNameIsValid then
			AssertHelper.Warn(itemNameInvalidReason)
			return false
		end
	end
	const replica = playerReplicas[player]
	if not replica then
		AssertHelper.Warn(`[PlayerStatsSystem] No replica for {player.Name}`)
		return false
	end
	local equipped = itemName
	local path = {"Items", itemType, "Equipped"}
	replica:Set(path, equipped)
	return true
end

function PlayerStatsSystem.PostInitialize()
	for _, player in Players:GetPlayers() do
		task.spawn(CreatePlayerStatsReplica, player)
	end

	Replica.NewReadyPlayer:Connect(function(player: Player)
		const profile = PlayerDataService.GetProfile(player)
		const profileIsValid = t.table(profile)
		if(not profileIsValid) then
			PlayerDataServiceSignals.PlayerDataLoaded:Once(function(profilePlayer: Player, profile)
				print("creating ")

				CreatePlayerStatsReplica(player)
			end)
		else
			CreatePlayerStatsReplica(player)
		end
		
	end)
	
	Replica.RemovingReadyPlayer:Connect(function(player: Player)
		print("destorying")
		DestroyPlayerStatsReplica(player)
	end)
	Players.PlayerRemoving:Connect(DestroyPlayerStatsReplica)
	
	PlayerDataServiceSignals.PlayerDataLoaded:Connect(function(player: Player, profile)
		CreatePlayerStatsReplica(player)
	end)
end

return PlayerStatsSystem
