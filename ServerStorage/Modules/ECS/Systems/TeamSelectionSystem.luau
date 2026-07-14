local ReplicatedStorage = game:GetService("ReplicatedStorage")

local selectTeamRE = ReplicatedStorage.Assets.Shared.Remotes.Events.SelectTeam

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)


local TeamSelectionSystem = {}

local function PlayerCanChangeTeam(player: Player)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
			and player:IsA("Player"),
		player,
		"player",
		"PlayerCanChangeTeam",
		"Player"
	)
	if not playerIsValid then return false end
	
	local playerTeam = player.Team
	local playerTeamIsValid = typeof(playerTeam) == "Instance"
		and playerTeam:IsA("Team")
	if not playerTeamIsValid then return false end
	
	return playerTeam == TeamConfig.teams.Choosing.Team
end

local function SetPlayerTeam(player: Player, selectedTeam: Team)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
			and player:IsA("Player"),
		player,
		"player",
		"SetPlayerTeam",
		"Player"
	)
	if not playerIsValid then return end
	
	local selectedTeamIsValid = typeof(selectedTeam) == "Instance"
		and selectedTeam:IsA("Team")
	if(not selectedTeamIsValid) then return end
	
	local playerCanChangeTeam = PlayerCanChangeTeam(player)
	if(playerCanChangeTeam) then
		player.Team = selectedTeam
	end
end

function TeamSelectionSystem.Initialize()
	selectTeamRE.OnServerEvent:Connect(function(player: Player, selectedTeam: Team)
		SetPlayerTeam(player, selectedTeam)	
	end)
end

return TeamSelectionSystem
