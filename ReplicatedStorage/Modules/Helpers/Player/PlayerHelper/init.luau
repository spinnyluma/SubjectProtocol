local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local PlayerHelperConstants = require(script.PlayerHelperConstants)

local PlayerHelper = {}

local function NearestPlayerCompare(
	element1: {[string]: Player | number},
	element2: {[string]: Player | number}
): boolean
	return element1["Distance"] < element2["Distance"]	
end

--[[
	Gets a sorted list of players from nearest to furthest in amount of studs from a particular position.
	
	@param Vector3 position The position to get the nearest players from.
	@returns {[number]: {[string]: Player | number}} A sorted list of players from nearest to furthest in amount of studs from a particular position.
	{
		[<Index>] = {
			["Player"] = <Player>,
			["Distance"] = <number>
		}
	}
]]
function PlayerHelper.GetNearestPlayersFromPosition(position: Vector3): {[number]: {[string]: Player | number}}
	local positionIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(position) == "Vector3",
		position,
		"position",
		"PlayerHelper.GetNearestPlayersFromPosition",
		"Vector3"
	)
	if(not positionIsValid) then
		return nil
	end
	
	local nearestPlayers: {[number]: {[string]: Player | number}} = {}
	
	local players: {Player} = Players:GetPlayers()
	
	for _, player in players do
		local positionToCharacterDistance: number = player:DistanceFromCharacter(position)
		table.insert(nearestPlayers, {
			["Player"] = player,
			["Distance"] = positionToCharacterDistance
		})
	end
	
	table.sort(nearestPlayers, NearestPlayerCompare)
	return nearestPlayers
end

function PlayerHelper.GetPlayerIntersectCharOverlapParams()
	return PlayerHelperConstants._playerIntersectCharOverlapParams
end



return PlayerHelper
