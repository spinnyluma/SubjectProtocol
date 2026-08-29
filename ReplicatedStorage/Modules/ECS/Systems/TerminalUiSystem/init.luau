local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
const Teams = game:GetService("Teams")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local Replica = require(ReplicatedStorage.Modules.Utilities.ReplicaClient)
local Trove = require(ReplicatedStorage.Modules.Utilities.Trove)

const ClientSoundReplicationService = require("../../Services/SoundReplication/ClientSoundReplicationService")
const TerminalUiSystemConfig = require("@self/Config")
const ClientSoundService = require("../../Services/Sound/ClientSoundService")
const Promise = require("../../Utilities/Promise")

-- TROVE!!! means i need to store tween of capture time text and check if it is playing so i need to cancel it when setting capture time text visibility
local ClientReplicaConfig = require(ReplicatedStorage.Modules.Shared.Constants.ClientReplicaConfig)
local TerminalConfig = require(ReplicatedStorage.Modules.Shared.Constants.TerminalConfig)
local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)

local terminalOwner: ScreenGui? = nil
local terminalOwnerContainer: Frame? = nil
local terminalCaptureText: TextLabel? = nil
local terminalOwnerTimeText: TextLabel? = nil
local terminalOwnerText: TextLabel? = nil

local terminalFillbarContainer: CanvasGroup? = nil
local terminalFillbar: Frame? = nil

local terminalUiAppearTweenInfo = TweenInfo.new(
	0.25,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In
)

local terminalUiDisappearTweenInfo = TweenInfo.new(
	0.25,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In,
	0,
	false,
	2
)

local designFolder = ReplicatedStorage.Assets.Design

local terminalOwnerFillbarStyleSheet = designFolder.TerminalOwnerFillbar
local GuardsTeamTheme = designFolder.TeamThemes.GuardsTeam
local SubjectsTeamTheme = designFolder.TeamThemes.SubjectsTeam

local TerminalUiSystem = {}

local function InitializeUiElements()
	
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	terminalOwner = playerGui:WaitForChild("TerminalOwner")
	terminalOwnerContainer = terminalOwner:WaitForChild("TerminalOwnerContainer")
	terminalCaptureText = terminalOwnerContainer:WaitForChild("TerminalCaptureText")
	terminalOwnerText = terminalOwnerContainer:WaitForChild("TerminalOwnerText")
	terminalFillbarContainer = terminalOwnerContainer:WaitForChild("TerminalFillbarContainer")
	
	terminalOwnerTimeText = terminalFillbarContainer:WaitForChild("TerminalOwnerTimeText")
	
	terminalFillbar = terminalFillbarContainer:WaitForChild("TerminalFillbar")
			
end

local function SetTerminalOwnerCaptureTime(terminalTime: number)
	local terminalTimeIsValid = AssertHelper.InvalidArgAssert(
		type(terminalTime) == "number",
		terminalTime,
		"terminalTime",
		"SetTerminalOwnerCaptureTime",
		"number"
	)
	
	if(not terminalTimeIsValid) then
		return
	end
	
	if(not terminalCaptureText) then return end
	local terminalTimeRounded = math.round(terminalTime)
	local formattedTime: string = string.format("%i", terminalTimeRounded)
	
	terminalOwnerTimeText.Text = formattedTime .. `/{TerminalConfig.TIME_TO_OWN_TERMINAL}`
end

local function SetFillbarContainerScale(newValue: number)
	local newValueIsValid = AssertHelper.InvalidArgAssert(
		type(newValue) == "number",
		newValue,
		"newValue",
		"SetFillbarContainerScale",
		"number"
	)
	
	if(not newValueIsValid) then return end
	
	if(not terminalFillbar) then return end
	
	local xScale = newValue / TerminalConfig.TIME_TO_CAPTURE
	local newFillbarSize = UDim2.fromScale(xScale, 1)
	terminalFillbar.Size = newFillbarSize
end

local function SetTerminalCaptureText(teamsOnTerminalState: TerminalConfig.TeamsOnTerminalState)
	local teamsOnTerminalStateIsValid = AssertHelper.InvalidArgAssert(
		TerminalConfig.teamsOnTerminalStates[teamsOnTerminalState] ~= nil,
		teamsOnTerminalState,
		"teamsOnTerminalState",
		"SetTerminalCaptureText",
		"TerminalConfig.TeamsOnTerminalState"
	)
	
	if(not teamsOnTerminalStateIsValid) then return end
	local contestStateMessage: string? = TerminalConfig.teamsOnTerminalStateToCapturingMsgMap[teamsOnTerminalState]
	local contestStateMessageIsValid = AssertHelper.ExpectedValAssert(
		type(contestStateMessage) == "string",
		contestStateMessage,
		"contestStateMessage",
		"string"
	)
	
	if(not contestStateMessageIsValid) then
		return
	end
	
	if(not terminalCaptureText) then return end
	
	terminalCaptureText.Text = contestStateMessage
end

local function SetTerminalOwnerMessage(terminalOwner: Team)
	local terminalOwnerIsValid = AssertHelper.InvalidArgAssert(
		typeof(terminalOwner) == "Instance"
		and terminalOwner:IsA("Team"),
		terminalOwner,
		"terminalOwner",
		"SetTerminalOwnerMessage",
		"Team"
	)
	
	if(not terminalOwnerIsValid) then return end
	if(not terminalOwnerText) then return end
	
	local newTerminalOwnerText: string? = TerminalConfig.terminalOwnerToOwnerMsgMap[terminalOwner]
	local newTerminalOwnerIsValid = AssertHelper.ExpectedValAssert(
		typeof(newTerminalOwnerText) == "string",
		newTerminalOwnerText,
		"newTerminalOwnerText",
		"SetTerminalOwnerMessage",
		"string"
	)
	if(not newTerminalOwnerIsValid) then return end
	terminalOwnerText.Text = newTerminalOwnerText
end

local function SetTerminalCaptureTextVisibility(isVisible: boolean)
	local isVisibleIsValid = AssertHelper.InvalidArgAssert(
		type(isVisible) == "boolean",
		isVisible,
		"isVisible",
		"SetTerminalSecondaryInfoVisibility",
		"boolean"
	)
	
	if(not isVisibleIsValid) then return end
	
	if(not terminalCaptureText
		or (not terminalFillbarContainer)
		or (not terminalOwnerTimeText)) then
		return	
	end
	
	local transparency: number? = nil
	if(isVisible) then
		transparency = 0
	else
		transparency = 1
	end
	terminalCaptureText.TextTransparency = transparency
	--terminalFillbarContainer.GroupTransparency = transparency
end

local function SetTerminalTimeVisibility(isVisible: boolean)

	
	local isVisibleIsValid = AssertHelper.InvalidArgAssert(
		type(isVisible) == "boolean",
		isVisible,
		"isVisible",
		"SetTerminalTimeVisibility",
		"boolean"
	)
	
	if(not isVisibleIsValid) then return end
	
	if(not terminalOwnerTimeText) then return end
	
	local transparency: number? = nil
	
	if(isVisible) then
		transparency = 0
	else
		transparency = 1
	end
	terminalOwnerTimeText.TextTransparency = transparency
end

local function TweenTerminalCaptureTextVisibility(isVisible: boolean)
	local isVisibleIsValid = AssertHelper.InvalidArgAssert(
		type(isVisible) == "boolean",
		isVisible,
		"isVisible",
		"TweenTerminalSecondaryInfoVisibility",
		"boolean"
	)
	
	if(not isVisibleIsValid) then return end
	
	if(not terminalCaptureText
		or (not terminalFillbarContainer)) then
		return	
	end
	
	
	local transparency: number? = nil
	if(isVisible) then
		transparency = 0
	else
		transparency = 1
	end
	
	local tweenInfoUsed: TweenInfo? = nil
	if(isVisible) then
		tweenInfoUsed = terminalUiAppearTweenInfo
	else
		tweenInfoUsed = terminalUiDisappearTweenInfo
	end
	local captureTextTransparencyTween = TweenService:Create(terminalCaptureText,
		tweenInfoUsed,
		{
			TextTransparency = transparency
		}
	)
	captureTextTransparencyTween:Play()
end

local function TweenTerminalOwnerTimeTextVisibility(isVisible: boolean)
	local isVisibleIsValid = AssertHelper.InvalidArgAssert(
		type(isVisible) == "boolean",
		isVisible,
		"isVisible",
		"TweenTerminalOwnerTimeTextVisibility",
		"boolean"
	)
	
	if(not isVisibleIsValid) then return end
	
	if(not terminalOwnerTimeText) then return end
	
	local transparency: number? = nil
	local tweenInfoUsed: TweenInfo? = nil

	if(isVisible) then
		transparency = 0
		tweenInfoUsed = terminalUiAppearTweenInfo
	else
		tweenInfoUsed = terminalUiDisappearTweenInfo
		transparency = 1
	end
	
	local tween = TweenService:Create(terminalOwnerTimeText,
		tweenInfoUsed,
		{
			TextTransparency = transparency
		}
	)
	tween:Play()
end

local function TweenTerminalFillbarVisibility(isVisible: boolean)
	local isVisibleIsValid = AssertHelper.InvalidArgAssert(
		type(isVisible) == "boolean",
		isVisible,
		"isVisible",
		"TweenTerminalFillbarVisibility",
		"boolean"
	)
	
	if(not isVisibleIsValid) then return end
	
	local transparency = 0
	if(not isVisible) then
		transparency = 1
	end
	
	local tweenInfoUsed: TweenInfo? = nil
	
	if(not isVisible) then
		tweenInfoUsed = terminalUiDisappearTweenInfo
	else
		tweenInfoUsed = terminalUiAppearTweenInfo
	end
	
	local tween = TweenService:Create(terminalFillbarContainer,
		tweenInfoUsed,
		{
			GroupTransparency = transparency
		}
	)
	tween:Play()
end

local function SetTerminalFillbarVisibility(isVisible: boolean)
	local isVisibleIsValid = AssertHelper.InvalidArgAssert(
		type(isVisible) == "boolean",
		isVisible,
		"isVisible",
		"SetTerminalFillbarVisibility",
		"boolean"
	)
	
	if(not isVisibleIsValid) then return end
	
	if(not terminalFillbarContainer) then return end
	
	local transparency = 0
	if(not isVisible) then
		transparency = 1
	end
	
	terminalFillbarContainer.GroupTransparency = transparency
end

const function InitializeTerminalVisibilityHandler()
	const localPlayer = Players.LocalPlayer
	
	const currentTeam = localPlayer.Team
	if(terminalOwner) then
		if(currentTeam == Teams.Choosing) then
			terminalOwner.Enabled = false
		else
			terminalOwner.Enabled = true
		end
	end
	localPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		if(not terminalOwner) then return end
		
		if(localPlayer.Team == Teams.Choosing) then
			terminalOwner.Enabled = false
		else
			terminalOwner.Enabled = true
		end
	end)
	
end

function TerminalUiSystem.Initialize()
	Promise.try(function()
		InitializeUiElements()
		InitializeTerminalVisibilityHandler()

	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
	
	
	Replica.OnNew(ClientReplicaConfig.replicaTokenNames.Terminal.Name, function(replica)
		local data = replica.Data
		local terminalCaptureTime = data["TerminalCaptureTime"]
		local terminalCaptureTimeIsValid = AssertHelper.ExpectedValAssert(
			type(terminalCaptureTime) == "number",
			terminalCaptureTime,
			"terminalTime",
			"number"
		)
		if(not terminalCaptureTimeIsValid) then return end
		
		SetTerminalOwnerCaptureTime(terminalCaptureTime)
		SetFillbarContainerScale(terminalCaptureTime)
		
		local terminalOwner: Team? = data["TerminalOwner"]
		local terminalOwnerIsValid = AssertHelper.ExpectedValAssert(
			typeof(terminalOwner) == "Instance"
			and terminalOwner:IsA("Team"),
			terminalOwner,
			"terminalOwner",
			"TerminalUiSystem.Initialize",
			"Team"
		)
		if(not terminalOwnerIsValid) then return end
		
		SetTerminalOwnerMessage(terminalOwner)


		local teamsOnTerminalState: TerminalConfig.TeamsOnTerminalState? = data["TeamsOnTerminalState"]
		local teamsOnTerminalStateIsValid = AssertHelper.ExpectedValAssert(
			TerminalConfig.teamsOnTerminalStates[teamsOnTerminalState] ~= nil,
			teamsOnTerminalState,
			"teamsOnTerminalState",
			"Initialize",
			"TeamsOnTerminalState"
		)
		if(not teamsOnTerminalStateIsValid) then return end
		
		SetTerminalCaptureText(teamsOnTerminalState)
		
		
		local terminalContestState: TerminalConfig.TerminalContestState? = data["TerminalContestState"]
		local terminalContestStateIsValid = AssertHelper.ExpectedValAssert(
			TerminalConfig.terminalContestStates[terminalContestState] ~= nil,
			terminalContestState,
			"terminalContestState",
			"Initialize",
			"TerminalContestState"
		)
		if(not terminalContestStateIsValid) then return end
		if(terminalContestState ~= TerminalConfig.terminalContestStates.Uncontested.Name) then
			SetTerminalCaptureTextVisibility(true)
		else
			SetTerminalCaptureTextVisibility(false)
		end
		
		if(terminalContestState ~= TerminalConfig.terminalContestStates.Uncontested.Name) then
			SetTerminalTimeVisibility(true)
		else
			SetTerminalTimeVisibility(false)
		end
		
		local terminalOwnerMaxTimeReached = data["TerminalOwnerMaxTimeReached"]
		local terminalOwnerMaxTimeReachedIsValid = AssertHelper.ExpectedValAssert(
			type(terminalOwnerMaxTimeReached) == "boolean",
			terminalOwnerMaxTimeReached,
			"terminalOwnerMaxTimeReached",
			"Initialize",
			"boolean"
		)
		if(not terminalOwnerMaxTimeReachedIsValid) then return end
		local terminalOwnerCaptureTime = data["TerminalOwnerCaptureTime"]
		local terminalOwnerCaptureTimeIsValid = AssertHelper.ExpectedValAssert(
			type(terminalOwnerCaptureTime) == "number",
			terminalOwnerCaptureTime,
			"terminalOwnerCaptureTime",
			"Initialize",
			"number"
		)
		if(not terminalOwnerCaptureTimeIsValid) then return end
		
		local terminalIsBeingCaptured = terminalCaptureTime ~= 0
			or (terminalOwner ~= TeamConfig.teams.Guards.Team
				and (not terminalOwnerMaxTimeReached))
		if(terminalOwnerMaxTimeReached
			or (not terminalIsBeingCaptured)) then
			SetTerminalTimeVisibility(false)
			SetTerminalFillbarVisibility(false)
		else
			SetTerminalTimeVisibility(true)
			SetTerminalFillbarVisibility(true)
		end
		
		replica:OnSet({"TerminalCaptureTime"}, function(newValue: number, oldValue: number)
			local replicaData = replica.Data
			local currentTerminalOwner: Team? = replicaData["TerminalOwner"]
			local currentTerminalOwnerIsValid = AssertHelper.ExpectedValAssert(
				typeof(currentTerminalOwner) == "Instance"
				and currentTerminalOwner:IsA("Team"),
				currentTerminalOwner,
				"terminalOwner",
				"Team"
			)
			if(not currentTerminalOwnerIsValid) then return end
			local terminalIsBeingCaptured = newValue ~= 0
				or (currentTerminalOwner ~= TeamConfig.teams.Guards.Team
					and (not terminalOwnerMaxTimeReached))
			
			SetFillbarContainerScale(newValue)
			
			if(terminalIsBeingCaptured) then
				SetTerminalFillbarVisibility(true)
			else
				TweenTerminalFillbarVisibility(false)
			end
		end)
		
		replica:OnSet({"TerminalOwnerMaxTimeReached"}, function(
			newValue: boolean,
			oldValue: boolean
		)
			local replicaData = replica.Data
			local currentTerminalOwner: Team? = replicaData["TerminalOwner"]
			local currentTerminalOwnerIsValid = AssertHelper.ExpectedValAssert(
				typeof(currentTerminalOwner) == "Instance"
					and currentTerminalOwner:IsA("Team"),
				currentTerminalOwner,
				"terminalOwner",
				"Team"
			)
			if(not currentTerminalOwnerIsValid) then return end
			
			local currentCaptureTime = replicaData["TerminalCaptureTime"]
			local currentCaptureTimeIsValid = AssertHelper.ExpectedValAssert(
				type(currentCaptureTime) == "number",
				currentCaptureTime,
				"captureTime",
				"Initialize",
				"number"
			)
			if(not currentCaptureTimeIsValid) then return end
			local terminalIsBeingCaptured = currentCaptureTime ~= 0
				or (currentTerminalOwner ~= TeamConfig.teams.Guards.Team
					and (not newValue))
			if(newValue) then
				TweenTerminalOwnerTimeTextVisibility(false)
			end
			
			if(not terminalIsBeingCaptured) then
				TweenTerminalFillbarVisibility(false)
			end
		end)
		
		replica:OnSet({"TerminalOwnerCaptureTime"}, function(
			newValue: number,
			oldValue: number
		)
			SetTerminalOwnerCaptureTime(newValue)
		end)
		
		replica:OnSet({"TerminalOwner"}, function(
			newValue: Team,
			oldValue: Team
		)
			ClientSoundService.PlayLocalSound(TerminalUiSystemConfig.terminalAnnouncementSoundConfigs.TerminalCompromised.SoundConfig)

			if(newValue ~= TeamConfig.teams.Guards.Team) then
				SetTerminalTimeVisibility(true)	
				TweenTerminalFillbarVisibility(true)
			else
				SetTerminalTimeVisibility(false)
				TweenTerminalFillbarVisibility(false)
			end
			SetTerminalOwnerMessage(newValue)
			
		end)
		
		replica:OnSet({"TeamsOnTerminalState"}, function(newValue: TerminalConfig.TeamsOnTerminalState,
			oldValue: TerminalConfig.TeamsOnTerminalState
		)
			SetTerminalCaptureText(newValue)
		end)
		
		replica:OnSet({"TerminalContestState"}, function(newValue: TerminalConfig.TerminalContestState,
			oldValue: TerminalConfig.TerminalContestState
		)
			if(newValue ~= TerminalConfig.terminalContestStates.Uncontested.Name) then
				SetTerminalCaptureTextVisibility(true)
			elseif(newValue == TerminalConfig.terminalContestStates.Uncontested.Name
				and newValue ~= oldValue) then
				TweenTerminalCaptureTextVisibility(false)
			end
			if(newValue == TerminalConfig.terminalContestStates.GuardsContesting.Name) then
				terminalOwnerFillbarStyleSheet:SetDerives({GuardsTeamTheme})
			elseif(newValue == TerminalConfig.terminalContestStates.SubjectsContesting.Name) then
				terminalOwnerFillbarStyleSheet:SetDerives({SubjectsTeamTheme})
			end
		end)
		
	end)
end

return TerminalUiSystem
