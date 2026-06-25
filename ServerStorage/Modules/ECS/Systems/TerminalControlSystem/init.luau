local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProximitySignals = require(ServerStorage.Modules.ECS.Systems.ProximityInteractionSystem.Signals)
local ProximityConfig = require(ServerStorage.Modules.ECS.Systems.ProximityInteractionSystem.Config)

local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local TerminalConfig = require(ReplicatedStorage.Modules.Shared.Constants.TerminalConfig)

local TerminalControlSystem = {}

local currentTerminalContestState = TerminalConfig.terminalContestStates.Uncontested.Name
local terminalOwner: Team = TeamConfig.teams.Guards.Team


local currentTerminalContestTime = 0
local contestingConnection: RBXScriptConnection? = nil


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
	if(currentTerminalContestTime >= TerminalConfig.TIME_TO_CAPTURE) then
		return TerminalConfig.terminalContestTimeStates.TerminalTimeMaxReached.Name
	end 
	
	if(currentTerminalContestTime <= 0) then
		return TerminalConfig.terminalContestTimeStates.TerminalTimeMinReached.Name
	end
	print(currentTerminalContestTime)
	return nil
end

local function ResetTerminalState()
	currentTerminalContestTime = 0
	currentTerminalContestState = TerminalConfig.terminalContestStates.Uncontested.Name
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
		
		
		
		currentTerminalContestState = contestState
		
		contestingConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
			local contestTimeState: boolean? = SetTerminalContestTime(
				currentTerminalContestTime + deltaTime
			)
			
			if(contestTimeState ~= TerminalConfig.terminalContestTimeStates.TerminalTimeMaxReached.Name) then
				return
			end
			terminalOwner = newContestingTeam

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
				terminalOwner = newContestingTeam
	
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
				print("min raeched!!")
				currentTerminalContestTime = 0
				
				if(terminalOwner == newContestingTeam) then 
					print("uncontested now!!!")
					currentTerminalContestState = TerminalConfig.terminalContestStates.Uncontested.Name
					return
				else
					--[[
						Increase the contest time only when there is another team (3rd team) that has captured the terminal
						because after the current terminal contest time reaches 0 after decrementing, the 3rd team may not be the terminal owner
					]]
					currentTerminalContestState = newContestingTeamContestState
					contestingConnection = RunService.Heartbeat:Connect(function(increaseDeltaTime: number)
						local contestTimeState: boolean? = SetTerminalContestTime(
							currentTerminalContestTime + increaseDeltaTime
						)
						if(contestTimeState ~= TerminalConfig.terminalContestTimeStates.TerminalTimeMaxReached.Name) then
							return
						end
						terminalOwner = newContestingTeam

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
	--local currentContestingTeam: {[string]: any}? = TerminalConfig.contestStateToTeamsMap[currentTerminalContestState]
	--local currentContestingTeamIsValid = AssertHelper.ExpectedValAssert(
	--	type(currentContestingTeam) == "table",
	--	currentContestingTeam,
	--	"currentContestingTeam",
	--	"table"
	--)
	--if(not currentContestingTeamIsValid) then return end
	
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
	local terminalContestState = GetTeamsOnTerminalStateFromPlayers(instancesFound)
	if(not terminalContestState) then return end
	if(terminalContestState == TerminalConfig.teamsOnTerminalStates.NumberOfTeamsOnTerminal.Name
		or terminalContestState == TerminalConfig.teamsOnTerminalStates.NoTeamsOnTerminal.Name) then
		if(typeof(contestingConnection) ~= "RBXScriptConnection") then return end
		contestingConnection:Disconnect()
		return
	end
	local teamFromControlType: Team? = TerminalConfig.teamsOnTerminalStateToTeamsMap[terminalContestState]
	if(not teamFromControlType) then return end
	if(teamFromControlType == terminalOwner
		and terminalContestState == TerminalConfig.teamsOnTerminalStates.NoTeamsOnTerminal.Name) then
		return
	end
	if(teamFromControlType == terminalOwner
		and currentTerminalContestState == TerminalConfig.terminalContestStates.Uncontested.Name) then return end
	--[[
		If there is a contesting team
		then we might not want to add a new contest state thread
		because it may already have been initialized.
	]]
	if(contestingConnection ~= nil
		and contestingConnection.Connected) then return end
	
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
end

return TerminalControlSystem
