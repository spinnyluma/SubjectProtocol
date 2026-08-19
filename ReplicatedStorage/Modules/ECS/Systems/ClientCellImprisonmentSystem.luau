const LocalizationService = game:GetService("LocalizationService")
const CollectionService = game:GetService("CollectionService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
const Teams = game:GetService("Teams")

const ClientCuffSystemSignals = require("./ClientCuffSystem/Signals")
const CellImprisonmentConfig = require("../../Shared/Constants/CellImprisonment/CellImprisonmentConfig")
const ClientReplicaConfig = require("../../Shared/Constants/ClientReplicaConfig")
const SystemManagerModule = require("../SystemManagerModule")
const ClientCuffService = require("../../Services/Cuff/ClientCuffService")
const CharacterConfig = require("../../Shared/Constants/CharacterConfig")
const DataModelHelper = require("../../Helpers/DataModel/DataModelHelper")
const AssertHelper = require("../../Helpers/Debug/AssertHelper")
const TimeHelper = require("../../Helpers/Time/TimeHelper")
const Promise = require("../../Utilities/Promise")
const Replica = require("../../Utilities/ReplicaClient")
const ClientCuffSystemConfig = require("./ClientCuffSystem/Config")
const t = require("../../Utilities/t")

local ClientCellImprisonmentSystem = {}

const transparentImprisonmentBeam = ReplicatedStorage.Assets.Beam.Templates.Indicators.TransparentImprisonmentBeam

const subjectsTeam = Teams.Subjects

const imprisonPlayerRE = ReplicatedStorage.Assets.Shared.Remotes.Events.CellImprisonment.ImprisonPlayer

local jailed: ScreenGui? = nil
local respawnTimerLabel: TextLabel? = nil

const function ParentArrowBetweenAttachments(attachment0: Attachment, attachment1: Attachment, beamParent: Instance)
	const attachmentIsValid = t.instanceIsA("Attachment")
	const attachment0IsValid, attachment0InvalidityReason = attachmentIsValid(attachment0)
	if not attachment0IsValid then 
		AssertHelper.Warn(attachment0InvalidityReason)
		return false
	end
	
	const attachment1IsValid, attachment1InvalidityReason = attachmentIsValid(attachment1)
	if not attachment1IsValid then 
		AssertHelper.Warn(attachment1InvalidityReason)
		return false
	end
	
	const beamParentIsValid, beamParentInvalidityReason = t.Instance(beamParent)
	if(not beamParentIsValid) then
		AssertHelper.Warn(beamParentInvalidityReason)
		return
	end
	
	
	
	const clonedBeamModel = transparentImprisonmentBeam:Clone()
	const beam = clonedBeamModel:FindFirstChildWhichIsA("Beam")
	if(not beam) then return end
	
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	clonedBeamModel.Parent = beamParent	
	
end

const function AttachTransparentPointerArrow(character: Model, jailCellImprisonmentModel: Model)
	const modelIsValid = t.instanceIsA("Model")
	const characterIsValid, characterInvalidityReason = modelIsValid(character)
	if not characterIsValid then 
		AssertHelper.Warn(characterInvalidityReason)
		return false
	end
	
	const modelIsValid, modelInvalidityReason = modelIsValid(jailCellImprisonmentModel)
	if not modelIsValid then 
		AssertHelper.Warn(modelInvalidityReason)
		return false
	end
	
	const pointerArrowAttachment = jailCellImprisonmentModel:WaitForChild("PointerArrowAttachment", true)
	const humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	const rootAttachment = humanoidRootPart:WaitForChild("RootAttachment")

	ParentArrowBetweenAttachments(rootAttachment,
		pointerArrowAttachment,
		character)
end

const function SetJailCellImprisonmentPromptState(jailCellImprisonmentModel: Model, enabled: boolean)
	const modelIsValid = t.instanceIsA("Model")
	const jailCellImprisonmentModelIsValid, jailCellImprisonmentModelInvalidityReason = modelIsValid(jailCellImprisonmentModel)
	if not jailCellImprisonmentModelIsValid then 
		AssertHelper.Warn(jailCellImprisonmentModelInvalidityReason)
		return false
	end
	
	const enabledIsValid, enabledInvalidityReason = t.boolean(enabled)
	if not enabledIsValid then 
		AssertHelper.Warn(enabledInvalidityReason)
		return false
	end
	
	const promptPart = jailCellImprisonmentModel:WaitForChild("PromptPart")
	const prompt = promptPart:WaitForChild("ImprisonmentPrompt")
	prompt.Enabled = enabled
	
	if(enabled) then
		
	else
		
	end
end

const function InitializeJailedUI()
	Promise.try(function()
		const localPlayer = Players.LocalPlayer
		if(not localPlayer) then return end

		const playerGui = localPlayer:WaitForChild("PlayerGui")
		const jailedGui = playerGui:WaitForChild("Jailed")
		const respawnTimer = jailedGui:WaitForChild("JailedFrame"):WaitForChild("RespawningTimer")

		jailed = jailedGui
		respawnTimerLabel = respawnTimer
	end)
		:catch(function(err)
			AssertHelper.Warn(tostring(err))
		end)
end

const function InitializeCellImprisonment()
	const localPlayer = Players.LocalPlayer
	if(not localPlayer) then return end

	const character = localPlayer.Character
	const jailCellImprisonmentModels = CollectionService:GetTagged(CellImprisonmentConfig.CELL_IMPRISONMENT_TAG_NAME)


	if(character) then
		Promise.try(function()
			const humanoid: Humanoid = character:WaitForChild("Humanoid")
			if(humanoid:GetState() == Enum.HumanoidStateType.Dead) then return end
			for _, jailCellImprisonmentModel in jailCellImprisonmentModels do
				AttachTransparentPointerArrow(character, jailCellImprisonmentModel)
				SetJailCellImprisonmentPromptState(jailCellImprisonmentModel, true)
			end
		end)
			:catch(function(err)
				AssertHelper.Warn(tostring(err))
			end)


	end
end

const function GetCuffedPlayer()
	const localPlayer = Players.LocalPlayer
	if(not localPlayer) then return end
	
	const localCharacter = localPlayer.Character
	if(not localCharacter) then return end
	
	const humanoidRootPart = localCharacter:WaitForChild("HumanoidRootPart")
	const alignPosition: AlignPosition = humanoidRootPart:WaitForChild("CuffAlignPosition")
	const attachment0 = alignPosition.Attachment0

	const character = DataModelHelper.GetRootParentWithTag(attachment0, CharacterConfig.CHARACTER_TAG_NAME)
	const player = Players:GetPlayerFromCharacter(character)
	return player
end

const function InitializeCellImprisonmentPrompts()
	const jailCellImprisonmentModels = CollectionService:GetTagged(CellImprisonmentConfig.CELL_IMPRISONMENT_TAG_NAME)
	const localPlayer = Players.LocalPlayer
	if(not localPlayer) then return end
	
	for _, jailCellImprisonmentModel in jailCellImprisonmentModels do
		Promise.try(function()
			local promptPart = jailCellImprisonmentModel:WaitForChild("PromptPart")
			local prompt = promptPart:WaitForChild("ImprisonmentPrompt")
			prompt.Triggered:Connect(function(playerWhoTriggered: Player)
				const cuffStateComp = SystemManagerModule.GetComponentByEntity("CuffState", localPlayer)
				const cuffStateCompIsValid, cuffStateCompInvalidityReason = t.table(cuffStateComp)
				if(not cuffStateCompIsValid) then
					AssertHelper.Warn(cuffStateCompInvalidityReason)
					return
				end
				
				const cuffedPlayer = GetCuffedPlayer()
				if(not cuffedPlayer) then return end
				-- clean on death handlers trove for that player and remove cuff constraints
				ClientCuffService.RemoveCuffConstraints(localPlayer)
				ClientCuffService.SetCuffState(ClientCuffSystemConfig.cuffStates.Idle.Name)

				-- Remove transparent arrow attachments
				for _, descendant in localPlayer.Character:GetDescendants() do
					if descendant.Name == "TransparentImprisonmentBeam" then
						descendant:Destroy()
					end
				end
				
				imprisonPlayerRE:FireServer(cuffedPlayer)
				
			end)
		end)
			:catch(function(err)
				AssertHelper.Warn(tostring(err))
			end)
		
	end
end

const function SetJailedScreenGuiState(state: boolean)
	const stateIsValid = t.boolean(state)
	if(not stateIsValid) then return end
	if(not jailed) then return end
	
	jailed.Enabled = state
end

const function SetRespawnTimeLabel(respawnTime: number)
	const respawnTimeIsValid, respawnTimeInvalidityReason = t.number(respawnTime)
	if(not respawnTimeIsValid) then
		AssertHelper.Warn(respawnTimeInvalidityReason)
		return
	end
	const minutesSeconds = TimeHelper.GetMinutesSecondsFromSeconds(respawnTime)
	if(not respawnTimerLabel) then return end
	respawnTimerLabel.Text = "Respawning in " .. minutesSeconds
end

function ClientCellImprisonmentSystem.Initialize()
	const localPlayer = Players.LocalPlayer
	if(not localPlayer) then return end
	Replica.OnNew(ClientReplicaConfig.replicaTokenNames.CellImprisonment.Name, function(replica: Replica.Replica)
		if(localPlayer ~= replica.Tags["Player"]) then
			return
		end	
		
		replica:OnSet({"Active"}, function(newValue: boolean, oldValue: boolean)
			SetJailedScreenGuiState(newValue)
		end)
		replica:OnSet({"RespawnTime"}, function(newValue: boolean, oldValue: boolean)
			SetRespawnTimeLabel(newValue)
		end)
	end)
	
	ClientCuffSystemSignals.CuffStateChanged:Connect(function(newState: string, oldState: string)
		const localPlayer = Players.LocalPlayer
		if(not localPlayer) then return end
		
		const team = localPlayer.Team
		if(team ~= subjectsTeam) then return end
		if(newState == ClientCuffSystemConfig.cuffStates.Cuffing.Name) then
			InitializeCellImprisonment()
		end
	end)
	InitializeCellImprisonmentPrompts()
	InitializeJailedUI()
end

return ClientCellImprisonmentSystem
