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
const CharacterHelper = require("../../../Helpers/Character/CharacterHelper")
const DataModelHelper = require("../../../Helpers/DataModel/DataModelHelper")
const AssertHelper = require("../../../Helpers/Debug/AssertHelper")
const CuffHelper = require("../../../Helpers/Cuff/CuffHelper")

local PromptAddHandlers = {}

const guardsTeam = Teams.Guards
const subjectsTeam = Teams.Subjects

const setPlayerCuffedStateRE = ReplicatedStorage.Assets.Shared.Remotes.Events.SetPlayerCuffedState




const function AddCuffPrompt(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then return end
	
	local character = player.Character
	if not character then return end
	
	
	const humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	const prompt = Instance.new("ProximityPrompt")
	
	const localPlayer = Players.LocalPlayer
	
	
	
	prompt.Name = "CuffPrompt"
	CollectionService:AddTag(prompt, ToolPromptSystemConfig.CUFF_PROMPT_TAG)
	
	const localPlayerIsCuffingThisPlayer = CuffHelper.LocalPlayerIsCuffingPlayer(localPlayer, player)

	if localPlayerIsCuffingThisPlayer then
		prompt.ActionText = "Release Player"
	else
		prompt.ActionText = "Cuff Player"
	end
	
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = humanoidRootPart
	
	return prompt
		
end

const function RemoveCuffConstraints(localPlayer: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	
	local playerIsValid, playerInvalidityReason = playerIsValidFn(localPlayer)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end
	
	local character = localPlayer.Character
	if not character then return false end
	
	Promise.try(function()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		if not humanoidRootPart then return false end

		local cuffAlignPosition = humanoidRootPart:WaitForChild("CuffAlignPosition")
		if not cuffAlignPosition then return false end
		
		local cuffAlignOrientation = humanoidRootPart:WaitForChild("CuffAlignOrientation")
		if(not cuffAlignOrientation) then return false end
		
		cuffAlignPosition:Destroy()
		cuffAlignOrientation:Destroy()
	end)

end

const function GetPlayersForPromptAdd(localPlayer: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	local playerIsValid, playerInvalidityReason = playerIsValidFn(localPlayer)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end
	
	local team = localPlayer.Team
	if not team then return end
	
	if(team == guardsTeam) then
		return subjectsTeam:GetPlayers()
	elseif (team == subjectsTeam) then
		return guardsTeam:GetPlayers()
	else
		return nil
	end
end

const function GetTeamForPromptAdd(localPlayer: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	local playerIsValid, playerInvalidityReason = playerIsValidFn(localPlayer)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end
	
	const localPlayerTeam = localPlayer.Team
	
	if(localPlayerTeam == guardsTeam) then
		return subjectsTeam
	elseif (localPlayerTeam == subjectsTeam) then
		return guardsTeam
	else
		return nil
	end
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
	
	
	
	const localPlayer = Players.LocalPlayer
	const addPromptPlayers: {Player?}? = GetPlayersForPromptAdd(localPlayer)
	if(not addPromptPlayers) then return end
	
	const teamForPromptAdd: Team? = GetTeamForPromptAdd(localPlayer)
	if(not teamForPromptAdd) then return end
	for _, player in addPromptPlayers do
		Promise.try(function()
			const prompt: ProximityPrompt? = AddCuffPrompt(player)			
			if(not prompt) then return end
			
			const character = localPlayer.Character
			if(not character) then return end
			const humanoid = CharacterHelper.GetHumanoidFromCharacter(character)
			if(not humanoid) then return end
			
			const humanoidDiedConn = humanoid.Died:Once(function()
				prompt.Text = "Cuff Player"
			end)
			promptHandlersTrove:Add(humanoidDiedConn)
			
		end)
			:catch(function(err)
				AssertHelper.Warn(tostring(err))
				
			end)
	end
	
	const playerAddedConn = teamForPromptAdd.PlayerAdded:Connect(function(player: Player)
		AddCuffPrompt(player)
		
		const character = localPlayer.Character
		if(not character) then return end
		const humanoid = CharacterHelper.GetHumanoidFromCharacter(character)
		if(not humanoid) then return end
		const humanoidDiedConn = humanoid.Died:Once(function()
			prompt.Text = "Cuff Player"
		end)
		promptHandlersTrove:Add(humanoidDiedConn)
	end)
	const promptTriggeredConn = ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player)
		const hasCuffPromptTag = CollectionService:HasTag(prompt, ToolPromptSystemConfig.CUFF_PROMPT_TAG)
		if not hasCuffPromptTag then return end
		
		const parentCharacter = DataModelHelper.GetRootParentWithTag(prompt, CharacterConfig.CHARACTER_TAG_NAME)
		if(not parentCharacter) then return end
		
		const player = Players:GetPlayerFromCharacter(parentCharacter)
		if(not player) then return end
		
		Promise.try(function()
			const localPlayerIsCuffing: boolean = CuffHelper.LocalPlayerIsCuffing(localPlayer)
			print("player is cuffing", localPlayerIsCuffing)
			if(localPlayerIsCuffing) then
				RemoveCuffConstraints(localPlayer)
				prompt.ActionText = "Cuff Player"
				setPlayerCuffedStateRE:FireServer(player, false)
			else
				print("went hereeeeeeee")
				prompt.ActionText = "Release Player"
				setPlayerCuffedStateRE:FireServer(player, true)

			end
		end)
			:catch(function(err)
				AssertHelper.Warn(tostring(err))
			end)
		
	end)
	promptHandlersTrove:Add(playerAddedConn)
	promptHandlersTrove:Add(promptTriggeredConn)
end


PromptAddHandlers.promptAddHandlers = {
	[ToolConfig.promptTools.Handcuffs.Name] = AddPromptsForHandcuffs
}

return PromptAddHandlers
