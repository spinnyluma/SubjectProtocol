local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")


local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

local teamSelection: ScreenGui? = nil
local guardsButton: ImageButton? = nil
local subjectsButton: ImageButton? = nil

local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)

local selectTeamRE = ReplicatedStorage.Assets.Shared.Remotes.Events.SelectTeam

local TeamSelectionUiSystem = {}

local function InitializeTeamSelectionButtons()
	local guardsButtonIsValid = AssertHelper.ExpectedValAssert(
		typeof(guardsButton) == "Instance"
			and guardsButton:IsA("ImageButton"),
		guardsButton,
		"guardsButton",
		"ImageButton"
	)
	
	if(not guardsButtonIsValid) then
		return
	end
	
	local subjectsButtonIsValid = AssertHelper.ExpectedValAssert(
		typeof(subjectsButton) == "Instance"
			and subjectsButton:IsA("ImageButton"),
		subjectsButton,
		"subjectsButton",
		"ImageButton"
	)
	if(not subjectsButtonIsValid) then
		return
	end
	
	guardsButton.Activated:Connect(function()
		selectTeamRE:FireServer(TeamConfig.teams.Guards.Team)
	end)
	
	subjectsButton.Activated:Connect(function()
		selectTeamRE:FireServer(TeamConfig.teams.Subjects.Team)
	end)
end

local function InitializeUiElements()
	local localPlayer = Players.LocalPlayer
	local localPlayerIsValid = AssertHelper.ExpectedValAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"Player"
	)
	if(not localPlayerIsValid) then return end
	
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	teamSelection = playerGui:WaitForChild("TeamSelection")
	local background = teamSelection:WaitForChild("Background")
	local teamSelectionLayout = background:WaitForChild("TeamSelectionLayout")
	local teamSelectionList = teamSelectionLayout:WaitForChild("TeamSelectionList")
	
	guardsButton = teamSelectionList:WaitForChild("GuardsButton")
	subjectsButton = teamSelectionList:WaitForChild("SubjectsButton")
end

local function InitializeTeamSelectionUi()
	local localPlayer = Players.LocalPlayer
	local localPlayerIsValid = AssertHelper.ExpectedValAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"Player"
	)
	if(not localPlayerIsValid) then return end
	
	local playerTeam = localPlayer.Team
	local playerTeamIsValid = AssertHelper.ExpectedValAssert(
		typeof(playerTeam) == "Instance"
			and playerTeam:IsA("Team"),
		playerTeam,
		"playerTeam",
		"Team"
	)
	if(not playerTeamIsValid) then return end
	
	local teamSelectionIsValid = AssertHelper.ExpectedValAssert(
		typeof(teamSelection) == "Instance"
			and teamSelection:IsA("ScreenGui"),
		teamSelection,
		"teamSelection",
		"ScreenGui"
	)
	if(not teamSelectionIsValid) then return end
	
	if(playerTeam == TeamConfig.teams.Choosing.Team) then
		teamSelection.Enabled = true
	else
		teamSelection.Enabled = false
	end
	
	localPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		if(localPlayer.Team == TeamConfig.teams.Choosing.Team) then
			teamSelection.Enabled = true
		else
			teamSelection.Enabled = false
		end
	end)
end

function TeamSelectionUiSystem.Initialize()
	InitializeUiElements()
	InitializeTeamSelectionButtons()
	InitializeTeamSelectionUi()
end

return TeamSelectionUiSystem
