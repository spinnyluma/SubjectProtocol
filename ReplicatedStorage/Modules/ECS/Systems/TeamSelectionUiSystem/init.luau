local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)

const CameraService = require("../../Services/Camera/CameraService")
const InputSystem = require("./InputSystem")
const Promise = require("../../Utilities/Promise")
const Icon = require("../../Utilities/TopbarPlus/Icon")

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

const function SetCameraToTeamSelectionCamera()
	Promise.try(function()
		const camCframePart: BasePart = workspace:WaitForChild("TeamSelectionCamCframePart")
		CameraService.SetCameraCframe(workspace.CurrentCamera, camCframePart.CFrame)
	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
end

const function ResetCameraToLocalHumanoid()
	const localPlayer = Players.LocalPlayer
	const character = localPlayer.Character
	
	Promise.try(function()
		if(character) then
			const humanoid = character:WaitForChild("Humanoid")
			CameraService.SetCameraSubject(workspace.CurrentCamera, humanoid)
				
		end
	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
	
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
		SetCameraToTeamSelectionCamera()		
	else
		teamSelection.Enabled = false
		ResetCameraToLocalHumanoid()
	end
	
	
	SetCameraToTeamSelectionCamera()
	localPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		if(localPlayer.Team == TeamConfig.teams.Choosing.Team) then
			SetCameraToTeamSelectionCamera()
			teamSelection.Enabled = true
		else
			teamSelection.Enabled = false
			ResetCameraToLocalHumanoid()
		end
	end)
end

const function InitializeTeamSelectionTopbar()
	const icon: Icon.Icon = Icon.new()
	
	const teamSelectionIconImageId = "135651764192293"
	icon:setImage(teamSelectionIconImageId)
	icon:setLabel("Change Team")
	icon:setOrder(1.01)
	icon:modifyTheme({
		{"IconImage", "ImageColor3", Color3.fromRGB(255,255,255), "Deselected"}
	})
	icon:oneClick(true)
	icon.selected:Connect(function()
		selectTeamRE:FireServer(TeamConfig.teams.Choosing.Team)
	end)
end

function TeamSelectionUiSystem.Initialize()
	InitializeUiElements()
	InitializeTeamSelectionButtons()
	InitializeTeamSelectionUi()
	InitializeTeamSelectionButtons()
	InitializeTeamSelectionTopbar()	
end

return TeamSelectionUiSystem
