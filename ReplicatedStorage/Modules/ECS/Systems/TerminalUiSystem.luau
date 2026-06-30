local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local Replica = require(ReplicatedStorage.Modules.Utilities.ReplicaClient)

local ReplicaConfig = require(ReplicatedStorage.Modules.Shared.Constants.ReplicaConfig)
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
local guardsTerminalFillbarTheme = designFolder.TerminalOwnerThemes.GuardsTerminalFillbar
local subjectsTerminalFillbarTheme = designFolder.TerminalOwnerThemes.SubjectsTerminalFillbar

local TerminalUiSystem = {}

local function InitializeUiElements()
	
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	terminalOwner = playerGui:WaitForChild("TerminalOwner")
	terminalOwnerContainer = terminalOwner:WaitForChild("TerminalOwnerContainer")
	terminalCaptureText = terminalOwnerContainer:WaitForChild("TerminalCaptureText")
	terminalOwnerTimeText = terminalOwnerContainer:WaitForChild("TerminalOwnerTimeText")
	terminalOwnerText = terminalOwnerContainer:WaitForChild("TerminalOwnerText")
	terminalFillbarContainer = terminalOwnerContainer:WaitForChild("TerminalFillbarContainer")
	terminalFillbar = terminalFillbarContainer:WaitForChild("TerminalFillbar")
			
end

local function SetTerminalTime(terminalTime: number)
	local terminalTimeIsValid = AssertHelper.InvalidArgAssert(
		type(terminalTime) == "number",
		terminalTime,
		"terminalTime",
		"SetTerminalTime",
		"number"
	)
	
	if(not terminalTimeIsValid) then
		return
	end
	
	if(not terminalCaptureText) then return end
	local formattedTime: string = string.format("%i", terminalTime)
	
	terminalOwnerTimeText.Text = formattedTime .. `/{TerminalConfig.TIME_TO_CAPTURE}`
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

local function SetTerminalSecondaryInfoVisibility(isVisible: boolean)
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
	local transparencyIsValid = AssertHelper.ExpectedValAssert(
		type(transparency) == "number",
		transparency,
		"transparency",
		"TweenTerminalSecondaryInfoVisibility",
		"number"
	)
	
	if(not transparencyIsValid) then return end
	terminalCaptureText.TextTransparency = transparency
	terminalFillbarContainer.GroupTransparency = transparency
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

local function TweenTerminalSecondaryInfoVisibility(isVisible: boolean)
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
	
	local fillbarTransparencyTween = TweenService:Create(terminalFillbarContainer,
		tweenInfoUsed,
		{
			GroupTransparency = transparency
		}
	)
	local ownerTimeTextTween = TweenService:Create(terminalOwnerTimeText,
		tweenInfoUsed,
		{
			TextTransparency = transparency
		}
	)
	
	ownerTimeTextTween:Play()
	captureTextTransparencyTween:Play()
	fillbarTransparencyTween:Play()
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
function TerminalUiSystem.Initialize()
	InitializeUiElements()
	
	Replica.OnNew(ReplicaConfig.replicaTokens.Terminal.Name, function(replica)
		local data = replica.Data
		local terminalTime = data["TerminalTime"]
		local terminalTimeIsValid = AssertHelper.ExpectedValAssert(
			type(terminalTime) == "number",
			terminalTime,
			"terminalTime",
			"number"
		)
		
		if(not terminalTimeIsValid) then return end
		
		SetTerminalTime(terminalTime)
		SetFillbarContainerScale(terminalTime)
		
		
		
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
			SetTerminalSecondaryInfoVisibility(true)
		else
			SetTerminalSecondaryInfoVisibility(false)
		end
		
		if(terminalContestState ~= TerminalConfig.terminalContestStates.Uncontested.Name) then
			SetTerminalTimeVisibility(true)
		else
			SetTerminalTimeVisibility(false)
		end
		
		replica:OnSet({"TerminalTime"}, function(newValue: number, oldValue: number)
			SetTerminalTime(newValue)
			SetFillbarContainerScale(newValue)
		end)
		
		
		
		replica:OnSet({"TerminalOwner"}, function(
			newValue: Team,
			oldValue: Team
		)

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
				TweenTerminalSecondaryInfoVisibility(true)
			else
				TweenTerminalSecondaryInfoVisibility(false)
			end
			if(newValue ~= TerminalConfig.terminalContestStates.Uncontested.Name) then
				TweenTerminalOwnerTimeTextVisibility(true)
			else
				TweenTerminalOwnerTimeTextVisibility(false)
			end
			
			if(newValue == TerminalConfig.terminalContestStates.GuardsContesting.Name) then
				terminalOwnerFillbarStyleSheet:SetDerives({guardsTerminalFillbarTheme})
			else
				terminalOwnerFillbarStyleSheet:SetDerives({subjectsTerminalFillbarTheme})
			end
		end)
		
	end)
end

return TerminalUiSystem
