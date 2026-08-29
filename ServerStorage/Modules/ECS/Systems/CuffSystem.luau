const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")
const Players = game:GetService("Players")
const Teams = game:GetService("Teams")

const setPlayerCuffedStateRE = ReplicatedStorage.Assets.Shared.Remotes.Events.SetPlayerCuffedState
const Modules = ReplicatedStorage.Modules

const Framework = Modules.Framework
const Utilities = Modules.Utilities
const Helpers = Modules.Helpers
const Shared = Modules.Shared
const ECS = Modules.ECS

const Cuff = Helpers.Cuff

const Constants = Shared.Constants
const Packages = Shared.Packages

const ReplicaShared = Packages.ReplicaShared

const SystemManagerModule = require(ECS.SystemManagerModule)
const ModuleLoader = require(Framework.ModuleLoader)
const CuffHelper = require(ServerStorage.Modules.Helpers.Cuff.CuffHelper)
const ModeConfig = require(Constants.ModeConfig)
const Trove = require(Utilities.Trove)
const Maid = require(ReplicaShared.Maid)

const FacilityModeSystemSignals = require("./FacilityModeSystem/Signals")
const HostilitySystemSignals = require("./HostilitySystem/Signals")
const CuffService = require("../../Services/Cuff/CuffService")
const ToolService = require("../../Services/Tool/ToolService")

const Character = Helpers.Character

const Debug = Helpers.Debug
const Tool = Helpers.Tool

const Constants = Shared.Constants

const CharacterHelper = require(Character.CharacterHelper)
const AssertHelper = require(Debug.AssertHelper)
const ToolConfig = require(Constants.ToolConfig)
const ToolHelper = require(Tool.ToolHelper)
const t = require(Utilities.t)

const handcuffsTool = ServerStorage.Assets.Tools.Cuffs.Handcuffs

local CuffSystem = {}

const ACCEPTABLE_CUFFING_DISTANCE = 20

const setupCuffConstraintRE = ReplicatedStorage.Assets.Shared.Remotes.Events.SetupCuffConstraint

const subjectsTeam = Teams.Subjects

const involvedCuffedPlayersRemoving: {[Player]: Trove.Trove} = {}

local subjectsTeamGiveHandcuffsConn: RBXScriptConnection? = nil



local function ValidatePlayerCuffing(playerCuffing: Player, playerBeingCuffed: Player)
	const playerValidFn = t.instanceIsA("Player")
	const playerCuffingIsValid, playerCuffingInvalidityReason = playerValidFn(playerCuffing)
	if not playerCuffingIsValid then 
		AssertHelper.Warn(playerCuffingInvalidityReason)
		return false
	end
	
	const playerBeingCuffedIsValid, playerBeingCuffedInvalidityReason = playerValidFn(playerBeingCuffed)
	if not playerBeingCuffedIsValid then 
		AssertHelper.Warn(playerBeingCuffedInvalidityReason)
		return false
	end
	
	if playerCuffing == playerBeingCuffed then return end
	local character1 = playerCuffing.Character
	if(not character1) then return false end
	
	local character2 = playerBeingCuffed.Character
	if(not character2) then return false end
	
	local character2Head = character2.Head
	if(not character2Head) then return false end
	
	const magnitudeBetweenPlayers = playerCuffing:DistanceFromCharacter(character2Head.Position)
	if magnitudeBetweenPlayers > ACCEPTABLE_CUFFING_DISTANCE then return false end
	
	const playerCuffingHasCuffs = ToolHelper.PlayerHasTool(playerCuffing, ToolConfig.promptTools.Handcuffs.Name)
	if not playerCuffingHasCuffs then return false end
	
	const playerCuffingDead = CharacterHelper.IsCharacterDead(character1)
	if playerCuffingDead then return false end
	
	const playerBeingCuffedDead = CharacterHelper.IsCharacterDead(character2)
	if playerBeingCuffedDead then return false end
	
	return true
end

const function SetUpCuffAlignOrientationForCuffer(cuffer: Player, playerToCuff: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const cufferIsValid, cufferInvalidityReason = playerIsValidFn(cuffer)
	if not cufferIsValid then 
		AssertHelper.Warn(cufferInvalidityReason)
		return false
	end
	
	const playerToCuffCharacter = playerToCuff.Character
	if(not playerToCuffCharacter) then return false end

	const playerToCuffHrp: BasePart? = playerToCuffCharacter.HumanoidRootPart
	if(not playerToCuffHrp) then return end

	playerToCuffHrp:SetNetworkOwner(cuffer)
	
	setupCuffConstraintRE:FireClient(cuffer, playerToCuff, "AlignOrientation")
	return true
end

const function SetUpCuffAlignPositionForCuffer(cuffer: Player, playerToCuff: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const cufferIsValid, cufferInvalidityReason = playerIsValidFn(cuffer)
	if not cufferIsValid then 
		AssertHelper.Warn(cufferInvalidityReason)
		return false
	end
	const playerToCuffIsValid, playerToCuffInvalidityReason = playerIsValidFn(playerToCuff)
	if(not playerToCuffIsValid) then
		AssertHelper.Warn(playerToCuffInvalidityReason)
		return false
	end
	
	
	const playerToCuffCharacter = playerToCuff.Character
	if(not playerToCuffCharacter) then return false end
	
	const playerToCuffHrp: BasePart? = playerToCuffCharacter.HumanoidRootPart
	if(not playerToCuffHrp) then return end


	
	playerToCuffHrp:SetNetworkOwner(cuffer)
	
	
	setupCuffConstraintRE:FireClient(cuffer, playerToCuff, "AlignPosition")
	return true
end

const function SetUpCuffingAlignPosition(cuffAttachment: Attachment, characterToCuffRootAttachment: Attachment)
	const attachmentIsValidFn = t.instanceIsA("Attachment")
	const attachmentIsValid, attachmentInvalidityReason = attachmentIsValidFn(cuffAttachment)
	if not attachmentIsValid then 
		AssertHelper.Warn(attachmentInvalidityReason)
		return false
	end
	
	const characterToCuffRootAttachmentIsValidFn = t.instanceIsA("Attachment")
	const characterToCuffRootAttachmentIsValid, characterToCuffRootAttachmentInvalidityReason = characterToCuffRootAttachmentIsValidFn(characterToCuffRootAttachment)
	if not characterToCuffRootAttachmentIsValid then 
		AssertHelper.Warn(characterToCuffRootAttachmentInvalidityReason)
		return false
	end
	
	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Attachment0 = characterToCuffRootAttachment
	alignPosition.Attachment1 = cuffAttachment
	alignPosition.MaxForce = 50_000
	alignPosition.Responsiveness = 10_000
	alignPosition.Name = "CuffAlignPosition"
	alignPosition.Parent = characterToCuffRootAttachment.Parent
	
end

const function CuffPlayerToPlayer(playerToCuffTo: Player, playerToCuff: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerToCuffToIsValid, playerToCuffToInvalidityReason = playerIsValidFn(playerToCuffTo)
	if not playerToCuffToIsValid then 
		AssertHelper.Warn(playerToCuffToInvalidityReason)
		return false
	end
	
	const playerToCuffIsValid, playerToCuffInvalidityReason = playerIsValidFn(playerToCuff)
	if not playerToCuffIsValid then 
		AssertHelper.Warn(playerToCuffInvalidityReason)
		return false
	end
	
	if playerToCuffTo == playerToCuff then return false end
	local character1 = playerToCuffTo.Character
	if(not character1) then return false end
	
	local character2 = playerToCuff.Character
	if(not character2) then return false end
	
	const hrpCharacter1 = character1.HumanoidRootPart
	if(not hrpCharacter1) then return false end
	
	local hrpCharacter2 = character2.HumanoidRootPart
	if(not hrpCharacter2) then return false end
	
	const cuffAttachment = hrpCharacter1.CuffAttachment
	
	const attachmentIsValidFn = t.instanceIsA("Attachment")
	const attachmentIsValid, attachmentInvalidityReason = attachmentIsValidFn(cuffAttachment)
	if not attachmentIsValid then 
		AssertHelper.Warn(attachmentInvalidityReason)
		return false
	end
	
	const playerToCuffRootAttachment = hrpCharacter2.RootAttachment
	const playerToCuffRootAttachmentIsValid, playerToCuffRootAttachmentInvalidityReason = attachmentIsValidFn(playerToCuffRootAttachment)
	if(not playerToCuffRootAttachmentIsValid) then
		AssertHelper.Warn(playerToCuffToInvalidityReason)
		return false
	end
	
	ToolService.StorePlayerTools(playerToCuff)
	const setupCuffAlignPosition = SetUpCuffAlignPositionForCuffer(playerToCuffTo, playerToCuff)
	if(not setupCuffAlignPosition) then return end
	const setupCuffAlignOrientation = SetUpCuffAlignOrientationForCuffer(playerToCuffTo, playerToCuff)
	
	return true
end

local function SetUpCuffAttachment(character: Model)
	const modelIsValidFn = t.instanceIsA("Model")
	const playerIsValid, playerInvalidityReason = modelIsValidFn(character)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end
	
	const humanoidRootPart: BasePart? = character.HumanoidRootPart
	const partIsValidFn = t.instanceIsA("BasePart")
	const hrpIsValid, hrpInvalidityReason = partIsValidFn(humanoidRootPart)
	if not hrpIsValid then 
		AssertHelper.Warn(hrpInvalidityReason)
		return false
	end
	
	const attachment = Instance.new("Attachment")
	attachment.Name = "CuffAttachment"
	const attachmentOffset = CFrame.new(0, 0, -3)

	attachment.Visible = true	
	attachment.CFrame = attachmentOffset
	attachment.Parent = humanoidRootPart
end

const function UncuffPlayer(player: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	local playerIsValid, playerInvalidityReason = playerIsValidFn(player)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end
	
	const playerIsInvolvedInCuffing = CuffHelper.IsPlayerInvolvedInCuffing(player)
	if not playerIsInvolvedInCuffing then return false end
	CuffService.RemovePlayerFromInvolvedInCuffing(player)
	const playerToCuffCharacter = player.Character
	if(not playerToCuffCharacter) then return end

	const playerToCuffHrp = playerToCuffCharacter.HumanoidRootPart
	if(not playerToCuffHrp) then return end

	playerToCuffHrp:SetNetworkOwner(player)
	ToolService.UnstorePlayerTools(player)
end

const function InitializeInvolvedCuffPlayersRemoving(playerToCuffTo: Player, playerToCuff: Player)
	const playerIsValidFn = t.instanceIsA("Player")
	
	const playerToCuffToIsValid, playerToCuffToInvalidityReason = playerIsValidFn(playerToCuffTo)
	if not playerToCuffToIsValid then 
		AssertHelper.Warn(playerToCuffToInvalidityReason)
		return false
	end
	
	const playerToCuffIsValid, playerToCuffInvalidityReason = playerIsValidFn(playerToCuff)
	if not playerToCuffIsValid then 
		AssertHelper.Warn(playerToCuffInvalidityReason)
		return false
	end
	
	const playerToCuffToRemoving = playerToCuffTo.CharacterRemoving:Once(function(character: Model)
		const playerToCuffCharacter = playerToCuff.Character
		if(not playerToCuffCharacter) then return end
		const playerToCuffHrp: BasePart? = playerToCuffCharacter.HumanoidRootPart
		if(not playerToCuffHrp) then return end
		playerToCuffHrp:SetNetworkOwner(playerToCuff)
		CuffService.RemovePlayerFromInvolvedInCuffing(playerToCuff)
	end)
	
	const playerToCuffRemoving = playerToCuff.CharacterRemoving:Once(function(character: Model)
		CuffService.RemovePlayerFromInvolvedInCuffing(playerToCuffTo)
	end)
	
	if(not involvedCuffedPlayersRemoving[playerToCuffTo]) then
		involvedCuffedPlayersRemoving[playerToCuffTo] = Trove.new()
	end
	
	if(not involvedCuffedPlayersRemoving[playerToCuff]) then
		involvedCuffedPlayersRemoving[playerToCuff] = Trove.new()
	end
	
	involvedCuffedPlayersRemoving[playerToCuffTo]:Add(playerToCuffToRemoving)
	involvedCuffedPlayersRemoving[playerToCuff]:Add(playerToCuffRemoving)
end

const function ValidateCuffed(playerToCuff: Player, cuffed: boolean)
	const playerIsValidFn = t.instanceIsA("Player")
	
	const playerIsValid, playerInvalidityReason = playerIsValidFn(playerToCuff)
	if not playerIsValid then 
		AssertHelper.Warn(playerInvalidityReason)
		return false
	end
	
	const cuffedIsValid, cuffedInvalidityReason = t.boolean(cuffed)
	if not cuffedIsValid then 
		AssertHelper.Warn(cuffedInvalidityReason)
		return false
	end
	
	const globalCuffedPlayers = SystemManagerModule.GetGlobalGameState("CuffedPlayers")
	print(globalCuffedPlayers)
	if(not globalCuffedPlayers) then
		return false
	end
	if(cuffed) then
		--[[
			For the cuffed to be valid,
			the player must not be cuffed or the one cuffing already someone
			because the player can only cuff one player at a time
			
		]]
		--const currentFacilityMode = SystemManagerModule.GetGlobalGameState("CurrentMode")
		--if(currentFacilityMode ~= ModeConfig.modes.RoleReversal.Name) then return false end
		local playerToCuffFound: boolean? = false
		for playerCuffing, playerCuffed in globalCuffedPlayers do
			if(playerToCuff == playerCuffing
				or playerToCuff == playerCuffed) then
				playerToCuffFound = true
				break
			end
		end
		
		return playerToCuffFound ~= true
	else
		--[[
			If we want to uncuff the player, we need to make sure the player is cuffed
			because we don't wnat to be uncuffing a player that is not even cuffed
		]]
		local playerIsCuffed: boolean? = false
		for _, playerCuffed in globalCuffedPlayers do
			if(playerCuffed == playerToCuff) then
				playerIsCuffed = true
				break
			end
		end
		
		
		return playerIsCuffed ~= false
	end
	
	
end


const function InitializeCuffEquippedHandler()
	
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(character: Model)
			character.ChildAdded:Connect(function(child: Instance)
				if(child:IsA("Tool")
					and child.Name == "Handcuffs") then
					HostilitySystemSignals.HostilityRequested:Fire(player)	
				end
			end)
		end)
	end
	
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			character.ChildAdded:Connect(function(child: Instance)
				if(child:IsA("Tool")
					and child.Name == "Handcuffs") then
					HostilitySystemSignals.HostilityRequested:Fire(player)	
				end
			end)
		end)
	end)
end

function CuffSystem.Initialize()
	FacilityModeSystemSignals.ModeChanged:Connect(function(newMode: ModeConfig.Mode, oldMode: ModeConfig.Mode)
		if(newMode == ModeConfig.modes.RoleReversal.Name) then
			for _, player in subjectsTeam:GetPlayers() do
				ToolService.GiveTool(player, handcuffsTool)
			end
			subjectsTeamGiveHandcuffsConn = subjectsTeam.PlayerAdded:Connect(function(player: Player)
				ToolService.GiveTool(player, handcuffsTool)
			end)
		else
			if(subjectsTeamGiveHandcuffsConn) then
				subjectsTeamGiveHandcuffsConn:Disconnect()
				subjectsTeamGiveHandcuffsConn = nil
			end
		end
	end)
	SystemManagerModule.SetGlobalGameState("CuffedPlayers", {})
	
	setPlayerCuffedStateRE.OnServerEvent:Connect(function(player: Player, playerToCuff: Player, cuffed: boolean)
		const playerIsValidFn = t.instanceIsA("Player")
		const playerToCuffIsValid, playerToCuffInvalidityReason = playerIsValidFn(playerToCuff)
		if not playerToCuffIsValid then return end
		
		const cuffedIsValidRE, cuffedInvalidityReason = t.boolean(cuffed)
		if not cuffedIsValidRE then return end
		
	
		const playerCuffingValid = ValidatePlayerCuffing(player, playerToCuff)
		print(playerCuffingValid)
		if(not playerCuffingValid) then return end
		
		
		const cuffedIsValid = ValidateCuffed(playerToCuff, cuffed)
		print(cuffedIsValid)
		if(not cuffedIsValid) then return end
		
		const globalCuffedPlayers = SystemManagerModule.GetGlobalGameState("CuffedPlayers")
		if(not globalCuffedPlayers) then return end
		if(cuffed) then
			const cufferIsBeingCuffed = CuffHelper.IsPlayerInvolvedInCuffing(player)
			if(cufferIsBeingCuffed) then return end
			const playerCuffedIsInvolvedInCuffing = CuffHelper.IsPlayerInvolvedInCuffing(playerToCuff)
			if(playerCuffedIsInvolvedInCuffing) then return end
			const cuffSuccessful = CuffPlayerToPlayer(player, playerToCuff)
			if(not cuffSuccessful) then return end
			
			InitializeInvolvedCuffPlayersRemoving(player, playerToCuff)
			globalCuffedPlayers[player] = playerToCuff
		else
			UncuffPlayer(playerToCuff)
		end
	end)
	
	const players = Players:GetPlayers()
	for _, player in players do
		const character = player.Character
		if(not character) then continue end
		SetUpCuffAttachment(character)
	end
	
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			SetUpCuffAttachment(character)
		end)
	end)
end

return CuffSystem
