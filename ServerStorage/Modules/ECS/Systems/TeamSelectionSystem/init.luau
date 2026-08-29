local ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")
const Teams = game:GetService("Teams")

local selectTeamRE = ReplicatedStorage.Assets.Shared.Remotes.Events.SelectTeam
const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Helpers = Modules.Helpers
const Shared = Modules.Shared

const Table = Helpers.Table
const Cuff = Helpers.Cuff

const Constants = Shared.Constants

const Hint = Constants.Hint

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
const TableHelper = require(Table.TableHelper)
const CuffHelper = require(ServerStorage.Modules.Helpers.Cuff.CuffHelper)
const HintConfig = require(Hint.HintConfig)
local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)
const Promise = require(Utilities.Promise)
const t = require(Utilities.t)

const CellImprisonmentHelper = require("../../Helpers/CellImprisonment/CellImprisonmentHelper")

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
const ToolService = require(ServerStorage.Modules.Services.Tool.ToolService)
const Config = require(script.Config)

const guardSpawns = workspace.GuardSpawns
const subjectSpawns = workspace.SubjectSpawns

const subjectsTeam = Teams.Subjects
const guardsTeam = Teams.Guards


const sendHintRE = ReplicatedStorage.Assets.Shared.Remotes.Events.SendHint
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
	
	return true
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
	elseif(selectedTeam == TeamConfig.teams.Subjects.Team) then
		const subjectSpawnsTable = subjectSpawns:GetChildren()
		const randomSpawn = TableHelper.GetRandomValueFromTable(subjectSpawnsTable)
		if(not randomSpawn) then return false end
		
		character:PivotTo(randomSpawn.CFrame)
	else
		local choosingSpawnLocationCframe = workspace.SpawnLocation.CFrame
		choosingSpawnLocationCframe *= CFrame.new(0, 10, 0)
		character:PivotTo(choosingSpawnLocationCframe)
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
	guardsTeam.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			Promise.try(function()
				local spawned = SpawnPlayerOnTeamSpawn(player, guardsTeam)
				if spawned then
					GivePlayerTeamTools(player, guardsTeam)
				end
			end)
				:catch(function(err)
					AssertHelper.Warn(tostring(err))
				end)
			
		end)
	end)
	
	subjectsTeam.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			Promise.try(function()
				local spawned = SpawnPlayerOnTeamSpawn(player, subjectsTeam)
				if spawned then
					GivePlayerTeamTools(player, guardsTeam)
				end
			end)
				:catch(function(err)
					AssertHelper.Warn(tostring(err))
				end)
		end)
	end)

	selectTeamRE.OnServerEvent:Connect(function(player: Player, selectedTeam: Team)
		if(selectedTeam == Teams.Choosing) then
			const playerCuffed = CuffHelper.IsPlayerCuffed(player)
			const playerJailed = CellImprisonmentHelper.IsPlayerImprisoned(player)
			
			if(playerCuffed or playerJailed) then
				sendHintRE:FireClient(player, "You cannot change team while cuffed or jailed.", HintConfig.hintColors.Rejection.Name)
				return
			end
		end
		
		const setPlayerTeam = SetPlayerTeam(player, selectedTeam)	
		if(not setPlayerTeam) then return end
		
		--Promise.try(function()
		--	local spawned = SpawnPlayerOnTeamSpawn(player, selectedTeam)
		--	if spawned then
		--		GivePlayerTeamTools(player, guardsTeam)
		--	end
		--end)
		--	:catch(function(err)
		--		AssertHelper.Warn(tostring(err))
		--	end)
	end)
	
	for _, player in Players:GetPlayers() do
		local team = player.Team
		if team and Config.teamOnSpawnTools[team] then
			GivePlayerTeamTools(player, team)
		end
	end
end

return TeamSelectionSystem
