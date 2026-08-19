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

const ClientCuffSystemConfig = require("../ClientCuffSystem/Config")
const PromptHandlerComponent = require("../../Components/PromptHandlerComponent")
const ToolPromptSystemConfig = require("./Config")
const SystemManagerModule = require("../../SystemManagerModule")
const CuffStateComponent = require("../../Components/CuffStateComponent")
const ClientCuffService = require("../../../Services/Cuff/ClientCuffService")
const CharacterConfig = require("../../../Shared/Constants/CharacterConfig")
const CharacterHelper = require("../../../Helpers/Character/CharacterHelper")
const DataModelHelper = require("../../../Helpers/DataModel/DataModelHelper")
const AssertHelper = require("../../../Helpers/Debug/AssertHelper")
const CuffHelper = require("../../../Helpers/Cuff/CuffHelper")
const ClientCuffSystemSignals = require("../ClientCuffSystem/Signals")
const Trove = require("../../../Utilities/Trove")

local PromptAddHandlers = {}

const guardsTeam = Teams.Guards
const subjectsTeam = Teams.Subjects

const setPlayerCuffedStateRE = ReplicatedStorage.Assets.Shared.Remotes.Events.SetPlayerCuffedState

const function AddCuffPrompt(player: Player, handcuffs: Tool)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return 
	end
	
	const handcuffsIsValidFn = t.instanceIsA("Tool")
	const handcuffsIsValid, handcuffsInvalidityReason = handcuffsIsValidFn(handcuffs)
	if(not handcuffsIsValid) then
		AssertHelper.Warn(handcuffsInvalidityReason)
		return
	end
	
	local character = player.Character
	if not character then return end
	
	
	const humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	const humanoid: Humanoid = character:WaitForChild("Humanoid")
	

	const promptHandlerComp = SystemManagerModule.GetComponentByEntity("PromptHandler", handcuffs)
	if not promptHandlerComp then return end
	
	const playerPromptHandlerTrove = promptHandlerComp.handlersTrove
	const playerPromptHandlerTroveIsValid, playerPromptHandlerTroveInvalidityReason = t.table(playerPromptHandlerTrove)
	
	if not playerPromptHandlerTroveIsValid then
		AssertHelper.Warn(playerPromptHandlerTroveInvalidityReason)
		return 
	end
	
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
	
	const localPlayer = Players.LocalPlayer
	if(not localPlayer) then return end
	local cuffStateComponent: CuffStateComponent.CuffStateComponent? = SystemManagerModule.GetComponentByEntity("CuffState", localPlayer)
	if(not cuffStateComponent) then
		cuffStateComponent = SystemManagerModule.AddComponent("CuffState", localPlayer)
	end
	
	
	const promptHandlerComponentIsValid,
		promptHandlerCompInvalidityReason = t.table(promptHandlerComponent)
	if(not promptHandlerComponentIsValid) then
		AssertHelper.Warn(promptHandlerComponentIsValid)
		return
	end
	
	const cuffStateCompIsValid, cuffStateCompInvalidityReason = t.table(cuffStateComponent)
	if(not cuffStateCompIsValid) then
		AssertHelper.Warn(cuffStateCompInvalidityReason)
		return end
	
	const promptHandlersTroves = promptHandlerComponent.handlersTrove
	const promptHandlersTrovesIsValid, 
		promptHandlersTrovesInvalidityReason = t.table(promptHandlersTroves)
	if(not promptHandlersTrovesIsValid) then
		AssertHelper.Warn(promptHandlersTrovesInvalidityReason)
		return
	end
	
	const onDeathCleanupHandlersTroves = promptHandlerComponent.onDeathCleanupHandlersTroves
	const onDeathCleanupHandlersTrovesIsValid, onDeathCleanupHandlersTrovesInvalidityReason = t.table(onDeathCleanupHandlersTroves)
	if(not onDeathCleanupHandlersTrovesIsValid) then
		AssertHelper.Warn(onDeathCleanupHandlersTrovesInvalidityReason)
		return
	end
	
	const globalPromptTrove = promptHandlerComponent.globalPromptTrove
	const globalPromptTroveIsValid, globalPromptTroveInvalidityReason = t.table(globalPromptTrove)
	if(not globalPromptTroveIsValid) then
		AssertHelper.Warn(globalPromptTroveInvalidityReason)
		return end
	
	const localPlayer = Players.LocalPlayer
	const addPromptPlayers: {Player?}? = GetPlayersForPromptAdd(localPlayer)

	if(not addPromptPlayers) then return end
	
	const teamForPromptAdd: Team? = GetTeamForPromptAdd(localPlayer)
	if(not teamForPromptAdd) then return end
	for _, player in addPromptPlayers do
		if(not promptHandlersTroves[player]) then
			promptHandlersTroves[player] = Trove.new()
		end
		
		const promptHandlersTrove = promptHandlersTroves[player]
		const promptHandlersTroveIsValid, promptHandlersTroveInvalidityReason = t.table(promptHandlersTrove)
		if(not promptHandlersTroveIsValid) then
			AssertHelper.Warn(promptHandlersTroveInvalidityReason)
			continue			
		end
		const promptAddOnCharAddedConn = player.CharacterAdded:Connect(function(character: Model)
			Promise.try(function()
				const prompt: ProximityPrompt? = AddCuffPrompt(player, handcuffs)			
			end)
				:catch(function(err)
					AssertHelper.Warn(tostring(err))
				end)
		end)
		Promise.try(function()
			const localCharacter = localPlayer.Character
			if(not localCharacter) then return end

			const targetCharacter = player.Character
			if(not targetCharacter) then return end


			local targetHumanoid = targetCharacter:WaitForChild("Humanoid")
			if(not targetHumanoid) then return end

			const handlersTroveIsValid, handlersTroveInvalidityReason = t.table(promptHandlersTrove)
			if(not handlersTroveIsValid) then
				AssertHelper.Warn(handlersTroveInvalidityReason)
				return
			end
			const prompt: ProximityPrompt? = AddCuffPrompt(player, handcuffs)			
			if(not prompt) then return end
			
			if(not onDeathCleanupHandlersTroves[player]) then
				onDeathCleanupHandlersTroves[player] = Trove.new()
			end
			const targetHumanoidDiedConn = targetHumanoid.Died:Once(function()
				ClientCuffService.RemoveCuffConstraints(localPlayer)
								
				ClientCuffService.SetCuffState(ClientCuffSystemConfig.cuffStates.Idle.Name)
				const targetPlayerTrove = onDeathCleanupHandlersTroves[player]
				const targetPlayerTroveIsValid, targetPlayerTroveInvalidityReason = t.table(targetPlayerTrove)
				if(not targetPlayerTroveIsValid) then
					AssertHelper.Warn(targetPlayerTroveInvalidityReason)
					return 
				end
				targetPlayerTrove:Clean()
			end)
			const targetPlayerTrove = onDeathCleanupHandlersTroves[player]
			targetPlayerTrove:Add(targetHumanoidDiedConn)
		end)
			:catch(function(err)
				AssertHelper.Warn(tostring(err))
			end)
		
		promptHandlersTrove:Add(promptAddOnCharAddedConn)
	end
	
	const playerAddedConn = teamForPromptAdd.PlayerAdded:Connect(function(player: Player)
		if(not promptHandlersTroves[player]) then
			promptHandlersTroves[player] = Trove.new()
		end

		const promptHandlersTrove = promptHandlersTroves[player]
		const promptHandlersTroveIsValid, promptHandlersTroveInvalidityReason = t.table(promptHandlersTrove)
		if(not promptHandlersTroveIsValid) then
			AssertHelper.Warn(promptHandlersTroveInvalidityReason)
			return			
		end
		AddCuffPrompt(player, handcuffs)
		
		const promptAddOnCharAddedConn = player.CharacterAdded:Connect(function(character: Model)
			Promise.try(function()
				const prompt: ProximityPrompt? = AddCuffPrompt(player, handcuffs)			
				const targetCharacterHumanoid: Humanoid = character:WaitForChild("Humanoid")
				if(not onDeathCleanupHandlersTroves[player]) then
					onDeathCleanupHandlersTroves[player] = Trove.new()
				end
				const targetHumanoidDiedConn = targetCharacterHumanoid.Died:Once(function()
					ClientCuffService.RemoveCuffConstraints(localPlayer)
					
					ClientCuffService.SetCuffState(ClientCuffSystemConfig.cuffStates.Idle.Name)
					const targetPlayerTrove = onDeathCleanupHandlersTroves[player]
					const targetPlayerTroveIsValid, targetPlayerTroveInvalidityReason = t.table(targetPlayerTrove)
					if(not targetPlayerTroveIsValid) then
						AssertHelper.Warn(targetPlayerTroveInvalidityReason)
						return 
					end
					targetPlayerTrove:Clean()
					
				end)
				const targetPlayerTrove = onDeathCleanupHandlersTroves[player]
				targetPlayerTrove:Add(targetHumanoidDiedConn)
			end)
				:catch(function(err)
					AssertHelper.Warn(tostring(err))
				end)
		end)		
		promptHandlersTrove:Add(promptAddOnCharAddedConn)
	end)
	const promptTriggeredConn = ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player)
		const hasCuffPromptTag = CollectionService:HasTag(prompt, ToolPromptSystemConfig.CUFF_PROMPT_TAG)
		if not hasCuffPromptTag then return end
		
		const parentCharacter = DataModelHelper.GetRootParentWithTag(prompt, CharacterConfig.CHARACTER_TAG_NAME)
		if(not parentCharacter) then return end
		
		const characterIsDead = CharacterHelper.IsCharacterDead(parentCharacter)
		if(characterIsDead) then return end
		const player = Players:GetPlayerFromCharacter(parentCharacter)
		if(not player) then return end
		
		
		
		Promise.try(function()
			const localPlayerIsCuffing: boolean = CuffHelper.LocalPlayerIsCuffing(localPlayer)
			const localPlayerIsCuffingTargetCharacter: boolean = CuffHelper.LocalPlayerIsCuffingPlayerByAttachments(localPlayer, player)
			if(localPlayerIsCuffing and localPlayerIsCuffingTargetCharacter) then
				ClientCuffService.RemoveCuffConstraints(localPlayer)
				-- Remove transparent arrow attachments
				for _, descendant in localPlayer.Character:GetDescendants() do
					if descendant.Name == "TransparentImprisonmentBeam" then
						descendant:Destroy()
					end
				end
				ClientCuffService.SetCuffState(ClientCuffSystemConfig.cuffStates.Idle.Name)
				prompt.ActionText = "Cuff Player"
				setPlayerCuffedStateRE:FireServer(player, false)
			elseif(not localPlayerIsCuffing and not localPlayerIsCuffingTargetCharacter) then
				
				prompt.ActionText = "Release Player"
				setPlayerCuffedStateRE:FireServer(player, true)

			end
		end)
			:catch(function(err)
				AssertHelper.Warn(tostring(err))
			end)
	
	end)
	
	Promise.try(function()
		const localCharacter = localPlayer.Character
		if(not localCharacter) then return end
		const localHumanoid = localCharacter:WaitForChild("Humanoid")
		localHumanoid.Died:Once(function()
			ClientCuffService.RemoveCuffConstraints(localPlayer)
			ClientCuffService.SetCuffState(ClientCuffSystemConfig.cuffStates.Idle.Name)
		end)		
	end)
		:catch(function(err: any)
			AssertHelper.Warn(tostring(err))
		end)
	
	
	const playerRemovingConn = Players.PlayerRemoving:Connect(function(player: Player)
		const promptHandlerComp: PromptHandlerComponent.PromptHandlerComponent = SystemManagerModule.GetComponentByEntity("PromptHandler", handcuffs)
		if(not promptHandlerComp) then return end
		
		
		local handlersTroves = promptHandlerComp.handlersTrove
		local handlersTrovesIsValid, handlersTrovesInvalidityReason = t.table(handlersTroves)
		if(not handlersTrovesIsValid) then
			AssertHelper.Warn(handlersTrovesInvalidityReason)
			return
		end
		
		local handlersTrove = promptHandlerComp[player]
		if(handlersTrove) then
			handlersTrove:Clean()
			handlersTroves[player] = nil
		end
		
		const onDeathCleanupTroves = promptHandlerComp.onDeathCleanupHandlersTroves
		local onDeathCleanupHandlersTrovesIsValid, onDeathCleanupHandlersTrovesInvalidityReason = t.table(onDeathCleanupHandlersTroves)
		if(not onDeathCleanupHandlersTrovesIsValid) then
			AssertHelper.Warn(onDeathCleanupHandlersTrovesInvalidityReason)
			return
		end
		
		local onDeathCleanupHandlersTrove = onDeathCleanupHandlersTroves[player]
		if(onDeathCleanupHandlersTrove) then
			onDeathCleanupHandlersTrove:Clean()
			onDeathCleanupHandlersTroves[player] = nil
		end
	end)
	globalPromptTrove:Add(playerAddedConn)
	globalPromptTrove:Add(promptTriggeredConn)
end


PromptAddHandlers.promptAddHandlers = {
	[ToolConfig.promptTools.Handcuffs.Name] = AddPromptsForHandcuffs
}

return PromptAddHandlers
