const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const ECS = Modules.ECS

const Systems = ECS.Systems

const ClientShopSystemConfig = require(Systems.ClientShopSystem.Config)
const t = require(Utilities.t)

const PlayerDataService = require("../../Services/PlayerData/PlayerDataService")
const ProfileStore = require("../../Utilities/ProfileStore")

const PROFILE_TEMPLATE = {
	Tokens = 0,
	Items = {
		[ClientShopSystemConfig.itemTypes.Titles.Name] = {
			Owned = {},
			Equipped = nil
		}
	}
}

const PlayerDataStore = ProfileStore.New("PlayerData", PROFILE_TEMPLATE)

local PlayerDataSystem = {}

const function PlayerAdded(player: Player)
	const playerUser = player.User
	const domainUserId = playerUser.Id
	const profile = PlayerDataStore:StartSessionAsync(`{playerUser.Id}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if(profile ~= nil) then
		profile:AddUserId(player.User.Id)
		profile:Reconcile()
		
		PlayerDataService.AddProfile(player, profile)
		
		profile.OnSessionEnd:Connect(function()
			PlayerDataService.RemoveProfile(player)
			player:Kick("Profile session end - Please rejoin")
		end)
	else
		player:Kick("Profile load fail - Please rejoin")
	end
end



function PlayerDataSystem.Initialize()
	for _, player in Players:GetPlayers() do
		task.spawn(PlayerAdded, player)
	end	
	
	Players.PlayerAdded:Connect(PlayerAdded)
	
	Players.PlayerRemoving:Connect(function(player)
		local profile = PlayerDataService.GetProfile(player)
		if(profile ~= nil) then
			profile:EndSession()
		end
		PlayerDataService.RemoveProfile(player)
	end)
end

return PlayerDataSystem
