const Players = game:GetService("Players")
const Teams = game:GetService("Teams")

const PromptHandlerComponent = require("../../Components/PromptHandlerComponent")
const SystemManagerModule = require("../../SystemManagerModule")
const AssertHelper = require("../../../Helpers/Debug/AssertHelper")
const ToolConfig = require("../../../Shared/Constants/ToolConfig")
const Promise = require("../../../Utilities/Promise")
const t = require("../../../Utilities/t")

local PromptRemoveHandlers = {}

const guardsTeam = Teams.Guards

const function RemoveCuffPrompt(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return
	end
	
	const character = player.Character
	Promise.try(function()
		const humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
		const humanoidRootPartIsValidFn = t.instanceIsA("BasePart")
		const humanoidRootPartIsValid, humanoidRootPartInvalidityReason = humanoidRootPartIsValidFn(humanoidRootPart)
		if not humanoidRootPartIsValid then return end
		const cuffPrompt = humanoidRootPart:FindFirstChild("CuffPrompt")
		const cuffPromptIsValidFn = t.instanceIsA("ProximityPrompt")
		const cuffPromptIsValid, cuffPromptInvalidityReason = cuffPromptIsValidFn(cuffPrompt)
		if not cuffPromptIsValid then return end
		
		cuffPrompt:Destroy()
	end)
		:catch(function(errorMsg)
			AssertHelper.Warn(tostring(errorMsg))
		end)
end

local function RemovePromptsForHandcuffs(handcuffs: Tool)
	const handcuffsIsValid = t.instanceIsA("Tool")
	if not handcuffsIsValid then 
		AssertHelper.Warn(handcuffs)
		return 
	end
	for _, guard in guardsTeam:GetPlayers() do
		RemoveCuffPrompt(guard)
	end
	
	const promptHandlerCompExists = SystemManagerModule.DoesEntityComponentExist(
		"PromptHandler",
		handcuffs
	)
	if not promptHandlerCompExists then return end
	
	const promptHandlerComp: PromptHandlerComponent.PromptHandlerComponent = SystemManagerModule.GetComponentByEntity("PromptHandler", handcuffs)
	const promptHandlerCompIsValid, promptHandlerCompInvalidityReason = t.table(promptHandlerComp)
	if not promptHandlerCompIsValid then 
		AssertHelper.Warn(promptHandlerCompInvalidityReason)
		return 
	end
	
	const handlersTrove = promptHandlerComp.handlersTrove
	const handlersTroveIsValid, handlersTroveInvalidityReason = t.table(handlersTrove)
	if not handlersTroveIsValid then 
		AssertHelper.Warn(handlersTroveInvalidityReason)
		return 
	end
	
	for player, trove in handlersTrove do
		trove:Clean()
	end
	
	const onDeathCleanupHandlersTroves = promptHandlerComp.onDeathCleanupHandlersTroves
	const onDeathCleanupHandlersTrovesIsValid, onDeathCleanupHandlersTrovesInvalidityReason = t.table(onDeathCleanupHandlersTroves)
	if not onDeathCleanupHandlersTrovesIsValid then 
		AssertHelper.Warn(onDeathCleanupHandlersTrovesInvalidityReason)
		return 
	end
	
	for player, trove in onDeathCleanupHandlersTroves do
		trove:Clean()
	end
	
	const globalPromptTrove = promptHandlerComp.globalPromptTrove
	const globalPromptTroveIsValid, globalPromptTroveInvalidityReason = t.table(globalPromptTrove)
	if not globalPromptTroveIsValid then 
		AssertHelper.Warn(globalPromptTroveInvalidityReason)
		return 
	end
	
	globalPromptTrove:Clean()
	
end

PromptRemoveHandlers.promptRemoveHandlers = {
	[ToolConfig.promptTools.Handcuffs.Name] = RemovePromptsForHandcuffs
}

return PromptRemoveHandlers
