local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")



local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local DataModelHelper = require(ReplicatedStorage.Modules.Helpers.DataModel.DataModelHelper)

local ExperimentConfig = require(script.Config)
local SpatialQueryConfig = require(ReplicatedStorage.Modules.Shared.Constants.SpatialQueryConfig)
local PlayerConfig = require(ServerStorage.Modules.ECS.Systems.PlayerSystem.Config)
local TeamConfig = require(ReplicatedStorage.Modules.Shared.Constants.TeamConfig)

local ExperimentMachineComponent = require(ServerStorage.Modules.ECS.Components.ExperimentMachineComponent)
local ExperimentHandlers = require(script.ExperimentHandlers)




local SystemManagerModule = require(ReplicatedStorage.Modules.ECS.SystemManagerModule)


local ExperimentSystem = {}

local function InitializeExperimentSystemComponent(experimentMachine: Model)
	local experimentMachineIsValid = AssertHelper.InvalidArgAssert(
		typeof(experimentMachine) == "Instance"
		and experimentMachine:IsA("Model"),
		experimentMachine,
		"experimentMachine",
		"InitializeExperimentSystemComponent",
		"Model"
	)
	if not experimentMachineIsValid then return end
	
	SystemManagerModule.AddComponent("ExperimentMachine", experimentMachine)
	
end

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

local function ApplyExperimentToPlayer(player: Player, experimentType: string)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
		and player:IsA("Player"),
		player,
		"player",
		"ApplyExperimentToPlayer",
		"Player"
	)
	if not playerIsValid then return end
	
	local experimentTypeIsValid = AssertHelper.InvalidArgAssert(
		typeof(experimentType) == "string",
		experimentType,
		"experimentType",
		"ApplyExperimentToPlayer",
		"string"
	)
	if not experimentTypeIsValid then return end
	
	
	
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
	
	local experimentMachineComponent = SystemManagerModule.GetComponentByEntity("ExperimentMachine", experimentMachine)
	local experimentMachineComponentIsValid = AssertHelper.ExpectedValAssert(
		typeof(experimentMachineComponent) == "table",
		experimentMachineComponent,
		"experimentMachineComponent",
		"table"
	)
	if not experimentMachineComponentIsValid then return end
	
	experimentMachineComponent.Operating = true
	
	local experimentType = experimentMachine:GetAttribute(ExperimentConfig.EXPERIMENT_TYPE_ATTR_NAME)
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
	
	local overlapParams = SpatialQueryConfig.GetOverlapParams(ExperimentConfig.SYSTEM_TAG_NAME, {
		["Self"] = experimentMachine
	})
	local parts = workspace:GetPartBoundsInBox(origin.CFrame,
		originSize,
		overlapParams
	)
	local players: {Player?} = GetExperimentablePlayersFromParts(parts)
	if(not players) then return end
	
	for _, player in players do
		ExperimentHandlers.ExecuteExperimentByType(player, experimentType)
	end
end

local function InitializeExperimentSystems()
	local experimentMachines = CollectionService:GetTagged(ExperimentConfig.SYSTEM_TAG_NAME)
	
	for _, experimentMachine in experimentMachines do
		InitializeExperimentSystemComponent(experimentMachine)
	end
	
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player)
		local parent = DataModelHelper.GetRootParentWithTag(prompt, ExperimentConfig.SYSTEM_TAG_NAME)
		if(parent) then
			OperateExperimentMachine(parent)
		end	
	end)
	
end

function ExperimentSystem.Initialize()
	InitializeExperimentSystems()
end

return ExperimentSystem
