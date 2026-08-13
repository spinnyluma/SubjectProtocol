const ProximityPromptService = game:GetService("ProximityPromptService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const CombatServiceConfig = require("../../Services/Combat/CombatService/Config")
const SystemManagerModule = require("../SystemManagerModule")
const InputSystemSignals = require("./InputSystem/Signals")
const MeleeStateService = require("../../Services/Melee/MeleeStateService")
const MeleeStateConfig = require("../Components/MeleeStateComponent/Config")
const WeaponDataConfig = require("../../Shared/Constants/WeaponDataConfig")
const CharacterConfig = require("../../Shared/Constants/CharacterConfig")
const DataModelHelper = require("../../Helpers/DataModel/DataModelHelper")
const CombatService = require("../../Services/Combat/CombatService")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const InputConfig = require("../../Shared/Constants/InputConfig")
const ToolConfig = require("../../Shared/Constants/ToolConfig")
const ToolHelper = require("../../Helpers/Tool/ToolHelper")
const Promise = require("../../Utilities/Promise")
const Trove = require("../../Utilities/Trove")

local ToolActivationSystem = {}

local toolActivationParams = OverlapParams.new()

local damageHitboxRemote = ReplicatedStorage.Assets.Shared.Remotes.Events.DamageHitbox

local toolThreadTroves: {[Tool]: Trove.Trove} = {}
local toolActionConnTroves: {[Tool]: Trove.Trove} = {}
local function HitObjectInBox(
	sourceTool: Tool,
	hitboxCframe: CFrame,
	hitboxSize: Vector3,
	overlapParams: OverlapParams
)
	local sourceToolIsValid = AssertHelper.InvalidArgAssert(
		typeof(sourceTool) == "Instance"
		and sourceTool:IsA("Tool"),
		sourceTool,
		"sourceTool",
		"HitObjectInBox",
		"Tool"
	)
	if(not sourceToolIsValid) then return end
	local hitboxCframeIsValid = AssertHelper.InvalidArgAssert(
		typeof(hitboxCframe) == "CFrame",
		hitboxCframe,
		"hitboxCframe",
		"HitObjectInBox",
		"CFrame"
	)
	if(not hitboxCframeIsValid) then return end
	
	local hitboxSizeIsValid = AssertHelper.InvalidArgAssert(
		typeof(hitboxSize) == "Vector3",
		hitboxSize,
		"hitboxSize",
		"HitObjectInBox",
		"Vector3"
	)
	if(not hitboxSizeIsValid) then return end
	
	local overlapParamsIsValid = AssertHelper.InvalidArgAssert(
		typeof(overlapParams) == "OverlapParams",
		overlapParams,
		"overlapParams",
		"HitObjectInBox",
		"OverlapParams"
	)
	if(not overlapParamsIsValid) then return end
	
	
	local partsInBox = CombatService.SpawnHitbox(hitboxCframe, 
		hitboxSize,
		toolActivationParams
	)
	if(not partsInBox) then return end
	
	local objectsHit: {Model?} = {}
	
	for _, part in partsInBox do
		local character: Model? = DataModelHelper.GetRootParentWithTag(part, CharacterConfig.CHARACTER_TAG_NAME)
		local damageableObject: Model? = nil
		if(not character) then
			damageableObject = DataModelHelper.GetRootParentWithTag(part, CombatServiceConfig.DAMAGEABLE_TAG_NAME)
		end
		
		
		if(character ~= nil) then
			local characterInTableIndex = table.find(objectsHit, character)
			if(not characterInTableIndex) then
				local canBeDamaged = CombatService.IsValidDamageableTarget(character)
				
				if(not canBeDamaged) then
					continue
				end
				table.insert(objectsHit, character)
			end
		elseif(damageableObject ~= nil) then
			local damageableObjectInTableIndex = table.find(objectsHit, damageableObject)
			if(not damageableObjectInTableIndex) then
				local canBeDamaged = CombatService.IsValidDamageableTarget(damageableObject)
				if(not canBeDamaged) then
					continue
				end
				table.insert(objectsHit, damageableObject)
			end
		end
	end
	
	if(#objectsHit == 0) then return end
	
	local firstDamageableObject: Model = objectsHit[1]
	local hitboxPacket = {
		Weapon = sourceTool,
		DamageableObjectHit = firstDamageableObject
	}
	damageHitboxRemote:FireServer(hitboxPacket)
end

local function InitializeToolActivationHandlers(tool: Tool)
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
			and tool:IsA("Tool"),
		tool,
		"tool",
		"InitializeToolActivationHandlers",
		"Tool"
	)	
	if(not toolIsValid) then return end

	const toolType = ToolHelper.GetToolType(tool)
	if(not toolType) then return end

	const contextByToolType: InputContext? = InputConfig.inputContextsByToolType[toolType]
	if(not contextByToolType) then return end

	const activateToolAction: InputAction? = contextByToolType.ActivateTool
	const activateToolActionIsValid = AssertHelper.InvalidArgAssert(
		typeof(activateToolAction) == "Instance"
		and activateToolAction:IsA("InputAction"),
		activateToolAction,
		"activateToolAction",
		"InitializeToolActivationHandlers",
		"string"
	)	
	
	if(not activateToolActionIsValid) then return end

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
	
	
	
	local toolCombatConfig = ToolConfig.toolCombatConfigs[tool.Name]
	local toolCombatConfigIsValid = AssertHelper.ExpectedValAssert(
		type(toolCombatConfig) == "table",
		toolCombatConfig,
		"toolCombatConfig",
		"table"
	)
	if(not toolCombatConfigIsValid) then return end
	
	local hitboxOffset = toolCombatConfig.HitboxOffset
	local hitboxOffsetIsValid = AssertHelper.ExpectedValAssert(
		typeof(hitboxOffset) == "Vector3",
		hitboxOffset,
		"hitboxOffset",
		"Vector3"
	)	
	if(not hitboxOffsetIsValid) then return end
	
	local attackAnimationHitboxSpawnMult = toolCombatConfig.AttackAnimationHitboxSpawnMult
	local attackAnimationHitboxSpawnMultIsValid = AssertHelper.ExpectedValAssert(
		type(attackAnimationHitboxSpawnMult) == "number",
		attackAnimationHitboxSpawnMult,
		"attackAnimationHitboxSpawnMult",
		"number"
	)	
	if(not attackAnimationHitboxSpawnMultIsValid) then return end
	
	local hitboxSize = toolCombatConfig.HitboxSize
	local hitboxSizeIsValid = AssertHelper.ExpectedValAssert(
		typeof(hitboxSize) == "Vector3",
		hitboxSize,
		"hitboxSize",
		"Vector3"
	)
	if(not hitboxSizeIsValid) then return end
	
	
	
	local meleeStateComp = SystemManagerModule.GetComponentByEntity("MeleeState", tool)
	if(not meleeStateComp) then 
		meleeStateComp = SystemManagerModule.AddComponent("MeleeState", tool)
	end
	
	MeleeStateService.ChangeMeleeState(meleeStateComp, 
		MeleeStateConfig.states.Equip.Name,
		tool
	)
	
	if(not toolThreadTroves[tool]) then
		toolThreadTroves[tool] = Trove.new()
	end
	
	if(not toolActionConnTroves[tool]) then
		toolActionConnTroves[tool] = Trove.new()
	end
	local toolThreadTrove = toolThreadTroves[tool]
	local troveIsValid = AssertHelper.ExpectedValAssert(
		type(toolThreadTrove) == "table",
		toolThreadTrove,
		"trove",
		"Trove"
	)
	if(not troveIsValid) then return end
	
	local toolActionConnTrove = toolActionConnTroves[tool]
	local toolActionConnTroveIsValid = AssertHelper.ExpectedValAssert(
		type(toolActionConnTrove) == "table",
		toolActionConnTrove,
		"toolActionConnTrove",
		"Trove"
	)
	if(not toolActionConnTroveIsValid) then return end
	
	InputSystemSignals.InputContextEnabledChanged:Fire(contextByToolType, true)
	local toolAction = activateToolAction.Pressed:Connect(function()
		local meleeState = meleeStateComp.State
		if(meleeState == MeleeStateConfig.states.Attacking.Name) then return end
		local player = Players.LocalPlayer
		local character = player.Character
		if(not character) then return end
		
		local meleeStateComp = SystemManagerModule.GetComponentByEntity("MeleeState", tool)

		local meleeStateCompIsValid = AssertHelper.ExpectedValAssert(
			type(meleeStateComp) == "table",
			meleeStateComp,
			"meleeStateComp",
			"table"
		)
		if(not meleeStateCompIsValid) then return end
		
		const alternativeActionPause = tool:GetAttribute(ToolConfig.ALTERNATIVE_ACTION_PAUSE_ATTR_NAME)
		if(not alternativeActionPause) then return end
		MeleeStateService.ChangeMeleeState(meleeStateComp, 
			MeleeStateConfig.states.Attacking.Name,
			tool
		)
		
		local fullLengthThread = task.delay(attackAnimationLength + alternativeActionPause, function()
			MeleeStateService.ChangeMeleeState(meleeStateComp, 
				MeleeStateConfig.states.Equip.Name,
				tool
			)
			toolThreadTrove:Clean()
		end)
		local attackThread = task.delay(attackAnimationLength * attackAnimationHitboxSpawnMult, function()
			local hrp: BasePart? = character:FindFirstChild("HumanoidRootPart")
			if(not hrp) then return end

			local hitboxPosition = hrp.CFrame:PointToWorldSpace(hitboxOffset)
			local hitboxCframe = CFrame.new(hitboxPosition)
			local orientX, orientY, orientZ = hrp.CFrame:ToOrientation()
			hitboxCframe = hitboxCframe * CFrame.Angles(
				orientX,
				orientY,
				orientZ
			)
			
			local part = Instance.new("Part")
			part.Transparency = 0.5
			part.Size = hitboxSize
			part.CFrame = hitboxCframe
			part.Anchored = true
			part.CanCollide = false
			part.BrickColor = BrickColor.new("Bright red")
			part.Parent = workspace
			game.Debris:AddItem(part, 1)
			toolActivationParams.ExcludeInstances = {character}
			HitObjectInBox(
				tool,
				hitboxCframe,
				hitboxSize,
				toolActivationParams
			)
			
		end)
		toolThreadTrove:Add(attackThread)
		toolThreadTrove:Add(fullLengthThread)

	end)
	toolActionConnTrove:Add(toolAction)
end

local function AddMeleeStateCompFromBackpack(localPlayer: Player)
	local localPlayerIsValid = AssertHelper.InvalidArgAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"ToolActivationSystem.InitializeMeleeStateComponents",
		"Player"
	)
	if(not localPlayerIsValid) then return end
	const backpack = localPlayer.Backpack

	const tools = backpack:GetChildren()
	for _, tool in tools do
		if(tool:IsA("Tool")) then
			const toolIsActivatable = ToolConfig.activatableTools[tool.Name]
			if(not toolIsActivatable) then continue end
			MeleeStateService.AddMeleeStateComponent(tool)

		end
	end
end

local function InitializeMeleeStateComponentsHandler(localPlayer: Player)
	const localPlayerIsValid = AssertHelper.InvalidArgAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"ToolActivationSystem.InitializeMeleeStateComponents",
		"Player"
	)
	if(not localPlayerIsValid) then return end
	AddMeleeStateCompFromBackpack(localPlayer)
	const backpack = localPlayer.Backpack
	backpack.ChildAdded:Connect(function(child: Instance)
		local meleeCompExists = SystemManagerModule.DoesEntityComponentExist("MeleeState", child)
		if(meleeCompExists) then return end
		local character = localPlayer.Character
		if(not character) then return end
		Promise.try(function()
			local humanoid = character:WaitForChild("Humanoid")
			if(not humanoid) then return end
			local state = humanoid:GetState()
			if(child:IsA("Tool")
				and state ~= Enum.HumanoidStateType.Dead) then
				local toolIsActivatable = ToolConfig.activatableTools[child.Name]
				if(not toolIsActivatable) then return end
				MeleeStateService.AddMeleeStateComponent(child)
			end
		end)
		
	end)
end




local function CleanUpToolTrove(tool: Tool)
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
			and tool:IsA("Tool"),
		tool,
		"tool",
		"ToolActivationSystem.CleanUpToolHandlers",
		"Tool"
	)
	if(not toolIsValid) then return end
	const toolIsActivatable = ToolConfig.activatableTools[tool.Name]
	if(not toolIsActivatable) then return end
	local trove = toolThreadTroves[tool]
	if(trove) then
		trove:Clean()
	end
	
	local toolActionConnTrove = toolActionConnTroves[tool]
	if(toolActionConnTrove) then
		toolActionConnTrove:Clean()
	end
	
	
	toolThreadTroves[tool] = nil
	toolActionConnTroves[tool] = nil
	

end

local function CleanUpTool(tool: Tool)
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
			and tool:IsA("Tool"),
		tool,
		"tool",
		"ToolActivationSystem.CleanUpTool",
		"Tool"
	)
	if(not toolIsValid) then return end
	

	const toolIsActivatable = ToolConfig.activatableTools[tool.Name]
	if(not toolIsActivatable) then return end

	local componentExists = SystemManagerModule.DoesEntityComponentExist("MeleeState", tool)
	if(componentExists) then
		MeleeStateService.RemoveMeleeStateComponent(tool)	
	end
	CleanUpToolTrove(tool)
end

local function CleanUpOnToolUnequipped(child: Instance)
	if(child:IsA("Tool")) then
		local toolType = ToolHelper.GetToolType(child)
		if(not toolType) then return end
		local contextByToolType = InputConfig.inputContextsByToolType[toolType]
		if(not contextByToolType) then return end
		InputSystemSignals.InputContextEnabledChanged:Fire(contextByToolType, false)
		
		
		
		
		
		MeleeStateService.RemoveMeleeStateComponent(child)
		CleanUpToolTrove(child)
	end
end

function ToolActivationSystem.Initialize()
	const localPlayer = Players.LocalPlayer
	const localPlayerIsValid = AssertHelper.ExpectedValAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"ToolActivationSystem.Initialize",
		"Player"
	)
	if(not localPlayerIsValid) then return end
	local character = localPlayer.Character
	
	if(character) then
		character.ChildAdded:Connect(function(child: Instance)
			Promise.try(function()
				local humanoid: Humanoid = character:WaitForChild("Humanoid")
				local humanoidStateType = humanoid:GetState()
				
				if(child:IsA("Tool")
					and humanoidStateType ~= Enum.HumanoidStateType.Dead) then
					InitializeToolActivationHandlers(child)
				end
			end)
		end)
		character.ChildRemoved:Connect(CleanUpOnToolUnequipped)
		
		Promise.try(function()
			const humanoid = character:WaitForChild("Humanoid")
			const humanoidIsValid = AssertHelper.ExpectedValAssert(
				typeof(humanoid) == "Instance"
					and humanoid:IsA("Humanoid"),
				humanoid,
				"humanoid",
				"Humanoid"
			)
			if(not humanoidIsValid) then return end
			humanoid.Died:Connect(function()
				local backpack = localPlayer.Backpack
				local tools = backpack:GetChildren()
				for _, tool in tools do
					if(tool:IsA("Tool")) then
						CleanUpTool(tool)
					end
				end
				
				local characterTools = character:QueryDescendants("Tool")
				for _, tool in characterTools do
					if(tool:IsA("Tool")) then
						CleanUpTool(tool)
					end
				end
			end)
		end)
			:catch(function(errorMsg)
				AssertHelper.Warn(tostring(errorMsg))
			end)
	end
		
	
	localPlayer.CharacterAdded:Connect(function(character: Model)
		AddMeleeStateCompFromBackpack(localPlayer)
		
		character.ChildAdded:Connect(function(child: Instance)
			
			local humanoid: Humanoid = character:WaitForChild("Humanoid")
			local humanoidStateType = humanoid:GetState()
			if(child:IsA("Tool")
				and humanoidStateType ~= Enum.HumanoidStateType.Dead) then
				InitializeToolActivationHandlers(child)
			end
		end)
		
		character.ChildRemoved:Connect(CleanUpOnToolUnequipped)
		
		Promise.try(function()
			const humanoid = character:WaitForChild("Humanoid")
			const humanoidIsValid = AssertHelper.ExpectedValAssert(
				typeof(humanoid) == "Instance"
					and humanoid:IsA("Humanoid"),
				humanoid,
				"humanoid",
				"Humanoid"
			)
			if(not humanoidIsValid) then return end
			humanoid.Died:Connect(function()
				local backpack = localPlayer.Backpack
				local tools = backpack:GetChildren()
				for _, tool in tools do
					if(tool:IsA("Tool")) then
						CleanUpTool(tool)
					end
				end
			end)
		end)
			:catch(function(errorMsg)
				AssertHelper.Warn(tostring(errorMsg))
			end)
		
	end)
	
end

function ToolActivationSystem.PostInitialize()
	const localPlayer = Players.LocalPlayer
	const localPlayerIsValid = AssertHelper.ExpectedValAssert(
		typeof(localPlayer) == "Instance"
			and localPlayer:IsA("Player"),
		localPlayer,
		"localPlayer",
		"ToolActivationSystem.Initialize",
		"Player"
	)
	if(not localPlayerIsValid) then return end
	
	InitializeMeleeStateComponentsHandler(localPlayer)

end
return ToolActivationSystem
