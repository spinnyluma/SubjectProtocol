const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const cuffPlayerRE = ReplicatedStorage.Assets.Shared.Remotes.Events.CuffPlayer
const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Helpers = Modules.Helpers
const Shared = Modules.Shared

const Character = Helpers.Character
const Debug = Helpers.Debug
const Tool = Helpers.Tool

const Constants = Shared.Constants

const CharacterHelper = require(Character.CharacterHelper)
const AssertHelper = require(Debug.AssertHelper)
const ToolConfig = require(Constants.ToolConfig)
const ToolHelper = require(Tool.ToolHelper)
const t = require(Utilities.t)

local CuffSystem = {}

const ACCEPTABLE_CUFFING_DISTANCE = 20

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
	alignPosition.Responsiveness = 100
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
	print("got here")
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
		return
	end
	
	SetUpCuffingAlignPosition(cuffAttachment, playerToCuffRootAttachment)
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


function CuffSystem.Initialize()
	cuffPlayerRE.OnServerEvent:Connect(function(player: Player, playerToCuff: Player)
		if(not player) then return end
		if(not playerToCuff) then return end
		
		const playerCuffingValid = ValidatePlayerCuffing(player, playerToCuff)
		print(playerCuffingValid)
		if(not playerCuffingValid) then return end
		
		CuffPlayerToPlayer(player, playerToCuff)
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
