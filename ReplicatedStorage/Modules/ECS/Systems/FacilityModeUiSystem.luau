local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicaConfig = require(ReplicatedStorage.Modules.Shared.Constants.ReplicaConfig)
local ModeConfig = require(ReplicatedStorage.Modules.Shared.Constants.ModeConfig)


local Replica = require(ReplicatedStorage.Modules.Utilities.ReplicaClient)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)


local facilityModeSelection: ScreenGui? = nil
local facilityModeContainer: Frame? = nil
local modeSelectionButtons: Frame? = nil
local voteTimeFillbar: Frame? = nil

local selectionButton: ImageButton = ReplicatedStorage.Assets.UI.Templates.SelectionButton

local submitModeVote: RemoteEvent = ReplicatedStorage.Assets.Shared.Remotes.Events.SubmitModeVote
local FacilityModeUiSystem = {}

local function SetFacilityModeSelectionVisibility(isVisible: boolean)
	local isVisibleIsValid = AssertHelper.InvalidArgAssert(
		type(isVisible) == "boolean",
		isVisible,
		"isVisible",
		"SetFacilityModeSelectionVisibility",
		"boolean"
	)
	if(not isVisibleIsValid) then return end
	local facilityModeSelectionIsValid = AssertHelper.ExpectedValAssert(
		typeof(facilityModeSelection) == "Instance"
		and facilityModeSelection:IsA("ScreenGui"),
		facilityModeSelection,
		"facilityModeSelection",
		"ScreenGui"
	)
	if(not facilityModeSelectionIsValid) then return end
	if(isVisible) then
		facilityModeSelection.Enabled = true
	else
		facilityModeSelection.Enabled = false
	end
end

local function InitializeUiElements()
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	
	
	facilityModeSelection = playerGui:WaitForChild("FacilityModeSelection")
	facilityModeContainer = facilityModeSelection:WaitForChild("FacilityModeContainer")
	local selection = facilityModeContainer:WaitForChild("Selection")
	modeSelectionButtons = selection:WaitForChild("ModeSelectionButtons")
	
	
	local voteTime: CanvasGroup = facilityModeContainer:WaitForChild("VoteTime")
	voteTimeFillbar = voteTime:WaitForChild("Fillbar")
end

local function SetupSelectionButton(selectionButton: ImageButton, mode: ModeConfig.Mode)
	local selectionButtonIsValid = AssertHelper.InvalidArgAssert(
		typeof(selectionButton) == "Instance"
		and selectionButton:IsA("ImageButton"),
		selectionButton,
		"selectionButton",
		"SetupSelectionButton",
		"ImageButton"
	)
	if(not selectionButtonIsValid) then return false end
	local modeIsValid = AssertHelper.InvalidArgAssert(
		ModeConfig.modes[mode] ~= nil,
		mode,
		"mode",
		"SetupSelectionButton",
		"ModeConfig.Mode"
	)
	if(not modeIsValid) then return false end
	
	local modeName: string? = ModeConfig.modes[mode].UserFriendlyName
	local modeNameIsValid = AssertHelper.ExpectedValAssert(
		type(modeName) == "string",
		modeName,
		"modeName",
		"string"
	)
	if(not modeNameIsValid) then return false end
	local modeDescription: string? = ModeConfig.modeDescriptions[mode].Description
	local modeDescriptionIsValid = AssertHelper.ExpectedValAssert(
		type(modeDescription) == "string",
		modeDescription,
		"modeDescription",
		"string"
	)
	if(not modeDescriptionIsValid) then return false end
	
	local modeNameLabel: TextLabel? = selectionButton:FindFirstChild("ModeName")
	local modeNameLabelIsValid = AssertHelper.ExpectedValAssert(
		typeof(modeNameLabel) == "Instance"
		and modeNameLabel:IsA("TextLabel"),
		modeNameLabel,
		"modeNameLabel",
		"TextLabel"
	)
	if(not modeNameLabelIsValid) then return false end
	
	local modeDescriptionLabel: TextLabel? = selectionButton:FindFirstChild("ModeDescription")
	local modeDescriptionLabelIsValid = AssertHelper.ExpectedValAssert(
		typeof(modeDescriptionLabel) == "Instance"
		and modeDescriptionLabel:IsA("TextLabel"),
		modeDescriptionLabel,
		"modeDescriptionLabel",
		"TextLabel"
	)
	if(not modeDescriptionLabelIsValid) then return false end
	
	modeNameLabel.Text = modeName
	modeDescriptionLabel.Text = modeDescription
	
	return true
end

local function InitializeSelectionButtons(modes: {ModeConfig.Mode?})
	local modesIsValid = AssertHelper.ExpectedValAssert(
		type(modes) == "table",
		modes,
		"modes",
		"table"
	)
	if(not modesIsValid) then return end
	

	local modeSelectionButtonsIsValid = AssertHelper.ExpectedValAssert(
		typeof(modeSelectionButtons) == "Instance"
		and modeSelectionButtons:IsA("Frame"),
		modeSelectionButtons,
		"modeSelectionButtons",
		"Frame"
	)	
	if(not modeSelectionButtonsIsValid) then return end
	
	local selectionButtons: {ImageButton?} = modeSelectionButtons:QueryDescendants("ImageButton")
	for _, selectionButton in selectionButtons do
		selectionButton:Destroy()
	end
	for _, mode in modes do
		local clonedSelectionButton: ImageButton = selectionButton:Clone()
		local setup: boolean = SetupSelectionButton(clonedSelectionButton, mode)
		if(not setup) then continue end
		clonedSelectionButton.Activated:Connect(function(inputObject: InputObject, _)
			SetFacilityModeSelectionVisibility(false)
			submitModeVote:FireServer(mode)
			
		end)
		clonedSelectionButton.Parent = modeSelectionButtons
	end
end

local function TweenModeVoteTimeBar(modeVoteEndTime: number)
	local modeVoteEndTimeIsValid = AssertHelper.InvalidArgAssert(
		type(modeVoteEndTime) == "number",
		modeVoteEndTime,
		"modeVoteEndTime",
		"TweenModeVoteTimeBar",
		"number"
	)
	if(not modeVoteEndTimeIsValid) then return end
	
	local currentTimeLeft: number = modeVoteEndTime - workspace:GetServerTimeNow()
	if(currentTimeLeft <= 0) then
		return
	end
	
	if(not voteTimeFillbar) then return end
	local timeBarScaleX: number? = currentTimeLeft / ModeConfig.MODE_VOTE_TIME
	local timeBarScaleXIsValid = AssertHelper.ExpectedValAssert(
		timeBarScaleX > 0,
		timeBarScaleX,
		"timeBarScaleX",
		"Time fillbar X scale must be greater than 0"
	)
	
	if(not timeBarScaleXIsValid) then return end
	
	local timeBarSize: UDim2 = UDim2.fromScale(timeBarScaleX, 1)
	
	voteTimeFillbar.Size = timeBarSize
	
	local tweenInfo: TweenInfo = TweenInfo.new(
		currentTimeLeft,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In
	)
	local tween: Tween = TweenService:Create(
		voteTimeFillbar,
		tweenInfo,
		{
			Size = UDim2.fromScale(0, 1)
		}
	)
	tween:Play()
	tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
		SetFacilityModeSelectionVisibility(false)
	end)
end

function FacilityModeUiSystem.Initialize()
	InitializeUiElements()
	Replica.OnNew(ReplicaConfig.replicaTokens.Mode.Name, function(replica: Replica.Replica)

		local data = replica.Data

		local voteOngoing: boolean? = data.VoteOngoing
		local voteOngoingIsValid = AssertHelper.ExpectedValAssert(
			type(voteOngoing) == "boolean",
			voteOngoing,
			"voteStarted",
			"boolean"
		)
		if(not voteOngoingIsValid) then return end
		
		local modes: {ModeConfig.Mode?}? = data.Modes
		local modesIsValid = AssertHelper.ExpectedValAssert(
			type(modes) == "table",
			modes,
			"modes",
			"table"
		)
		if(not modesIsValid) then return end
		if(voteOngoing) then
			InitializeSelectionButtons(modes)
			SetFacilityModeSelectionVisibility(true)
		else
			SetFacilityModeSelectionVisibility(false)
		end
		replica:OnChange(function(action: string, path: {string | number}, values: any)
			
						
			if(action ~=  "SetValues"
				or (type(values) ~= "table")
				or (#path ~= 0)
				or (values["Modes"] == nil)
				or (values["VoteOngoing"] == nil)
				or (values["VoteEndTime"]) == nil) then
				
				return	
			end
			
			local voteOngoing: boolean? = values["VoteOngoing"]
			local voteOngoingIsValid = AssertHelper.ExpectedValAssert(
				type(voteOngoing) == "boolean",
				voteOngoing,
				"voteStarted",
				"boolean"
			)
			if(not voteOngoingIsValid) then return end
			
			local modes: {ModeConfig.Mode?}? = values["Modes"]
			local modesIsValid = AssertHelper.ExpectedValAssert(
				type(modes) == "table",
				modes,
				"modes",
				"table"
			)
			if(not modesIsValid) then return end
			
			local voteEndTime: number? = values["VoteEndTime"]
			local voteEndTimeIsValid = AssertHelper.ExpectedValAssert(
				type(voteEndTime) == "number",
				voteEndTime,
				"voteEndTime",
				"number"
			)
			if(not voteEndTimeIsValid) then return end
			if(voteOngoing) then
				InitializeSelectionButtons(modes)
				SetFacilityModeSelectionVisibility(true)
				TweenModeVoteTimeBar(voteEndTime)
			else
				SetFacilityModeSelectionVisibility(false)
			end
		end)
			
		
	end)
end

return FacilityModeUiSystem
