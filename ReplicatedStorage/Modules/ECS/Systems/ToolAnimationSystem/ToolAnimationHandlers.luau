const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const ToolAnimationSystemConfig = require("./Config")
const SystemManagerModule = require("../../SystemManagerModule")
const InputSystemSignals = require("../InputSystem/Signals")
const AssertHelper = require("../../../Helpers/Debug/AssertHelper")
const InputService = require("../../../Services/Input/InputService")
const AssetConfig = require("../../../Shared/Constants/AssetConfig")
const ToolConfig = require("../../../Shared/Constants/ToolConfig")
const MeleeStateComponentSignals = require("../../Components/MeleeStateComponent/Signals")
const Trove = require("../../../Utilities/Trove")

local ToolAnimationHandlers = {}


ToolAnimationHandlers.toolAnimTroves = {} :: {[Tool]: Trove.Trove}




local function InitializeTwoHandedToolHandlers(toolType: string, tool: Tool)
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
		and tool:IsA("Tool"),
		tool,
		"tool",
		"InitializeTwoHandedToolHandlers",
		"Tool"
	)
	if(not toolIsValid) then return end
	
	local activatedInputContext = InputService.SetInputContextStateByToolType(toolType, true)
	local activatedInputContextIsValid = AssertHelper.ExpectedValAssert(
		typeof(activatedInputContext) == "Instance"
		and activatedInputContext:IsA("InputContext"),
		activatedInputContext,
		"activatedInputContext",
		"InputContext"
	)
	if(not activatedInputContextIsValid) then return end
	local activateToolAction = activatedInputContext.ActivateTool
	local activateToolActionIsValid = AssertHelper.ExpectedValAssert(
		typeof(activateToolAction) == "Instance"
		and activateToolAction:IsA("InputAction"),
		activateToolAction,
		"activateToolAction",
		"InputAction"
	)
	if(not activateToolActionIsValid) then return end

	local pressedConn = activateToolAction.Pressed:Connect(function()
		local localPlayer = Players.LocalPlayer
		local localPlayerIsValid = AssertHelper.ExpectedValAssert(
			typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
			localPlayer,
			"localPlayer",
			"Player"
		)
		if(not localPlayerIsValid) then return end
		local character = localPlayer.Character
		if(not character) then
			return
		end
		
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		local humanoidIsValid = AssertHelper.ExpectedValAssert(
			typeof(humanoid) == "Instance"
			and humanoid:IsA("Humanoid"),
			humanoid,
			"humanoid",
			"Humanoid"
		)
		if(not humanoidIsValid) then return end
		
		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		local animatorIsValid = AssertHelper.ExpectedValAssert(
			typeof(animator) == "Instance"
			and animator:IsA("Animator"),
			animator,
			"animator",
			"Animator"
		)
		if(not animatorIsValid) then return end
		
		local loadedAnimatorAnimComponent = SystemManagerModule.GetComponentByEntity("LoadedAnimatorAnims", animator)
		local loadedAnimatorAnimComponentIsValid = AssertHelper.ExpectedValAssert(
			type(loadedAnimatorAnimComponent) == "table",
			loadedAnimatorAnimComponent,
			"loadedAnimatorAnimComponent",
			"table"
		)
		if(not loadedAnimatorAnimComponentIsValid) then return end
		local loadedAnimationTracks = loadedAnimatorAnimComponent.LoadedAnimationTracks
		local loadedAnimationTracksIsValid = AssertHelper.ExpectedValAssert(
			typeof(loadedAnimationTracks) == "table",
			loadedAnimationTracks,
			"loadedAnimationTracks",
			"table"
		)
		if(not loadedAnimationTracksIsValid) then return end
		
		local twoHandedTypeName = ToolConfig.toolTypes.TwoHandedTool.Name
		local twoHandedAnimGraphId = ToolAnimationSystemConfig.animationGraphIds[twoHandedTypeName]
		local twoHandedAnimGraphIdIsValid = AssertHelper.ExpectedValAssert(
			typeof(twoHandedAnimGraphId) == "string",
			twoHandedAnimGraphId,
			"twoHandedAnimGraphId",
			"string"
		)
		if(not twoHandedAnimGraphIdIsValid) then return end
		local twoHandedAnimTrack: AnimationTrack? = loadedAnimationTracks[AssetConfig.assetIdPrefix 
			.. twoHandedAnimGraphId]
		local twoHandedAnimTrackIsValid = AssertHelper.ExpectedValAssert(
			typeof(twoHandedAnimTrack) == "Instance"
			and twoHandedAnimTrack:IsA("AnimationTrack"),
			twoHandedAnimTrack,
			"twoHandedAnimTrack",
			"AnimationTrack"
		)
		if(not twoHandedAnimTrackIsValid) then return end
		
		local toolAnimConfig = ToolConfig.toolAnimationConfigs[tool.Name]
		local toolAnimConfigIsValid = AssertHelper.ExpectedValAssert(
			type(toolAnimConfig) == "table",
			toolAnimConfig,
			"toolAnimConfig",
			"table"
		)
		if(not toolAnimConfigIsValid) then return end
		
		local attackAnimationLength = toolAnimConfig.AttackAnimationLength
		local attackAnimationLengthIsValid = AssertHelper.ExpectedValAssert(
			type(attackAnimationLength) == "number",
			attackAnimationLength,
			"attackAnimationLength",
			"number"
		)
		if(not attackAnimationLengthIsValid) then return end
		
		twoHandedAnimTrack:SetParameter("IsAttacking", true)
		twoHandedAnimTrack:SetParameter("AlternativeActionWeight", 1)
		
		task.delay(attackAnimationLength, function()
			twoHandedAnimTrack:SetParameter("IsAttacking", false)
			twoHandedAnimTrack:SetParameter("AlternativeActionWeight", 0)
		end)
	end)
	
	
	
	if(not ToolAnimationHandlers.toolAnimTroves[tool]) then
		ToolAnimationHandlers.toolAnimTroves[tool] = Trove.new()
	end
	ToolAnimationHandlers.toolAnimTroves[tool]:Add(pressedConn)
end

local activationFunctions = {
	[ToolConfig.toolTypes.TwoHandedTool.Name] = InitializeTwoHandedToolHandlers
}

function ToolAnimationHandlers.GetToolActivationHandlerFn(toolType: string)
	local toolTypeIsValid = AssertHelper.InvalidArgAssert(
		typeof(toolType) == "string",
		toolType,
		"toolType",
		"GetToolActivationHandlerFn",
		"string"
	)
	if(not toolTypeIsValid) then return end
	
	local activationFunction = activationFunctions[toolType]
	
	return activationFunction
end

return ToolAnimationHandlers
