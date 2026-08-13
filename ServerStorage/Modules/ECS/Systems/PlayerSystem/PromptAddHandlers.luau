const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Teams = game:GetService("Teams")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Shared = Modules.Shared

const Constants = Shared.Constants

const ToolConfig = require(Constants.ToolConfig)
const Promise = require(Utilities.Promise)
const t = require(Utilities.t)

local PromptAddHandlers = {}

const guardsTeam = Teams.Guards


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
		prompt.ActionText = "Cuff Player"
		
		prompt.HoldDuration = 0.5
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 10
		prompt.Parent = humanoidRootPart

	end)
end

const function AddPromptsForHandcuffs(handcuffs: Tool)
	const handcuffsIsValidFn = t.instanceIsA("Tool")
	const handcuffsIsValid, handcuffsInvalidityReason = handcuffsIsValidFn(handcuffs)
	if not handcuffsIsValid then return end
	
	const guardsTeamPlayers = guardsTeam:GetPlayers()
	for _, guard in guardsTeamPlayers do
		
	end
end


PromptAddHandlers.promptAddHandlers = {
	[ToolConfig.promptAddTools.Handcuffs.Name] = AddPromptsForHandcuffs
}

return PromptAddHandlers
