local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssertHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Debug
	.AssertHelper
)
local DataModelHelper = require(ReplicatedStorage.Modules.Helpers.DataModel.DataModelHelper)

local CharacterConfig = require(ReplicatedStorage.Modules.Shared.Constants.CharacterConfig)


local CharacterHelper = {}

--[[
	Gets the humanoid from a character model.
	
	@param Model character The character model.
	@return Humanoid? The humanoid.
]]
function CharacterHelper.GetHumanoidFromCharacter(character: Model): Humanoid
	local characterIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
		and character:IsA("Model"),
		character,
		"character",
		"CharacterModule.GetHumanoidFromCharacter",
		"Model"
	)
	if(not characterIsValid) then
		return nil
	end
	
	local humanoid: Humanoid? = character:FindFirstChildWhichIsA("Humanoid")
	
	if(not humanoid) then
		return nil
	end
	return humanoid
end

--[[
	Gets a humanoid root part from a character.
	
	@param Model character The character model.
	@returns BasePart? The humanoid root part.
]]
function CharacterHelper.GetRootPartFromCharacter(character: Model): BasePart?
	local characterIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
		and character:IsA("Model"),
		character,
		"character",
		"CharacterModule.GetRootPartFromCharacter",
		"Model"
	)
	if(not characterIsValid) then
		return nil
	end
	
	local humanoidRootPart: BasePart? = character.PrimaryPart
	local humanoidRootPartIsValid: boolean = typeof(humanoidRootPart) == "Instance"
		and humanoidRootPart:IsA("BasePart")
	if(humanoidRootPartIsValid) then
		return humanoidRootPart
	else
		return character:FindFirstChild("HumanoidRootPart")
	end
end


--[[
	Returns a table of the parts of a character (Head, HRP, Limbs)
	
	@param Model character The character to query the parts of.
	@returns {BasePart?}? A table of the parts of a character (Head, HRP, Limbs)
]]
function CharacterHelper.GetCharacterParts(character: Model): {BasePart?}?
	local characterIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
			and character:IsA("Model"),
		character,
		"character",
		"CharacterModule.GetCharacterParts",
		"Model"
	)
	if(not characterIsValid) then
		return nil
	end

	local charPartsSelector: string = "Part:not(Object > BasePart),MeshPart:not(Object > BasePart)"
	local characterParts: {BasePart?} = character:QueryDescendants(charPartsSelector)
	return characterParts
end

--[[
	Gets the hat parts (NOT the accessories) from a character. These parts are the children "Handle" objects of an Accessory.
	
	@param Model character The character to get the hat parts from.
	@returns {BasePart?}? A table of the hat parts of a character.
]]
function CharacterHelper.GetHatParts(character: Model): {BasePart?}?
	local characterIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
		and character:IsA("Model"),
		character,
		"character",
		"CharacterModule.GetHatParts",
		"Model"
	)
	if(not characterIsValid) then
		return nil
	end
	
	
	local hatPartsSelector: string = "Accessory > BasePart"
	local hatParts: string = character:QueryDescendants(hatPartsSelector)
	return hatParts	
end

--[[
	Returns a table of unique player characters from a list of BaseParts.
	
	@param {BasePart?} characterParts The list of BaseParts to get the players from.
	@returns {Model?}? A table of unique players from a list of BaseParts with the format:
	{
		<character: Model>
	}
]]
function CharacterHelper.GetCharsFromCharacterParts(characterParts: {BasePart?}): {Model?}?
	local characterPartsIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(characterParts) == "table",
		characterParts,
		"characterParts",
		"CharacterModule.GetCharsFromCharacterParts",
		"table"
	)
	if(not characterPartsIsValid) then
		return nil		
	end

	local characters: {Model?} = {}

	for _, charPart in characterParts do
		local charPartIsValid: boolean? = AssertHelper.ExpectedValAssert(
			typeof(charPart) == "Instance"
				and charPart:IsA("BasePart"),
			charPart,
			"charPart",
			"BasePart"
		)
		if(not charPartIsValid) then
			continue
		end


		local character: Model? = charPart.Parent
		local characterIsValid: boolean? = AssertHelper.ExpectedValAssert(
			typeof(character) == "Instance",
			character,
			"character",
			"Instance"
		)
		if(not characterIsValid) then
			continue
		end

		local charHasHumanoid: boolean = character:FindFirstChildWhichIsA("Humanoid") ~= nil		
		if(not charHasHumanoid) then
			continue
		end


		local charInTable: boolean = table.find(characters, character)
		if(charInTable ~= nil) then
			continue
		end
		table.insert(characters, character)
	end
	return characters
end

--[[
	Gets the position where the character is standing (below the middle of the two legs of a character).
	
	@param Model character The character to get the standing position of.
	@returns Vector3? The position where the character is standing.
]]
function CharacterHelper.GetStandingPosition(character: Model): Vector3?
	local characterIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
		and character:IsA("Model"),
		character,
		"character",
		"CharacterModule.GetStandingPosition",
		"Model"
	)
	if(not characterIsValid) then
		return nil
	end
	
	local humanoid: Humanoid? = CharacterHelper.GetHumanoidFromCharacter(character)
	local humanoidIsValid: boolean? = AssertHelper.ExpectedValAssert(
		typeof(humanoid) == "Instance"
		and humanoid:IsA("Humanoid"),
		humanoid,
		"humanoid",
		"Humanoid"
	)
	if(not humanoidIsValid) then
		return nil
	end
	
	local rootPart: BasePart = CharacterHelper.GetRootPartFromCharacter(character)
	local rootPartIsValid: boolean? = AssertHelper.ExpectedValAssert(
		typeof(rootPart) == "Instance"
		and rootPart:IsA("BasePart"),
		rootPart,
		"rootPart",
		"BasePart"
	)
	if(not rootPartIsValid) then
		return nil
	end
	
	local hipHeight: number = humanoid.HipHeight
	local rootPartHalfSize: number = rootPart.Size.Y / 2
	
	local belowLegsYPos: number = rootPart.Position.Y - hipHeight - rootPartHalfSize
	local standingPosition: Vector3 = Vector3.new(
		rootPart.Position.X,
		belowLegsYPos,
		rootPart.Position.Z
	)
	return standingPosition
end

--[[
	Gets the humanoid's Animator instance from a character.
	
	@param Model character The character to get the humanoid's Animator instance from.
	@returns Animator? The humanoid's Animator instance.
]]
function CharacterHelper.GetAnimatorFromCharacter(character: Model): Animator?
	local characterIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
		and character:IsA("Model"),
		character,
		"character",
		"CharacterModule.GetAnimatorFromCharacter",
		"Model"
	)
	if(not characterIsValid) then
		return nil
	end
	
	local humanoid: Humanoid? = CharacterHelper.GetHumanoidFromCharacter(character)
	local humanoidIsValid: boolean? = AssertHelper.ExpectedValAssert(
		typeof(humanoid) == "Instance"
		and humanoid:IsA("Humanoid"),
		humanoid,
		"humanoid",
		"Humanoid"
	)
	if(not humanoidIsValid) then
		return nil
	end
	
	local animator: Animator? = humanoid:FindFirstChildWhichIsA("Animator")
	local animatorIsValid: boolean? = AssertHelper.ExpectedValAssert(
		typeof(animator) == "Instance"
		and animator:IsA("Animator"),
		animator,
		"animator",
		"Animator"
	)
	if(not animatorIsValid) then
		return nil
	end
	
	return animator
end

function CharacterHelper.IsPartExistentInCharacter(character: Model, part: BasePart)
	local partIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(part) == "Instance"
		and part:IsA("BasePart"),
		part,
		"part",
		"CharacterModule.IsPartExistentInCharacter",
		"BasePart"
	)
	if(not partIsValid) then
		return false
	end
	
	local characterIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
		and character:IsA("Model"),
		character,
		"character",
		"CharacterModule.IsPartExistentInCharacter",
		"Model"
	)
	if(not characterIsValid) then return false end
	return part:IsDescendantOf(character)
end


--[[
	Checks if a part is in any character model.
	
	@param BasePart part The part to check.
	@returns Model? The character model that the part is in.
]]
function CharacterHelper.IsPartInCharacterModel(part: Instance): Model?
	local partIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(part) == "Instance"
		and part:IsA("BasePart"),
		part,
		"part",
		"CharacterHelper.IsPartInCharacterModel",
		"BasePart"
	)
	if(not partIsValid) then
		return nil
	end
	
	local characterModel = DataModelHelper.GetRootParentWithTag(part, CharacterConfig.CHARACTER_TAG_NAME)

	return characterModel ~= nil
end

function CharacterHelper.IsCharacterDead(character: Model): boolean
	
	local characterIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
		and character:IsA("Model"),
		character,
		"character",
		"CharacterHelper.IsCharacterDead",
		"Model"
	)
	if(not characterIsValid) then
		return true
	end
	
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if(not humanoid) then
		return true
	end
	
	local humanoidState = humanoid:GetState()
	return humanoidState == Enum.HumanoidStateType.Dead
end

return CharacterHelper
