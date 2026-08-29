local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local ClientReplicaConfig = require(ReplicatedStorage.Modules.Shared.Constants.ClientReplicaConfig)
local SystemManagerModule = require(ReplicatedStorage.Modules.ECS.SystemManagerModule)
local DictionaryHelper = require(ReplicatedStorage.Modules.Helpers.Table.DictionaryHelper)
local TerminalSignals = require(ServerStorage.Modules.ECS.Systems.TerminalControlSystem.Signals)
local ReplicaConfig = require(ServerStorage.Modules.Constants.ReplicaConfig)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local TableHelper = require(ReplicatedStorage.Modules.Helpers.Table.TableHelper)
local ModeConfig = require(ReplicatedStorage.Modules.Shared.Constants.ModeConfig)
local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)
local TimeHelper = require(ReplicatedStorage.Modules.Helpers.Time.TimeHelper)
local Promise = require(ReplicatedStorage.Modules.Utilities.Promise)
local Replica = require(ServerStorage.Modules.Utilities.ReplicaServer)
local Trove = require(ReplicatedStorage.Modules.Utilities.Trove)

local FacilityModeSignals = require(script.Signals)
local FacilityModeConfig = require(script.Config)

const FacilityModeSystemConfig = require("@self/Config")

local teamPlayerAddedConnection: RBXScriptConnection? = nil
local facilityModeSelectionTrove: Trove.Trove = Trove.new()

local currentMode: ModeConfig.Mode? = ModeConfig.modes.Idle.Name


local voteOccurredForCurrentSubjectCapture = false

local submitModeVoteRE: RemoteEvent = ReplicatedStorage.Assets.Shared.Remotes.Events.SubmitModeVote
const sendHintRE: RemoteEvent = ReplicatedStorage.Assets.Shared.Remotes.Events.SendHint


local subjectsTeam = Teams:FindFirstChild("Subjects")

local modesReplica = Replica.New({
	Token = Replica.Token(ClientReplicaConfig.replicaTokenNames.Mode.Name),
	Data = {
		VoteOngoing = false,
		Modes = {}
	}
})

local currentModeReplica = Replica.New({
	Token = ReplicaConfig.tokens.CurrentMode.Token,
	Data = {
		CurrentMode = currentMode,
		ModeRemainingTime = -1,
		ModeVoteCooldown = -1
	}
})

local voteOngoing = false
local currentRandomModes: {ModeConfig.Mode?} = {}
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
		if(key == ModeConfig.modes.Idle.Name) then continue end
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
		table.remove(keys, rndmIndex)
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
		modesReplica:Subscribe(player)
	end
	
	
	Replica.NewReadyPlayer:Connect(function(player: Player)
		if(player.Team == subjectsTeam) then
			modesReplica:Subscribe(player)
		end
	end)
	subjectsTeam.PlayerAdded:Connect(function(player: Player)
		if(Replica.ReadyPlayers[player]) then
			modesReplica:Subscribe(player)
		end
	end)
	
	subjectsTeam.PlayerRemoved:Connect(function(player: Player)
		if(Replica.ReadyPlayers[player]) then
			modesReplica:Unsubscribe(player)
		end
	end)
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
	table.clear(currentRandomModes)
	modesReplica:SetValues({}, {
		VoteOngoing = false,
		Modes = {},
		VoteEndTime = 0,
	})
end

local function GetSelectedMode(compiledVotes: {[ModeConfig.Mode]: number?}): ModeConfig.Mode?
	local compiledVotesIsValid = AssertHelper.InvalidArgAssert(
		type(compiledVotes) == "table",
		compiledVotes,
		"compiledVotes",
		"SelectMode",
		"table"
	)
	if(not compiledVotesIsValid) then return nil end
	
	local lenOfDict: number? = DictionaryHelper.GetLengthOfDictionary(compiledVotes)
	if(not lenOfDict) then
		return nil
	end
	
	
	local modeWithMaxVotes: ModeConfig.Mode? = nil
	local maxVotes: number? = nil
	for mode, count in compiledVotes do
		if(not modeWithMaxVotes
			or count > maxVotes) then
			modeWithMaxVotes = mode
			maxVotes = count
		end
	end
	
	return modeWithMaxVotes
end

local function SetSelectedMode(mode: ModeConfig.Mode)
	local modeIsValid = AssertHelper.InvalidArgAssert(
		ModeConfig.modes[mode] ~= nil,
		mode,
		"mode",
		"SetSelectedMode",
		"ModeConfig.Mode"
	)
	if(not modeIsValid) then return end
	local oldMode: ModeConfig.Mode? = currentMode
	
	currentMode = mode
	if(oldMode ~= currentMode) then
		
		FacilityModeSignals.ModeChanged:Fire(currentMode, oldMode)
	end
	
	const modeHintEnum = FacilityModeSystemConfig.modeChangedHints[mode]
	if(modeHintEnum) then
		
		sendHintRE:FireAllClients(modeHintEnum.Hint, modeHintEnum.HintColor)

	end
	SystemManagerModule.SetGlobalGameState("CurrentMode", currentMode)
	currentModeReplica:Set({"CurrentMode"}, currentMode)
end

local function InitializeModeVoteProcess()
	Promise.try(function()
		local countdownEndedSuccess = TimeHelper.CreateCountdownInSeconds(ModeConfig.MODE_VOTE_TIME)
		if(not countdownEndedSuccess) then
			return Promise.reject("Mode vote countdown could not be started properly")
		end
		
	end)
		:andThen(function()
			local compiledVotes: {[ModeConfig.Mode]: number?} = CompileModeVotes()
			local lenOfDict: number? = DictionaryHelper.GetLengthOfDictionary(compiledVotes)
			if(not lenOfDict) then
				return Promise.reject(`Unable to obtain the number of compiled votes, expected number, got {lenOfDict}`)
			end
			if(lenOfDict == 0) then
				local randomMode: ModeConfig.Mode? = TableHelper.GetRandomValueFromTable(currentRandomModes)
				if(not randomMode) then
					return Promise.reject(`Unable to obtain random mode from selection of modes, expected ModeConfig.Mode, got {randomMode}`)
				end
				SetSelectedMode(randomMode)
				return Promise.resolve()
			else
				local selectedMode: ModeConfig.Mode? = GetSelectedMode(compiledVotes)
				if(not selectedMode) then
					return Promise.reject(`Unable to select a mode from compiled votes, expected ModeConfig.Mode, got {selectedMode}`)
				end
				SetSelectedMode(selectedMode)

				return Promise.resolve()

			end
		end)
		:andThen(function()
			local modeDurationEndedSuccess = TimeHelper.CreateCountdownInSecondsPrecise(ModeConfig.MODE_DURATION, function(secondsRemaining)
				currentModeReplica:Set({"ModeRemainingTime"}, secondsRemaining)
			end)
			if(not modeDurationEndedSuccess) then
				return Promise.reject("Mode duration countdown could not be started properly")
			end
			
			SetSelectedMode(ModeConfig.modes.Idle.Name)
			voteOccurredForCurrentSubjectCapture = false

		end)
		:andThen(function()
			local currentModeVoteCooldown = SystemManagerModule.GetGlobalGameState("ModeVoteCooldown")
			local modeVoteCooldownEndTime = os.time() + currentModeVoteCooldown
			local numberOfSecondsCooldown = modeVoteCooldownEndTime - os.time()
			TimeHelper.CreateCountdownInSecondsPrecise(numberOfSecondsCooldown, function(secondsRemaining)
				SystemManagerModule.SetGlobalGameState("ModeVoteCooldown", secondsRemaining)
				currentModeReplica:Set({"ModeVoteCooldown"}, secondsRemaining)

			end)
			
			SystemManagerModule.SetGlobalGameState("ModeVoteCooldown", 0)
			currentModeReplica:Set({"ModeVoteCooldown"}, 0)
		end)
		:catch(function(error)
			AssertHelper.Warn(tostring(error))
		end)
		:finally(function()
			ResetModeVote()
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

local function SetupOnModeVoteVariables()
	voteOccurredForCurrentSubjectCapture = true
	SystemManagerModule.SetGlobalGameState("ModeVoteCooldown", FacilityModeConfig.MODE_COOLDOWN)
	local modes = GetRandomModes(ModeConfig.NUMBER_OF_MODES)
	local modesIsValid = AssertHelper.ExpectedValAssert(
		type(modes) == "table",
		modes,
		"modes",
		"table"
	)
	if(not modesIsValid) then return end

	currentRandomModes = modes
	local voteEndTime = workspace:GetServerTimeNow() + ModeConfig.MODE_VOTE_TIME
	modesReplica:SetValues({}, {
		VoteOngoing = true,
		Modes = modes,
		VoteEndTime = voteEndTime
	})
	voteOngoing = true
end

function FacilityModeSystem.Initialize()
	SystemManagerModule.SetGlobalGameState("CurrentMode", currentMode)
	SystemManagerModule.SetGlobalGameState("ModeVoteCooldown", 0)
	ReplicateReplicaToSubjects()
	currentModeReplica:Replicate()
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
	
	TerminalSignals.TerminalOwnerCaptureTimeMaxReached:Connect(function()
		if(voteOccurredForCurrentSubjectCapture) then return end

		local facilityModeCooldown = SystemManagerModule.GetGlobalGameState("ModeVoteCooldown")
		local facilityModeCooldownIsValid = AssertHelper.ExpectedValAssert(
			type(facilityModeCooldown) == "number",
			facilityModeCooldown,
			"facilityModeCooldown",
			"number"
		)
		if(not facilityModeCooldownIsValid) then return end
		voteOccurredForCurrentSubjectCapture = true

		
		if(facilityModeCooldown == 0) then
			SetupOnModeVoteVariables()
			ReplicateReplicaToSubjects()
			InitializeModeVoteProcess()	
		else
			local voteCooldownEndedSuccess = TimeHelper.CreateCountdownInSeconds(FacilityModeConfig.MODE_COOLDOWN)
			

			SetupOnModeVoteVariables()
			ReplicateReplicaToSubjects()
			InitializeModeVoteProcess()
		end
	
	end)
end

return FacilityModeSystem
