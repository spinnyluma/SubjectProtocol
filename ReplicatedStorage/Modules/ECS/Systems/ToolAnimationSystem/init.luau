const CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

const AnimatorLoadingSystemSignals = require("./AnimatorLoadingSystem/Signals")
const MeleeStateComponentSignals = require("../Components/MeleeStateComponent/Signals")
const MeleeStateComponentConfig = require("../Components/MeleeStateComponent/Config")
const ToolAnimationSystemConfig = require("@self/Config")
const ToolAnimationHandlers = require("@self/ToolAnimationHandlers")
const MeleeStateComponent = require("../Components/MeleeStateComponent")
const SystemManagerModule = require("../SystemManagerModule")
const InputSystemSignals = require("./InputSystem/Signals")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const InputService = require("../../Services/Input/InputService")
const AssetConfig = require("../../Shared/Constants/AssetConfig")
const ToolConfig = require("../../Shared/Constants/ToolConfig")
const ToolHelper = require("../../Helpers/Tool/ToolHelper")
const Promise = require("../../Utilities/Promise")
const Trove = require("../../Utilities/Trove")

local ToolAnimationSystem = {}

local meleeStateSignalTroves: {[Tool]: Trove.Trove} = {}

local function InitializeEventHandlersByToolType(toolType: string, tool: Tool)
	local toolTypeIsValid = AssertHelper.InvalidArgAssert(
		type(toolType) == "string",
		toolType,
		"toolType",
		"InitializeEventHandlersByToolType",
		"string"
	)
	if(not toolTypeIsValid) then return end
	
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
		and tool:IsA("Tool"),
		tool,
		"tool",
		"InitializeEventHandlersByToolType",
		"Tool"
	)
	if(not toolIsValid) then return end
	
	local toolAnimationHandler: (Tool) -> ()? = ToolAnimationHandlers.GetToolActivationHandlerFn(toolType)
	local toolAnimationHandlerIsValid = AssertHelper.ExpectedValAssert(
		type(toolAnimationHandler) == "function",
		toolAnimationHandler,
		"toolAnimationHandler",
		"InitializeEventHandlersByToolType",
		"function"
	)
	if(not toolAnimationHandlerIsValid) then return end
	
	toolAnimationHandler(toolType, tool)
end

local function LoadAnimationGraph(
	character: Model,
	tool: Tool,
	meleeState: MeleeStateComponentConfig.MeleeState
)
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
	
	
	local toolType = ToolHelper.GetToolType(tool)
	if(not toolType) then return end
	local animationGraphId: string? = ToolAnimationSystemConfig.animationGraphIds[toolType]
	local animationGraphIdIsValid = AssertHelper.ExpectedValAssert(
		typeof(animationGraphId) == "string",
		animationGraphId,
		"animationGraphId",
		"LoadAnimationGraph",
		"string"
	)
	if(not animationGraphIdIsValid) then return end
	
	local loadedAnimatorAnimsComp = SystemManagerModule.GetComponentByEntity("LoadedAnimatorAnims", animator)
	
	local toolAnimConfig = ToolConfig.toolAnimationConfigs[tool.Name]
	local toolAnimConfigIsValid = AssertHelper.ExpectedValAssert(
		type(toolAnimConfig) == "table",
		toolAnimConfig,
		"toolAnimConfig",
		"table"
	)
	if(not toolAnimConfigIsValid) then return end

	local equipAnimLength = toolAnimConfig.EquipAnimationLength
	local equipAnimLengthIsValid = AssertHelper.ExpectedValAssert(
		type(equipAnimLength) == "number",
		equipAnimLength,
		"equipAnimLength",
		"number"
	)
	if(not equipAnimLengthIsValid) then return end
	
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
		
		local toolAnimConfig = ToolConfig.toolAnimationConfigs[tool.Name]
		local toolAnimConfigIsValid = AssertHelper.ExpectedValAssert(
			type(toolAnimConfig) == "table",
			toolAnimConfig,
			"toolAnimConfig",
			"table"
		)
		if(not toolAnimConfigIsValid) then return end
		
		local weaponId: string? = toolAnimConfig.WeaponId
		local weaponIdIsValid = AssertHelper.ExpectedValAssert(
			type(weaponId) == "string",
			weaponId,
			"weaponId",
			"string"
		)
		if(not weaponIdIsValid) then return end
		
		
		animTrack:SetParameter("WeaponId", weaponId)
		
		if(meleeState == MeleeStateComponentConfig.states.Equip.Name) then
			print("went in equip1!!!")
			animTrack:SetParameter("IsAttacking", false)
			animTrack:SetParameter("AlternativeActionWeight", 0)
		elseif(meleeState == MeleeStateComponentConfig.states.Attacking.Name) then
			print("went in attacking")
			animTrack:SetParameter("IsAttacking", true)
			animTrack:SetParameter("AlternativeActionWeight", 1)
		end
		if(not animTrack.IsPlaying) then
			animTrack:Play()
		end	

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
		if(meleeState == MeleeStateComponentConfig.states.Equip.Name) then
			animTrack:SetParameter("IsAttacking", false)
			animTrack:SetParameter("AlternativeActionWeight", 0)
		elseif(meleeState == MeleeStateComponentConfig.states.Attacking.Name) then
			animTrack:SetParameter("IsAttacking", true)
			animTrack:SetParameter("AlternativeActionWeight", 1)
		end
		AnimatorLoadingSystemSignals.AnimatorTrackCacheRequested:Fire(animator, animTrack)
		if(not animTrack.IsPlaying) then
			animTrack:Play()
		
		end	
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

	local toolType = ToolHelper.GetToolType(tool)
	if(not toolType) then return end

	local animationGraphId: string? = ToolAnimationSystemConfig.animationGraphIds[toolType]
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

local function InitializeLoadedAnimatorAnimsHandlers()
	const localPlayer = Players.LocalPlayer
	const character = localPlayer.Character
	
	if(character) then
		character.ChildRemoved:Connect(function(child: Instance)
			Promise.try(function()
				const humanoid = character:WaitForChild("Humanoid")
				const animator = humanoid:WaitForChild("Animator")
				local loadedAnimatorAnimsComp = SystemManagerModule.GetComponentByEntity("LoadedAnimatorAnims", animator)
				if(loadedAnimatorAnimsComp) then
					local loadedAnimTracks = loadedAnimatorAnimsComp.LoadedAnimationTracks

					for id, loadedTrack in loadedAnimTracks do
						loadedTrack:Stop()
					end

				end
			end)
		end)
	end
	
	
	localPlayer.CharacterRemoving:Connect(function(character: Model)
		Promise.try(function()
			const humanoid = character:WaitForChild("Humanoid")
			const animator = humanoid:WaitForChild("Animator")
			local loadedAnimatorAnims = SystemManagerModule.GetComponentByEntity("LoadedAnimatorAnims", animator)
			if(not loadedAnimatorAnims) then return end
			
			local loadedAnimatorAnimsComp = SystemManagerModule.GetComponentByEntity("LoadedAnimatorAnims", animator)
			if(loadedAnimatorAnimsComp) then
				local loadedAnimTracks = loadedAnimatorAnimsComp.LoadedAnimationTracks
				for id, loadedTrack in loadedAnimTracks do

					loadedTrack:Stop()
				end
				SystemManagerModule.RemoveComponent("LoadedAnimatorAnims", animator)	
			end
		end)
			:catch(function(errorMsg)
				AssertHelper.Warn(tostring(errorMsg))
			end)
	end)
	
	
end


function ToolAnimationSystem.Initialize()
	InitializeLoadedAnimatorAnimsHandlers()
	MeleeStateComponentSignals.MeleeStateCreated:Connect(function(meleeStateComponent: MeleeStateComponent.MeleeStateComponent,
		tool: Tool
	)
		const localPlayer = Players.LocalPlayer
		const character = localPlayer.Character
		
		if(not meleeStateSignalTroves[tool]) then
			meleeStateSignalTroves[tool] = Trove.new()
		end
		
		local meleeStateSignalTrove = meleeStateSignalTroves[tool]
		if(not meleeStateSignalTrove) then return end
		if(character) then
			--TODO: delete connections when meleestate destroyed
			const meleeStateChangedConn = MeleeStateComponentSignals.MeleeStateChanged:Connect(function(meleeStateComponent: MeleeStateComponent.MeleeStateComponent,
				entity: Instance,
				newState: MeleeStateComponentConfig.MeleeState
			)
				LoadAnimationGraph(character, entity, newState)
			end)	
			meleeStateSignalTrove:Add(meleeStateChangedConn)
		end
		localPlayer.CharacterAdded:Connect(function(character: Model)
			const meleeStateChangedConnOnNewChar = MeleeStateComponentSignals.MeleeStateChanged:Connect(function(meleeStateComponent: MeleeStateComponent.MeleeStateComponent,
				entity: Instance,
				newState: MeleeStateComponentConfig.MeleeState
			)
				LoadAnimationGraph(character, entity, newState)
			end)
			meleeStateSignalTrove:Add(meleeStateChangedConnOnNewChar)
		end)
	end)
	
	
	MeleeStateComponentSignals.MeleeStateRemoved:Connect(function(tool: Tool)
		local meleeStateTrove = meleeStateSignalTroves[tool]
		if(meleeStateTrove) then
			meleeStateTrove:Clean()
			meleeStateSignalTroves[tool] = nil
		end
	end)
end

return ToolAnimationSystem
