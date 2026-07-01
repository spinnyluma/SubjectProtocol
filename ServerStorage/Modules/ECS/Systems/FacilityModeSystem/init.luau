local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")


local TerminalSignals = require(ServerStorage.Modules.ECS.Systems.TerminalControlSystem.Signals)

local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)
local ReplicaConfig = require(ReplicatedStorage.Modules.Shared.Constants.ReplicaConfig)
local ModeConfig = require(ReplicatedStorage.Modules.Shared.Constants.ModeConfig)
local FacilityModeConfig = require(script.Config)


local Trove = require(ReplicatedStorage.Modules.Utilities.Trove)
local Replica = require(ServerStorage.Modules.Utilities.ReplicaServer)
local Promise = require(ReplicatedStorage.Modules.Utilities.Promise)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local TimeHelper = require(ReplicatedStorage.Modules.Helpers.Time.TimeHelper)

local teamPlayerAddedConnection: RBXScriptConnection? = nil
local facilityModeSelectionTrove: Trove.Trove = Trove.new()


local submitModeVoteRE: RemoteEvent = ReplicatedStorage.Assets.Shared.Remotes.Events.SubmitModeVote

local subjectsTeam = Teams:FindFirstChild("Subjects")

local modeReplica = Replica.New({
	Token = Replica.Token(ReplicaConfig.replicaTokens.Mode.Name),
	Data = {
		VoteOngoing = false,
		Modes = {}
	}
})

local voteOngoing = false

local currentVotes: {[Player]: ModeConfig.Mode?} = {}

local FacilityModeSystem = {}

local function GetRandomModes(numberOfModes: number): {ModeConfig.Mode?}?
	local numberOfModesIsValid = AssertHelper.InvalidArgAssert(
		typeof(numberOfModes) == "number",
		numberOfModes,
		"numberOfModes",
		"GetRandomModes",
		"number"
	)
	if(not numberOfModesIsValid) then return end
	
	
	local keys = {}

	for key, _ in ModeConfig.modes do
		table.insert(keys, key)
	end

	local modes = {}
	local random = Random.new()
	
	for i = #keys, 1, -1 do
		local rndmIndex = random:NextInteger(1, i)
		
		local chosenKey = keys[rndmIndex]
		local newMode: {[string]: number | string}? = ModeConfig.modes[chosenKey]
		local newModeIsValid = AssertHelper.ExpectedValAssert(
			type(newMode) == "table",
			newMode,
			"newMode",
			"table"
		)
		if(not newModeIsValid) then continue end
		local modeName = newMode["Name"]
		local modeNameIsValid = AssertHelper.ExpectedValAssert(
			type(modeName) == "string",
			modeName,
			"modeName",
			"string"
		)
		if(not modeNameIsValid) then continue end
		
		table.insert(modes, modeName)
	end
	return modes
end


local function ReplicateReplicaToSubjects()
	local subjectsTeamIsValid = AssertHelper.ExpectedValAssert(
		typeof(subjectsTeam) == "Instance"
		and subjectsTeam:IsA("Team"),
		subjectsTeam,
		"subjectsTeam",
		"Team"
	)
	if(not subjectsTeamIsValid) then return end
	
	local subjectsPlayers = subjectsTeam:GetPlayers()
	
	for _, player in subjectsPlayers do
		modeReplica:Subscribe(player)
	end
	
	
	Replica.NewReadyPlayer:Connect(function(player: Player)
		if(player.Team == subjectsTeam) then
			modeReplica:Subscribe(player)
		end
	end)
	subjectsTeam.PlayerAdded:Connect(function(player: Player)
		if(Replica.ReadyPlayers[player]) then
			modeReplica:Subscribe(player)
		end
	end)
	
	subjectsTeam.PlayerRemoved:Connect(function(player: Player)
		if(Replica.ReadyPlayers[player]) then
			modeReplica:Unsubscribe(player)
		end
	end)
end

--[[
	Sets the Modes' value in the modeReplica.
	@param modes {[string]: number | string} The modes to add to the replica.
	@returns boolean? Returns a boolean telling whether the operation was successful.
]]
local function AddModesToReplica(modes: {ModeConfig.Mode?}?): boolean?
	local modesIsValid = AssertHelper.InvalidArgAssert(
		type(modes) == "table",
		modes,
		"modes",
		"AddModesToReplica",
		"table"
	)
	if(not modesIsValid) then return end
	
	modeReplica:Set({"Modes"}, modes)
	return true
end



local function ProcessVote(votedMode: ModeConfig.Mode)
	local votedModeIsValid = AssertHelper.InvalidArgAssert(
		ModeConfig.modes[votedMode] ~= nil,
		votedMode,
		"votedMode",
		"ProcessVote",
		"ModeConfig.Mode"
	)
	if(not votedModeIsValid) then return end
end


--[[
	Checks whether a mode vote exists for a certain player.
	
	@param player Player The player to check for.
	@returns boolean? Whether the mode vote exists for the player. If the value returned is true, the vote may already exist for the player
	or an error occurred when calling the function.
]]
local function ModeVoteExistsForPlayer(player: Player): boolean
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
		and player:IsA("Player"),
		player,
		"player",
		"VoteExists",
		"Player"
	)
	if(not playerIsValid) then return true end
	
	return currentVotes[player] ~= nil
end

local function CompileModeVotes(): {[ModeConfig.Mode]: number?}
	local compiledModeVotes: {[ModeConfig.Mode]: number?} = {}
	for _, mode in currentVotes do
		if(not compiledModeVotes[mode]) then
			compiledModeVotes[mode] = 1
		else
			compiledModeVotes[mode] += 1
		end
	end
	return compiledModeVotes
end

local function ResetModeVote()
	voteOngoing = false
	table.clear(currentVotes)

	modeReplica:Set({"VoteOngoing"}, false)
	modeReplica:Set({"Modes"}, {})
end

local function InitializeModeVoteProcess()
	Promise.try(function()
		local voteEndTime = workspace:GetServerTimeNow() + FacilityModeConfig.MODE_VOTE_TIME
		modeReplica:Set({"VoteEndTime"}, voteEndTime)
		local countdownEndedSuccess = TimeHelper.CreateCountdownInSeconds(FacilityModeConfig.MODE_VOTE_TIME)
		if(not countdownEndedSuccess) then
			return Promise.reject()
		end
		
	end)
		:andThen(function()
			local compiledVotes: {[ModeConfig.Mode]: number?} = CompileModeVotes()
			print(compiledVotes)
			
			ResetModeVote()
		end)
		:catch(function(error)
			AssertHelper.Warn(tostring(error))
		end)
end

local function AddVoteToCurrentVotes(player: Player, votedMode: ModeConfig.Mode)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
		and player:IsA("Player"),
		player,
		"player",
		"AddVoteToCurrentVotes",
		"Player"
	)
	if(not playerIsValid) then return end
	
	local votedModeIsValid = AssertHelper.InvalidArgAssert(
		ModeConfig.modes[votedMode] ~= nil,
		votedMode,
		"votedMode",
		"AddVoteToCurrentVotes",
		"ModeConfig.Mode"
	)
	if(not votedModeIsValid) then return end
	
	currentVotes[player] = votedMode
end

function FacilityModeSystem.Initialize()
	ReplicateReplicaToSubjects()
	submitModeVoteRE.OnServerEvent:Connect(function(player: Player, votedMode: ModeConfig.Mode)
		if(not voteOngoing) then return end
		local modeVoteExistsForPlayer: boolean = ModeVoteExistsForPlayer(player)
		if(modeVoteExistsForPlayer) then
			return
		end
		
		local votedModeExists: boolean = ModeConfig.modes[votedMode] ~= nil
		if(not votedModeExists) then return end
		
		AddVoteToCurrentVotes(player, votedMode)
	end)
	TerminalSignals.ModeVoteAvailable:Connect(function()
		local modes = GetRandomModes(ModeConfig.NUMBER_OF_MODES)
		local modesIsValid = AssertHelper.ExpectedValAssert(
			type(modes) == "table",
			modes,
			"modes",
			"table"
		)
		if(not modesIsValid) then return end
		local success: boolean? = AddModesToReplica(modes)
		if(not success) then return end
		print("vote  ongoing changed")
		modeReplica:Set({"VoteOngoing"}, true)
		voteOngoing = true
		ReplicateReplicaToSubjects()
		InitializeModeVoteProcess()

	end)
	
end

return FacilityModeSystem
