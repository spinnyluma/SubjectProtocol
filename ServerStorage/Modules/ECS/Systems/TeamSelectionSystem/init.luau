local ReplicatedStorage = game:GetService("ReplicatedStorage")

local selectTeamRE = ReplicatedStorage.Assets.Shared.Remotes.Events.SelectTeam
const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Helpers = Modules.Helpers

const Table = Helpers.Table

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
const TableHelper = require(Table.TableHelper)
local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)
const t = require(Utilities.t)

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
const ToolService = require(ServerStorage.Modules.Services.Tool.ToolService)
const Config = require(script.Config)

const guardSpawns = workspace.GuardSpawns
const subjectSpawns = workspace.SubjectSpawns

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
	if(not selectedTeamIsValid) then return false end
	
	local playerCanChangeTeam = PlayerCanChangeTeam(player)
	if(playerCanChangeTeam) then
		player.Team = selectedTeam
		return true
	else
		return false

	end
	
end

const function SpawnPlayerOnTeamSpawn(player: Player, selectedTeam: Team)
	const playerIsValidFn = t.instanceIsA("Player")
	
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if(not playerIsValid) then
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end
	
	local selectedTeamIsValidFn = t.instanceIsA("Team")
	local selectedTeamIsValid, selectedTeamInvalidityReason = selectedTeamIsValidFn(selectedTeam)
	if(not selectedTeamIsValid) then
		AssertHelper.Warn(selectedTeamInvalidityReason)
		return false
	end
	
	const character = player.Character
	if(not character) then return false end
	
	if(selectedTeam == TeamConfig.teams.Guards.Team) then
		const guardSpawnsTable = guardSpawns:GetChildren()
		const randomSpawn = TableHelper.GetRandomValueFromTable(guardSpawnsTable)
		if(not randomSpawn) then return false end
		character:PivotTo(randomSpawn.CFrame)
	else
		const subjectSpawnsTable = subjectSpawns:GetChildren()
		const randomSpawn = TableHelper.GetRandomValueFromTable(subjectSpawnsTable)
		if(not randomSpawn) then return false end
		character:PivotTo(randomSpawn.CFrame)
	end
	
	return true
end

local function GivePlayerTeamTools(player: Player, selectedTeam: Team)
	local teamTools = Config.teamOnSpawnTools[selectedTeam]
	if not teamTools then return end

	for _, tool in teamTools do
		ToolService.GiveTool(player, tool)
	end
end

function TeamSelectionSystem.Initialize()
	selectTeamRE.OnServerEvent:Connect(function(player: Player, selectedTeam: Team)
		const setPlayerTeam = SetPlayerTeam(player, selectedTeam)	
		if(not setPlayerTeam) then return end
		
		local spawned = SpawnPlayerOnTeamSpawn(player, selectedTeam)
		if spawned then
			GivePlayerTeamTools(player, selectedTeam)
		end
	end)
	
	for _, player in Players:GetPlayers() do
		local team = player.Team
		if team and Config.teamOnSpawnTools[team] then
			GivePlayerTeamTools(player, team)
		end
	end
end

return TeamSelectionSystem
