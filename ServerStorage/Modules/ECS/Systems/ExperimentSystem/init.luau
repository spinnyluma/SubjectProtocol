local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")



local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local DataModelHelper = require(ReplicatedStorage.Modules.Helpers.DataModel.DataModelHelper)

local ExperimentSystemConfig = require(script.Config)
local ExperimentConfig = require(ReplicatedStorage.Modules.Shared.Constants.ExperimentConfig)
local SpatialQueryConfig = require(ReplicatedStorage.Modules.Shared.Constants.SpatialQueryConfig)
local PlayerConfig = require(ServerStorage.Modules.ECS.Systems.PlayerSystem.Config)
local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)

local ExperimentMachineComponent = require(ServerStorage.Modules.ECS.Components.ExperimentMachineComponent)
local ExperimentHandlers = require(script.ExperimentHandlers)




local SystemManagerModule = require(ReplicatedStorage.Modules.ECS.SystemManagerModule)


local ExperimentSystem = {}



local function GetExperimentablePlayersFromParts(parts: {BasePart?})
	local partsIsValid = AssertHelper.InvalidArgAssert(
		typeof(parts) == "table",
		parts,
		"parts",
		"GetExperimentablePlayersFromParts",
		"table"
	)
	if not partsIsValid then return end
	
	local players = {}
	for _, part in parts do
		local playerCharacter = DataModelHelper.GetRootParentWithTag(part, PlayerConfig.PLAYER_TAG_NAME)
		local player: Player? = Players:GetPlayerFromCharacter(playerCharacter)
		if(not player) then
			continue
		end
		local playerInTableIndex = table.find(players, player)
		local playerTeam = player.Team
		
		if not playerInTableIndex 
			and playerTeam == TeamConfig.teams.Subjects.Team
		then
			table.insert(players, player)
		end
	end
	return players
end

local function SetExperimentMachineDoorState(experimentMachine: Model, visible: boolean)
	local experimentMachineIsValid = AssertHelper.InvalidArgAssert(
		typeof(experimentMachine) == "Instance"
		and experimentMachine:IsA("Model"),
		experimentMachine,
		"experimentMachine",
		"SetExperimentMachineDoorState",
		"Model"
	)
	if not experimentMachineIsValid then return end
	
	local visibleIsValid = AssertHelper.InvalidArgAssert(
		typeof(visible) == "boolean",
		visible,
		"visible",
		"SetExperimentMachineDoorState",
		"boolean"
	)
	if not visibleIsValid then return end
	
	local door = experimentMachine.Door
	local doorIsValid = AssertHelper.ExpectedValAssert(
		typeof(door) == "Instance"
		and door:IsA("BasePart"),
		door,
		"door",
		"BasePart"
	)
	if not doorIsValid then return end
	
	local newTransparency = 0
	if(visible) then
		newTransparency = 0
	else
		newTransparency = 1
	end
	door.Transparency = newTransparency
	door.CanCollide = visible
	
end

local function OperateExperimentMachine(experimentMachine: Model)
	local experimentMachineIsValid = AssertHelper.InvalidArgAssert(
		typeof(experimentMachine) == "Instance"
		and experimentMachine:IsA("Model"),
		experimentMachine,
		"experimentMachine",
		"OperateExperimentMachine",
		"Model"
	)
	if not experimentMachineIsValid then return end
	
	local experimentOperating: boolean? = experimentMachine:GetAttribute(ExperimentConfig.EXPERIMENT_OPERATING_ATTR_NAME)
	local experimentOperatingIsValid = AssertHelper.ExpectedValAssert(
		type(experimentOperating) == "boolean",
		experimentOperating,
		"experimentOperating",
		"boolean"
	)
	if not experimentOperatingIsValid then return end
	
	if(experimentOperating) then return end
	local experimentType = experimentMachine:GetAttribute(ExperimentSystemConfig.EXPERIMENT_TYPE_ATTR_NAME)
	local experimentTypeIsValid = AssertHelper.ExpectedValAssert(
		typeof(experimentType) == "string",
		experimentType,
		"experimentType",
		"string"
	)
	if not experimentTypeIsValid then return end
	
	local origin = experimentMachine.Origin
	local originIsValid = AssertHelper.ExpectedValAssert(
		typeof(origin) == "Instance"
		and origin:IsA("BasePart"),
		origin,
		"origin",
		"BasePart"
	)
	if not originIsValid then return end
	
	
	
	local originCFrame = origin.CFrame
	local originSize = origin.Size
	
	local overlapParams = SpatialQueryConfig.GetOverlapParams(ExperimentConfig.EXPERIMENT_MACHINE_TAG_NAME, {
		["Self"] = experimentMachine
	})
	local parts = workspace:GetPartBoundsInBox(origin.CFrame,
		originSize,
		overlapParams
	)

	local players: {Player?} = GetExperimentablePlayersFromParts(parts)
	if(not players) then return end
	
	if(#players > 0) then
		experimentMachine:SetAttribute(ExperimentSystemConfig.EXPERIMENT_OPERATING_ATTR_NAME, true)
			SetExperimentMachineDoorState(experimentMachine, true)
	end
	
	task.delay(5, function()
		for _, player in players do
			ExperimentHandlers.ExecuteExperimentByType(player, experimentType)
		end
		experimentMachine:SetAttribute(ExperimentConfig.EXPERIMENT_OPERATING_ATTR_NAME, false)
		SetExperimentMachineDoorState(experimentMachine, false)
	end)
	
	
end

local function InitializeExperimentSystems()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player)
		local parent = DataModelHelper.GetRootParentWithTag(prompt, ExperimentConfig.EXPERIMENT_MACHINE_TAG_NAME)
		if(parent) then
			OperateExperimentMachine(parent)
		end	
	end)
	
end

function ExperimentSystem.Initialize()
	InitializeExperimentSystems()
end

return ExperimentSystem
