local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local PlayerConfig = require(script.Config)

local PlayerSystem = {}

local function AddTags(playerCharacter: Model)
	local playerCharacterIsValid = AssertHelper.InvalidArgAssert(
		typeof(playerCharacter) == "Instance"
			and playerCharacter:IsA("Model"),
		playerCharacter,
		"playerCharacter",
		"AddTags",
		"Model"
	)
	if(not playerCharacterIsValid) then return end
	CollectionService:AddTag(playerCharacter, PlayerConfig.PLAYER_TAG_NAME)
end

const function AddPlayerCollisionGroup(character: Model)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = "CG_Player"
		end
	end
end

function PlayerSystem.Initialize()
	
	for _, player in Players:GetPlayers() do
		const character = player.Character
		if(character) then
			
			AddTags(character)
			AddPlayerCollisionGroup(character)
		end
		player.CharacterAdded:Connect(function(character)
			AddTags(character)
			AddPlayerCollisionGroup(character)
		end)
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			AddTags(character)
			AddPlayerCollisionGroup(character)
		end)
	end)
end

return PlayerSystem
