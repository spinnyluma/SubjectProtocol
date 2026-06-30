local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")


local TerminalSignals = require(ServerStorage.Modules.ECS.Systems.TerminalControlSystem.Signals)

local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)
local ReplicaConfig = require(ReplicatedStorage.Modules.Shared.Constants.ReplicaConfig)
local ModeConfig = require(ReplicatedStorage.Modules.Shared.Constants.ModeConfig)

local Replica = require(ServerStorage.Modules.Utilities.ReplicaServer)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)


local teamPlayerAddedConnection: RBXScriptConnection? = nil

local subjectsTeam = Teams:FindFirstChild("Subjects")

local modeReplica = Replica.New({
	Token = Replica.Token(ReplicaConfig.replicaTokens.Mode.Name),
	Data = {
		VoteStarted = false,
		Modes = {}
	}
})

local currentVoteCountdown = 

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
	
	print(modeReplica)
	for _, player in subjectsPlayers do
		modeReplica:Subscribe(player)
	end
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

local function ResetModeReplica()
	modeReplica:Set({"VoteStarted"}, false)
	modeReplica:Set({"Modes"}, {})
end

function FacilityModeSystem.Initialize()
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

		modeReplica:Set({"VoteStarted"}, true)
		ReplicateReplicaToSubjects()
	end)
	TerminalSignals.TerminalOwnerChanged:Connect(function(newTerminalOwner: Team, _)
		if(newTerminalOwner == TeamConfig.teams.Subjects.Team) then
			
		else
			ResetModeReplica()
			modeReplica:DontReplicate()
		end		
	end)
end

return FacilityModeSystem
