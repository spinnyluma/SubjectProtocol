const ContextActionService = game:GetService("ContextActionService")
const CollectionService = game:GetService("CollectionService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const Modules = ReplicatedStorage.Modules

const ECS = Modules.ECS

const Systems = ECS.Systems

const ToolPromptSystemConfig = require("@self/Config")
const PromptRemoveHandlers = require("@self/PromptRemoveHandlers")
const SystemManagerModule = require("../SystemManagerModule")
const PromptAddHandlers = require("@self/PromptAddHandlers")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const Promise = require("../../Utilities/Promise")
const t = require("../../Utilities/t")

local ToolPromptSystem = {}

local function InitializePromptTool(toolPromptInstance: Tool)
	const toolPromptInstanceIsValid, toolPromptInvalidityReason = t.instanceIsA("Tool")(toolPromptInstance)
	
	if not toolPromptInstanceIsValid then 
		AssertHelper.Warn(toolPromptInvalidityReason)
		return
	end
	
	const promptAddHandler = PromptAddHandlers.promptAddHandlers[toolPromptInstance.Name]
	const promptAddHandlerIsValid, promptAddHandlerInvalidityReason = t.callback(promptAddHandler)
	if(not promptAddHandlerIsValid) then 
		AssertHelper.Warn(promptAddHandlerInvalidityReason)
		return 
	end	
	promptAddHandler(toolPromptInstance)
end

const function InitializeRemovePromptTool(toolPromptInstance: Tool)
	const toolPromptInstanceValidFn = t.instanceIsA("Tool")
	const toolPromptInstanceIsValid, toolPromptInstanceInvalidityReason = toolPromptInstanceValidFn(toolPromptInstance)
	if not toolPromptInstanceIsValid then return end
	
	local promptRemoveHandler = PromptRemoveHandlers.promptRemoveHandlers[toolPromptInstance.Name]
	local promptRemoveHandlerIsValid, promptRemoveHandlerInvalidityReason = t.callback(promptRemoveHandler)
	if(not promptRemoveHandlerIsValid) then 
		AssertHelper.Warn(promptRemoveHandlerInvalidityReason)
		return
	end
	promptRemoveHandler(toolPromptInstance)
end


local function InitializePromptTools()
	local toolPromptInstances = CollectionService:GetTagged(ToolPromptSystemConfig.SYSTEM_TAG_NAME)
	
	const localPlayer = Players.LocalPlayer
	
	
	ContextActionService.LocalToolEquipped:Connect(function(localToolEquipped: Tool)
		const hasSystemTag = CollectionService:HasTag(localToolEquipped, ToolPromptSystemConfig.SYSTEM_TAG_NAME)
		if not hasSystemTag then return end
		
		const character = localPlayer.Character
		
		Promise.try(function()
			const humanoid = character:WaitForChild("Humanoid")
			
			const humanoidState = humanoid:GetState()
			if(humanoid == Enum.HumanoidStateType.Dead) then return end			
			
			InitializePromptTool(localToolEquipped)
		end)
			:catch(function(errorMsg: any)
				AssertHelper.Warn(tostring(errorMsg))
			end)
		
	end)
	
	ContextActionService.LocalToolUnequipped:Connect(function(localToolUnequipped: Tool)
		const hasSystemTag = CollectionService:HasTag(localToolUnequipped, ToolPromptSystemConfig.SYSTEM_TAG_NAME)
		if not hasSystemTag then return end
		
		InitializeRemovePromptTool(localToolUnequipped)
	end)
end

const function CleanUpBackpackToolsHandlers(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return
	end

	local backpack = player.Backpack


	local tools = backpack:GetChildren()
	for _, tool in tools do
		if(tool:IsA("Tool")) then
			InitializeRemovePromptTool(tool)
			SystemManagerModule.RemoveComponent("PromptHandler", tool)
			SystemManagerModule.RemoveComponent("CuffState", player)
		end
	end
end

const function CleanUpCharacterToolsHandlers(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return end
	
	local character = player.Character
	if not character then return end
	
	local tools = character:QueryDescendants("Tool")
	for _, tool in tools do
		if(tool:IsA("Tool")) then
			InitializeRemovePromptTool(tool)
			SystemManagerModule.RemoveComponent("PromptHandler", tool)
			SystemManagerModule.RemoveComponent("CuffState", player)
		end
	end
end

local function InitializeOnCharRemovingHandlers()
	const localPlayer = Players.LocalPlayer
	const character = localPlayer.Character
	if(character) then
		Promise.try(function()
			const humanoid: Humanoid = character:WaitForChild("Humanoid")
			
			humanoid.Died:Once(function()
				CleanUpBackpackToolsHandlers(localPlayer)
				CleanUpCharacterToolsHandlers(localPlayer)
			end)
		end)
			:catch(function(err: any)
				AssertHelper.Warn(tostring(err))
			end)
		
		
		
	end
	
	localPlayer.CharacterAdded:Connect(function(character: Model)
		Promise.try(function()
			const humanoid = character:WaitForChild("Humanoid")
			
			humanoid.Died:Once(function()
				CleanUpBackpackToolsHandlers(localPlayer)
				CleanUpCharacterToolsHandlers(localPlayer)
			end)
		end)
			:catch(function(errorMsg: any)
				AssertHelper.Warn(tostring(errorMsg))
			end)
	end)
end

function ToolPromptSystem.Initialize()
	InitializePromptTools()
	InitializeOnCharRemovingHandlers()
end

return ToolPromptSystem
