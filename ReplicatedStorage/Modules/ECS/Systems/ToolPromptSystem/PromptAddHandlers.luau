const ProximityPromptService = game:GetService("ProximityPromptService")
const CollectionService = game:GetService("CollectionService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
const Teams = game:GetService("Teams")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Shared = Modules.Shared

const Constants = Shared.Constants

const ToolConfig = require(Constants.ToolConfig)
const Promise = require(Utilities.Promise)
const t = require(Utilities.t)

const PromptHandlerComponent = require("../../Components/PromptHandlerComponent")
const ToolPromptSystemConfig = require("./Config")
const SystemManagerModule = require("../../SystemManagerModule")
const CharacterConfig = require("../../../Shared/Constants/CharacterConfig")
const DataModelHelper = require("../../../Helpers/DataModel/DataModelHelper")
const AssertHelper = require("../../../Helpers/Debug/AssertHelper")

local PromptAddHandlers = {}

const guardsTeam = Teams.Guards

const cuffPlayerRE = ReplicatedStorage.Assets.Shared.Remotes.Events.CuffPlayer

const function AddCuffPrompt(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then return end
	
	local character = player.Character
	if not character then return end
	
	Promise.try(function()
		const humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		
		const prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CuffPrompt"
		CollectionService:AddTag(prompt, ToolPromptSystemConfig.CUFF_PROMPT_TAG)
		prompt.ActionText = "Cuff Player"
		
		prompt.HoldDuration = 0.5
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 10
		prompt.Parent = humanoidRootPart
	end)
		:catch(function(errorMsg)
			AssertHelper.Warn(tostring(errorMsg))
		end)
end


const function AddPromptsForHandcuffs(handcuffs: Tool)
	const handcuffsIsValidFn = t.instanceIsA("Tool")
	const handcuffsIsValid, handcuffsInvalidityReason = handcuffsIsValidFn(handcuffs)
	if not handcuffsIsValid then return end
	
	local promptHandlerComponent: PromptHandlerComponent.PromptHandlerComponent? = SystemManagerModule.GetComponentByEntity(
		"PromptHandler",
		handcuffs
	)
	if(not promptHandlerComponent) then
		promptHandlerComponent = SystemManagerModule.AddComponent("PromptHandler", handcuffs)
	end
	
	const promptHandlerComponentIsValid,
		promptHandlerCompInvalidityReason = t.table(promptHandlerComponent)
	if(not promptHandlerComponentIsValid) then
		AssertHelper.Warn(promptHandlerComponentIsValid)
		return
	end
	
	const promptHandlersTrove = promptHandlerComponent.handlersTrove
	const promptHandlersTroveIsValid, 
		promptHandlersTroveInvalidityReason = t.table(promptHandlersTrove)
	if(not promptHandlersTroveIsValid) then
		AssertHelper.Warn(promptHandlersTroveInvalidityReason)
		return
	end
	
	const guardsTeamPlayers = guardsTeam:GetPlayers()
	for _, guard in guardsTeamPlayers do
		AddCuffPrompt(guard)
	end
	const playerAddedConn = guardsTeam.PlayerAdded:Connect(function(player: Player)
		AddCuffPrompt(player)
	end)
	const promptTriggeredConn = ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player)
		const hasCuffPromptTag = CollectionService:HasTag(prompt, ToolPromptSystemConfig.CUFF_PROMPT_TAG)
		if not hasCuffPromptTag then return end
		
		const parentCharacter = DataModelHelper.GetRootParentWithTag(prompt, CharacterConfig.CHARACTER_TAG_NAME)
		if(not parentCharacter) then return end
		
		const player = Players:GetPlayerFromCharacter(parentCharacter)
		if(not player) then return end
		
		cuffPlayerRE:FireServer(player)
	end)
	promptHandlersTrove:Add(playerAddedConn)
	promptHandlersTrove:Add(promptTriggeredConn)
end


PromptAddHandlers.promptAddHandlers = {
	[ToolConfig.promptTools.Handcuffs.Name] = AddPromptsForHandcuffs
}

return PromptAddHandlers
