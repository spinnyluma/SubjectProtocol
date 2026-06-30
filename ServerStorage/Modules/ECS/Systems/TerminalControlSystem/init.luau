local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local NamedSignal = require(ReplicatedStorage.Modules.Utilities.NamedSignal)


local ProximitySignals = require(ServerStorage.Modules.ECS.Systems.ProximityInteractionSystem.Signals)
local ProximityConfig = require(ServerStorage.Modules.ECS.Systems.ProximityInteractionSystem.Config)

local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local TerminalConfig = require(ReplicatedStorage.Modules.Shared.Constants.TerminalConfig)
local ReplicaConfig = require(ReplicatedStorage.Modules.Shared.Constants.ReplicaConfig)

local SystemManagerModule = require(ReplicatedStorage.Modules.ECS.SystemManagerModule)
local TerminalSignals = require(script.Signals)

local Replica = require(ServerStorage.Modules.Utilities.ReplicaServer)


local TerminalControlSystem = {}

local currentTerminalContestState = TerminalConfig.terminalContestStates.Uncontested.Name
local terminalOwner: Team = TeamConfig.teams.Guards.Team


local currentModeCooldownTime = 0
local voteOccurredForCurrentSubjectCapture = false

local currentTerminalContestTime = 0
local contestingConnection: RBXScriptConnection? = nil


local cooldownDecrementConnection: RBXScriptConnection? = nil

local terminalReplica = Replica.New({
	Token = Replica.Token(ReplicaConfig.replicaTokens.Terminal.Name),
	Data = {
		TerminalTime = currentTerminalContestTime,
		TerminalOwner = TeamConfig.teams.Guards.Team,
		TerminalContestState = TerminalConfig.terminalContestStates.Uncontested.Name,
		TeamsOnTerminalState = TerminalConfig.teamsOnTerminalStates.NoTeamsOnTerminal.Name
	}
})

local function GetTeamsOnTerminalStateFromPlayers(playerCharacters: {Model?}): TerminalConfig.TeamsOnTerminalState?
	local playerCharactersIsValid = AssertHelper.InvalidArgAssert(
		type(playerCharacters) == "table",
		playerCharacters,
		"playerCharacters",
		"GetTerminalControlTypeFromPlayers",
		"playerCharacters"
	)
	if(not playerCharactersIsValid) then return end
	
	local subjectsContesting, guardsContesting = 0, 0
	for _, character in playerCharacters do
		local player = Players:GetPlayerFromCharacter(character)
		local playerIsValid = AssertHelper.ExpectedValAssert(
			typeof(player) == "Instance"
			and player:IsA("Player"),
			player,
			"player",
			"GetTerminalControlTypeFromPlayers",
			"player"
		)
		if(not playerIsValid) then continue end
		
		local playerTeam = player.Team
		if(tostring(player.Team) == TeamConfig.teams.Guards.Name) then
			guardsContesting += 1
		else
			subjectsContesting += 1
		end
	end
	
	if(guardsContesting > 0 and subjectsContesting > 0) then
		return TerminalConfig.teamsOnTerminalStates.NumberOfTeamsOnTerminal.Name
	elseif(guardsContesting > 0) then
		return TerminalConfig.teamsOnTerminalStates.Guards.Name
	elseif(subjectsContesting > 0) then
		return TerminalConfig.teamsOnTerminalStates.Subjects.Name
	else
		return TerminalConfig.teamsOnTerminalStates.NoTeamsOnTerminal.Name
	end
end

--[[
	Sets the new terminal contest time.
	
	@param number newContestTime The new contest time.
	@returns boolean Returns true if the new contest time set was more or equal than the limit of Terminal.TIME_TO_CAPTURE
	and false if the new time set was less than 0.
]]
local function SetTerminalContestTime(newContestTime: number): boolean?
	currentTerminalContestTime = newContestTime
	terminalReplica:Set({"TerminalTime"}, currentTerminalContestTime)
	if(currentTerminalContestTime >= TerminalConfig.TIME_TO_CAPTURE) then
		return TerminalConfig.terminalContestTimeStates.TerminalTimeMaxReached.Name
	end 
	
	if(currentTerminalContestTime <= 0) then
		return TerminalConfig.terminalContestTimeStates.TerminalTimeMinReached.Name
	end
	return nil
end


local function SetTerminalContestState(newContestState: TerminalConfig.TerminalContestState)
	local newContestStateIsValid = AssertHelper.InvalidArgAssert(
		TerminalConfig.terminalContestStates[newContestState] ~= nil,
		newContestState,
		"newContestState",
		"SetTerminalContestState",
		"TerminalContestState"
	)
	if(not newContestStateIsValid) then return end
	
	currentTerminalContestState = newContestState

	terminalReplica:Set({"TerminalContestState"}, currentTerminalContestState)
		
end

local function SetTeamsOnTerminalState(newTeamsOnTerminalState: TerminalConfig.TeamsOnTerminalState)
	local newTeamsOnTerminalStateIsValid = AssertHelper.InvalidArgAssert(
		TerminalConfig.teamsOnTerminalStates[newTeamsOnTerminalState] ~= nil,
		newTeamsOnTerminalState,
		"newTeamOnTerminalState",
		"SetTeamsOnTerminalState",
		"TeamsOnTerminalState"
	)
	if(not newTeamsOnTerminalStateIsValid) then return end
	terminalReplica:Set({"TeamsOnTerminalState"}, newTeamsOnTerminalState)
end

local function SetTerminalOwner(newTerminalOwner: Team)
	local newTerminalOwnerIsValid = AssertHelper.InvalidArgAssert(
		typeof(newTerminalOwner) == "Instance"
		and newTerminalOwner:IsA("Team"),
		newTerminalOwner,
		"terminalOwner",
		"SetTerminalOwner",
		"Team"
	)
	if(not newTerminalOwnerIsValid) then return end
	
	local oldTerminalOwner = terminalOwner
	terminalOwner = newTerminalOwner
	
	if(oldTerminalOwner ~= terminalOwner) then
		voteOccurredForCurrentSubjectCapture = false
		TerminalSignals.TerminalOwnerChanged:Fire(terminalOwner, oldTerminalOwner)
	end
	terminalReplica:Set({"TerminalOwner"}, newTerminalOwner)
	
	if(voteOccurredForCurrentSubjectCapture) then return end
	if(terminalOwner == TeamConfig.teams.Subjects.Team) then
		if(currentModeCooldownTime == 0) then
			TerminalSignals.ModeVoteAvailable:Fire()
			voteOccurredForCurrentSubjectCapture = true
			currentModeCooldownTime = TerminalConfig.TIME_TO_CAPTURE
			
			cooldownDecrementConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
				currentModeCooldownTime -= deltaTime
				if(currentModeCooldownTime <= 0) then
					cooldownDecrementConnection:Disconnect()
					if(not voteOccurredForCurrentSubjectCapture) then
						currentModeCooldownTime = 0
						TerminalConfig.ModeVoteAvailable:Fire()
					end
				end
			end)
		end
	else
		
	end
end


local function ResetTerminalState()
	SetTerminalContestTime(0)
	SetTerminalContestState(TerminalConfig.terminalContestStates.Uncontested.Name)
end



local function AddTerminalContestStateThread(newContestingTeam: Team)
	local newContestingTeamIsValid = AssertHelper.InvalidArgAssert(
		typeof(newContestingTeam) == "Instance"
		and newContestingTeam:IsA("Team"),
		newContestingTeam,
		"newContestingTeam",
		"AddTerminalContestStateThread",
		"Team"
	)
	if(not newContestingTeamIsValid) then return end
	
	if(currentTerminalContestState == TerminalConfig.terminalContestStates.Uncontested.Name
		and terminalOwner ~= newContestingTeam) then
		local contestState: {[string]: any}? = TerminalConfig.teamsToContestStateMap[newContestingTeam]
		local contestStateIsValid = AssertHelper.ExpectedValAssert(
			TerminalConfig.terminalContestStates[contestState] ~= nil,
			contestState,
			"contestState",
			"table"
		)
		if(not contestStateIsValid) then return end
		
		
		SetTerminalContestState(contestState)
		
		contestingConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
			local contestTimeState: boolean? = SetTerminalContestTime(
				currentTerminalContestTime + deltaTime
			)
			
			if(contestTimeState ~= TerminalConfig.terminalContestTimeStates.TerminalTimeMaxReached.Name) then
				return
			end
			SetTerminalOwner(newContestingTeam)

			ResetTerminalState()
			contestingConnection:Disconnect()				
		end)
	else
		
		local currentContestingTeam: {[string]: any}? = TerminalConfig.contestStateToTeamsMap[currentTerminalContestState]
		
		local currentContestingTeamIsValid = AssertHelper.ExpectedValAssert(
			typeof(currentContestingTeam) == "Instance"
			and currentContestingTeam:IsA("Team"),
			currentContestingTeam,
			"currentContestingTeam",
			"Team"
		)
		if(not currentContestingTeamIsValid) then return end
		
		local currentContestingTeamIsValid = AssertHelper.ExpectedValAssert(
			typeof(currentContestingTeam) == "Instance"
			and currentContestingTeam:IsA("Team"),
			currentContestingTeam,
			"currentContestingTeam",
			"Team"
		)
		if(not currentContestingTeamIsValid) then return end
		
		
		if(currentContestingTeam == newContestingTeam) then
			contestingConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
				local contestTimeState: boolean? = SetTerminalContestTime(
					currentTerminalContestTime + deltaTime
				)
				if(contestTimeState ~= TerminalConfig.terminalContestTimeStates.TerminalTimeMaxReached.Name) then
					return
				end
				SetTerminalOwner(newContestingTeam)
	
				ResetTerminalState()
				if(contestingConnection ~= nil
					and contestingConnection.Connected) then 
					contestingConnection:Disconnect()
				end
			end)
		else
			local newContestingTeamContestState: {[string]: any}? = TerminalConfig.teamsToContestStateMap[newContestingTeam]
			local newContestingTeamContestStateIsValid = AssertHelper.ExpectedValAssert(
				TerminalConfig.terminalContestStates[newContestingTeamContestState] ~= nil,
				newContestingTeamContestState,
				"newContestingTeamContestState",
				"table"
			)
			if(not newContestingTeamContestStateIsValid) then return end
			
			contestingConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
				local contestTimeState: boolean? = SetTerminalContestTime(
					currentTerminalContestTime - deltaTime
				)
				if(contestTimeState ~= TerminalConfig.terminalContestTimeStates.TerminalTimeMinReached.Name) then
					return
				end
				if(contestingConnection ~= nil
					and contestingConnection.Connected) then
					contestingConnection:Disconnect()
				end
				SetTerminalContestTime(0)
				
				if(terminalOwner == newContestingTeam) then
					SetTerminalContestState(TerminalConfig.terminalContestStates.Uncontested.Name)
					SetTeamsOnTerminalState(TerminalConfig.teamsOnTerminalStates.NoTeamsOnTerminal.Name)
					return
				else
					--[[
						Increase the contest time only when there is another team (3rd team) that has captured the terminal
						because after the current terminal contest time reaches 0 after decrementing, the 3rd team may not be the terminal owner
					]]
					SetTerminalContestState(newContestingTeamContestState)
					contestingConnection = RunService.Heartbeat:Connect(function(increaseDeltaTime: number)
						local contestTimeState: boolean? = SetTerminalContestTime(
							currentTerminalContestTime + increaseDeltaTime
						)
						if(contestTimeState ~= TerminalConfig.terminalContestTimeStates.TerminalTimeMaxReached.Name) then
							return
						end
						SetTerminalOwner(newContestingTeam)

						ResetTerminalState()
						if(contestingConnection ~= nil
							and contestingConnection.Connected) then
							contestingConnection:Disconnect()
						end
					end)
				end
			end)
		end
	end
end


local function HandleTerminalControlSystem(proximityInteractionType: string,
	querySource: Instance,
	instancesFound: {Instance?}
)
	local proximityInteractionTypeIsValid = AssertHelper.InvalidArgAssert(
		type(proximityInteractionType) == "string",
		proximityInteractionType,
		"proximityInteractionType",
		"HandleTerminalControlSystem",
		"proximityInteractionType"
	)
	if(not proximityInteractionTypeIsValid) then
		return
	end
	
	local querySourceIsValid = AssertHelper.InvalidArgAssert(
		typeof(querySource) == "Instance",
		querySource,
		"querySource",
		"HandleTerminalControlSystem",
		"querySource"
	)
	if(not querySourceIsValid) then return end
	local instancesFoundIsValid = AssertHelper.InvalidArgAssert(
		type(instancesFound) == "table",
		instancesFound,
		"instancesFound",
		"HandleTerminalControlSystem",
		"instancesFound"
	)
	if(not instancesFoundIsValid) then return end
	local teamsOnTerminalState = GetTeamsOnTerminalStateFromPlayers(instancesFound)
	if(not teamsOnTerminalState) then return end
	
	local terminalOwnerIsValid = AssertHelper.ExpectedValAssert(
		typeof(terminalOwner) == "Instance"
		and terminalOwner:IsA("Team"),
		terminalOwner,
		"terminalOwner",
		"Team"
	)
	if(not terminalOwnerIsValid) then return end
	
	
	local team: Team? = TerminalConfig.teamsOnTerminalStateToTeamsMap[teamsOnTerminalState]
	if(team
		and terminalOwner == team
		and currentTerminalContestState == TerminalConfig.terminalContestStates.Uncontested.Name) then
		SetTeamsOnTerminalState(TerminalConfig.teamsOnTerminalStates.NoTeamsOnTerminal.Name)
	else
		SetTeamsOnTerminalState(teamsOnTerminalState)

	end
	
	if(teamsOnTerminalState == TerminalConfig.teamsOnTerminalStates.NumberOfTeamsOnTerminal.Name
		or teamsOnTerminalState == TerminalConfig.teamsOnTerminalStates.NoTeamsOnTerminal.Name) then
		if(typeof(contestingConnection) ~= "RBXScriptConnection") then return end
		contestingConnection:Disconnect()
		return
	end
	local teamFromControlType: Team? = TerminalConfig.teamsOnTerminalStateToTeamsMap[teamsOnTerminalState]
	if(not teamFromControlType) then return end
	if(teamFromControlType == terminalOwner
		and teamsOnTerminalState == TerminalConfig.teamsOnTerminalStates.NoTeamsOnTerminal.Name) then
		return
	end
	if(teamFromControlType == terminalOwner
		and currentTerminalContestState == TerminalConfig.terminalContestStates.Uncontested.Name) then 
		return 
	end
	--[[
		If there is a contesting team
		then we might not want to add a new contest state thread
		because it may already have been initialized.
	]]
	if(contestingConnection ~= nil
		and contestingConnection.Connected) then 
		return 
	end
	
	AddTerminalContestStateThread(teamFromControlType)
end

function TerminalControlSystem.Initialize()
	
	ProximitySignals.ProximityObjectsFound:Connect(function(proximityInteractionType: string,
		querySource: Instance,
		instancesFound: {Instance?}
	)
		if(proximityInteractionType == ProximityConfig.proximityInteractionTypes.T_Terminal.Name) then
			HandleTerminalControlSystem(proximityInteractionType, querySource, instancesFound)
		end
	end)
	
	terminalReplica:Replicate()
end

return TerminalControlSystem
