local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local t = require(ReplicatedStorage.Modules.Utilities.t)

const PlayerDataServiceSignals = require("@self/Signals")

local PlayerDataService = {}

local profileCache: {[Player]: {[string]: any}} = {}

local checkPlayer = t.instanceIsA("Player")
local checkProfile = t.table

function PlayerDataService.AddProfile(player: Player, profile: {[string]: any})
	local playerIsValid, playerInvalidReason = checkPlayer(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidReason)
		return false
	end

	local profileIsValid, profileInvalidReason = checkProfile(profile)
	if not profileIsValid then
		AssertHelper.Warn(profileInvalidReason)
		return false
	end

	profileCache[player] = profile
	PlayerDataServiceSignals.PlayerDataLoaded:Fire(player, profile)
	return true
end

function PlayerDataService.RemoveProfile(player: Player)
	local playerIsValid, playerInvalidReason = checkPlayer(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidReason)
		return false
	end

	profileCache[player] = nil
	return true
end

function PlayerDataService.GetProfile(player: Player): {[string]: any}?
	local playerIsValid, playerInvalidReason = checkPlayer(player)
	if not playerIsValid then
		AssertHelper.Warn(playerInvalidReason)
		return nil
	end

	return profileCache[player]
end

return PlayerDataService
