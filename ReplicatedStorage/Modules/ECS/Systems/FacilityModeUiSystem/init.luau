local ReplicatedStorage = game:GetService("ReplicatedStorage")
const SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
const Teams = game:GetService("Teams")

local ClientReplicaConfig = require(ReplicatedStorage.Modules.Shared.Constants.ClientReplicaConfig)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local ModeConfig = require(ReplicatedStorage.Modules.Shared.Constants.ModeConfig)
local Replica = require(ReplicatedStorage.Modules.Utilities.ReplicaClient)

local Config = require(script.Config)

const ClientSoundService = require("../../Services/Sound/ClientSoundService")
const DictionaryHelper = require("../../Helpers/Table/DictionaryHelper")
const SoundConfig = require("../../Shared/Constants/Sound/SoundConfig")
const Promise = require("../../Utilities/Promise")
const t = require("../../Utilities/t")

local facilityModeSelection: ScreenGui? = nil
local facilityModeContainer: Frame? = nil
local modeSelectionButtons: Frame? = nil
local voteTimeFillbar: Frame? = nil

local modeLabel: TextLabel? = nil
local objectiveLabel: TextLabel? = nil
local modeTimerLabel: TextLabel? = nil
local objectiveScreen: ScreenGui? = nil

local selectionButton: ImageButton = ReplicatedStorage.Assets.UI.Templates.SelectionButton

local submitModeVote: RemoteEvent = ReplicatedStorage.Assets.Shared.Remotes.Events.SubmitModeVote

local FacilityModeUiSystem = {}


local currentlyPlayedActionMusic: Sound? = nil


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

	objectiveScreen = playerGui:WaitForChild("Objective")
	local objectiveFrame = objectiveScreen:WaitForChild("ObjectiveFrame")
	modeLabel = objectiveFrame:WaitForChild("ModeLabel")
	modeTimerLabel = objectiveFrame:WaitForChild("ModeTimer")
	objectiveLabel = objectiveFrame:WaitForChild("ObjectiveLabel")
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

local function UpdateObjectiveGui(mode: string?)
	if not mode then return end

	local localPlayer = Players.LocalPlayer
	local team = localPlayer.Team
	if not team then return end

	local modeData = ModeConfig.modes[mode]
	if not modeData then return end

	local teamObjectives = Config.modeObjectives[mode]
	if not teamObjectives then return end

	local objectiveData = teamObjectives[team]
	if not objectiveData then return end

	if modeLabel then
		modeLabel.Text = "FACILITY MODE: " .. modeData.UserFriendlyName
	end
	if objectiveLabel then
		objectiveLabel.Text = "Objective: " .. objectiveData.Objective
	end
end

const function PlayRandomActionMusic(): Sound?
	const randomMusicConfig: SoundConfig.SoundConfig? = DictionaryHelper.GetRandomValueFromDict(SoundConfig.clientSoundConfigs["Action"])
	const randomMusicConfigIsValid, randomMusicConfigInvalidityReason = t.table(randomMusicConfig)
	if(not randomMusicConfigIsValid) then
		AssertHelper.Warn(randomMusicConfigInvalidityReason)
		return
	end	
	
	const sound = ClientSoundService.PlayLocalSound(randomMusicConfig)
	return sound
end

const function SetModeTimerLabelText(text: string)
	const textIsValid, textInvalidityReason = t.string(text)
	if(not textIsValid) then
		AssertHelper.Warn(textInvalidityReason)
		return 
	end
	
	if(not modeTimerLabel) then return end
	
	modeTimerLabel.Text = text
end

const function InitializeObjectiveVisibilityHandler()
	const localPlayer = Players.LocalPlayer
	const currentTeam = localPlayer.Team
	if(objectiveScreen) then
		if(currentTeam == Teams.Choosing) then
			objectiveScreen.Enabled = false
		else
			objectiveScreen.Enabled = true
		end	
	end
	localPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		if(not objectiveScreen) then return end
		
		if(localPlayer.Team == Teams.Choosing) then
			objectiveScreen.Enabled = false
		else
			objectiveScreen.Enabled = true
		end
	end)
end

function FacilityModeUiSystem.Initialize()
	Promise.try(function()
		InitializeUiElements()
		InitializeObjectiveVisibilityHandler()

	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
	Replica.OnNew(ClientReplicaConfig.replicaTokenNames.Mode.Name, function(replica: Replica.Replica)

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

	Replica.OnNew(ClientReplicaConfig.replicaTokenNames.CurrentMode.Name, function(replica: Replica.Replica)
		local data = replica.Data
		local currentMode = data.CurrentMode

		

		UpdateObjectiveGui(currentMode)
		if(currentMode ~= ModeConfig.modes.Idle.Name) then
			currentlyPlayedActionMusic = PlayRandomActionMusic()
		end
		replica:OnSet({"CurrentMode"}, function(newMode: any, oldMode: any)
			currentMode = newMode
			UpdateObjectiveGui(newMode)
			
			const modeSoundConfigEnum = ModeConfig.modeAnnouncementSoundConfigs[newMode]
			if(modeSoundConfigEnum) then
				const modeSoundConfig = modeSoundConfigEnum.SoundConfig
				if(modeSoundConfig) then
					const modeSound = ClientSoundService.PlayLocalSound(modeSoundConfig)
					print(modeSound)
					if(modeSound) then
						modeSound.Ended:Once(function()
							modeSound:Destroy()
						end)
					end
			end
			
			end
			if(currentMode ~= ModeConfig.modes.Idle.Name) then
				currentlyPlayedActionMusic = PlayRandomActionMusic()
			else
				if(currentlyPlayedActionMusic) then
					Promise.try(function()
						ClientSoundService.FadeOutSound(currentlyPlayedActionMusic, 2)
						currentlyPlayedActionMusic:Destroy()
						currentlyPlayedActionMusic = nil
					end)
						:catch(function(err)
							AssertHelper.Warn(tostring(err))
						end)
				end
				
			end
		end)
		replica:OnSet({"ModeRemainingTime"}, function(newValue: number, oldValue: number)
			SetModeTimerLabelText("Mode ends in " .. newValue .. "s")
		end)
		
		replica:OnSet({"ModeVoteCooldown"}, function(newValue: number, oldValue: number)
			if(newValue == 0) then
				SetModeTimerLabelText("")
			else
				SetModeTimerLabelText("Next mode may be activated in " .. newValue .. "s")

			end
			
		end)
		Players.LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
			UpdateObjectiveGui(currentMode)
		end)
	end)
end

return FacilityModeUiSystem
