const CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

const AnimatorLoadingSystemSignals = require("./AnimatorLoadingSystem/Signals")
const ToolAnimationHandlers = require("@self/ToolAnimationHandlers")
const SystemManagerModule = require("../SystemManagerModule")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const AssetConfig = require("../../Shared/Constants/AssetConfig")
const ToolConfig = require("../../Shared/Constants/ToolConfig")


local usingMeleeTool = ReplicatedStorage.Assets.Input.Contexts.UsingMeleeTool

local animationGraphIds = {
	[ToolConfig.toolTypes.TwoHandedTool.Name] = "134652981384574" 
}


local inputContextsByToolType = {
	[ToolConfig.toolTypes.TwoHandedTool.Name] = usingMeleeTool
}


local ToolAnimationSystem = {}

local function GetToolType(tool: Tool)
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
		and tool:IsA("Tool"),
		tool,
		"tool",
		"GetToolType",
		"Tool"
	)
	if(not toolIsValid) then return end
	
	local toolTypeObtained: string? = nil
	
	for _, toolType in ToolConfig.toolTypes do
		local toolTypeTag = toolType.Tag
		if(not toolTypeTag) then continue end
		if(CollectionService:HasTag(tool, toolTypeTag)) then
			toolTypeObtained = toolType.Name
			break
		end
	end
	
	return toolTypeObtained
end

local function InitializeEventHandlersByToolType(toolType: string)
	local toolTypeIsValid = AssertHelper.InvalidArgAssert(
		type(toolType) == "string",
		toolType,
		"toolType",
		"InitializeEventHandlersByToolType",
		"string"
	)
	if(not toolTypeIsValid) then return end
	
	local toolAnimationHandler: (Tool) -> ()? = ToolAnimationHandlers.GetToolActivationHandlerFn(toolType)
	toolAnimationHandler(toolType)
	
end

local function LoadAnimationGraph(character: Model, tool: Tool)
	local characterIsValid = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
		and character:IsA("Model"),
		character,
		"character",
		"LoadAnimationGraph",
		"Model"
	)	
	if(not characterIsValid) then return end
	
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
		and tool:IsA("Tool"),
		tool,
		"tool",
		"LoadAnimationGraph",
		"Tool"
	)
	if(not toolIsValid) then return end
	
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if(not humanoid) then return end
	
	local animator = humanoid:FindFirstChildWhichIsA("Animator")
	if(not animator) then return end
	
	
	
	local toolType = GetToolType(tool)
	if(not toolType) then return end

	local animationGraphId: string? = animationGraphIds[toolType]
	local animationGraphIdIsValid = AssertHelper.ExpectedValAssert(
		typeof(animationGraphId) == "string",
		animationGraphId,
		"animationGraphId",
		"LoadAnimationGraph",
		"string"
	)
	if(not animationGraphIdIsValid) then return end
	
	local loadedAnimatorAnimsComp = SystemManagerModule.GetComponentByEntity("LoadedAnimatorAnims", animator)
	if(loadedAnimatorAnimsComp) then
		local loadedAnimTracks = loadedAnimatorAnimsComp.LoadedAnimationTracks
		local loadedAnimTracksIsValid = AssertHelper.ExpectedValAssert(
			type(loadedAnimTracks) == "table",
			loadedAnimTracks,
			"loadedAnimTracks",
			"table"
		)
		if(not loadedAnimTracksIsValid) then return end
		
		local animTrack = loadedAnimTracks[AssetConfig.assetIdPrefix 
			.. animationGraphId]
		local animTrackIsValid = AssertHelper.ExpectedValAssert(
			typeof(animTrack) == "Instance"
			and animTrack:IsA("AnimationTrack"),
			animTrack,
			"animTrack",
			"LoadAnimationGraph",
			"AnimationTrack"
		)
		if(not animTrackIsValid) then return end
		
		animTrack:Play()
		InitializeEventHandlersByToolType(toolType)
	else
		local animationGraph = Instance.new("Animation")
		
		
		
		animationGraph.AnimationId = AssetConfig.assetIdPrefix 
			.. animationGraphId
		local animTrack = animator:LoadAnimation(animationGraph)
		local toolConfig = ToolConfig.toolAnimationConfigs[tool.Name]
		if(toolConfig) then 
			local weaponId = toolConfig.WeaponId
			animTrack:SetParameter("WeaponId", weaponId)
		end
		
		AnimatorLoadingSystemSignals.AnimatorTrackCacheRequested:Fire(animator, animTrack)
		animTrack.Priority = Enum.AnimationPriority.Action
		
		animTrack:Play()
		InitializeEventHandlersByToolType(toolType)
	end
end

local function UnloadAnimationGraph(character: Model, tool: Tool)
	local characterIsValid = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
		and character:IsA("Model"),
		character,
		"character",
		"UnloadAnimationGraph",
		"Model"
	)	
	if(not characterIsValid) then return end
	
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
		and tool:IsA("Tool"),
		tool,
		"tool",
		"UnloadAnimationGraph",
		"Tool"
	)
	if(not toolIsValid) then return end
	
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
			and tool:IsA("Tool"),
		tool,
		"tool",
		"LoadAnimationGraph",
		"Tool"
	)
	if(not toolIsValid) then return end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if(not humanoid) then return end

	local animator = humanoid:FindFirstChildWhichIsA("Animator")
	if(not animator) then return end

	local toolType = GetToolType(tool)
	if(not toolType) then return end

	local animationGraphId: string? = animationGraphIds[toolType]
	local animationGraphIdIsValid = AssertHelper.ExpectedValAssert(
		typeof(animationGraphId) == "string",
		animationGraphId,
		"animationGraphId",
		"LoadAnimationGraph",
		"string"
	)
	if(not animationGraphIdIsValid) then return end
	
	local component = SystemManagerModule.GetComponentByEntity("LoadedAnimatorAnims", animator)
	if(component) then
		local toolLoadedAnimTracks = component.LoadedAnimationTracks
		local loadedAnimationTrack = toolLoadedAnimTracks[AssetConfig.assetIdPrefix 
			.. animationGraphId]
		if(not loadedAnimationTrack) then return end
		loadedAnimationTrack:Stop()
	end
end


local function ActivateInputContextByToolType(toolType: string)
	local toolTypeIsValid = AssertHelper.InvalidArgAssert(
		typeof(toolType) == "string",
		toolType,
		"toolType",
		"ActivateInputContextByToolType",
		"string"
	)
	if(not toolTypeIsValid) then return end
	
	
end

local function ActivateInputContext(tool: Tool)
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
			and tool:IsA("Tool"),
		tool,
		"tool",
		"ActivateInputContext",
		"Tool"
	)
	if(not toolIsValid) then return end
	
	local toolType = GetToolType(tool)
	if(not toolType) then return end

	
end


local function InitializeToolAnimationHandlers()
	local localPlayer = Players.LocalPlayer
	
	local character = localPlayer.Character
	if(character) then
		character.ChildAdded:Connect(function(child: Instance)
			if(child:IsA("Tool")) then
				LoadAnimationGraph(character, child)
			end
		end)
		
		character.ChildRemoved:Connect(function(child: Instance)
			if(child:IsA("Tool")) then
				UnloadAnimationGraph(character, child)
			end
		end)
	end
	localPlayer.CharacterAdded:Connect(function(character: Model)
		character.ChildAdded:Connect(function(child: Instance)
			if(child:IsA("Tool")) then
				LoadAnimationGraph(character, child)
			end
		end)

		character.ChildRemoved:Connect(function(child: Instance)
			if(child:IsA("Tool")) then
				UnloadAnimationGraph(character, child)
			end
		end)
		

	end)
	
	
	
end



function ToolAnimationSystem.Initialize()
	InitializeToolAnimationHandlers()
	
end

return ToolAnimationSystem
