const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const Modules = ReplicatedStorage.Modules

const Utilities = Modules.Utilities
const Services = Modules.Services
const Helpers = Modules.Helpers
const Shared = Modules.Shared

const Combat = Services.Combat

const Constants = Shared.Constants

const CharacterConfig = require(Constants.CharacterConfig)
const CombatService = require(Combat.CombatService)
const t = require(Utilities.t)

const Character = Helpers.Character

const DataModel = Helpers.DataModel
const Debug = Helpers.Debug

const CharacterHelper = require(Character.CharacterHelper)
const DataModelHelper = require(DataModel.DataModelHelper)
const AssertHelper = require(Debug.AssertHelper)

local AreaDamageService = {}

const areaDamageParams = OverlapParams.new()

function AreaDamageService.DamageCharacterInRadiusFalloff( 
	radiusCenter: Vector3,
	maxDamage: number,
	fullDamageMinRadius: number,
	maxRadius: number
)
	const radiusCenterIsValid = AssertHelper.InvalidArgAssert(
		typeof(radiusCenter) == "Vector3",
		radiusCenter,
		"radiusCenter",
		"AreaDamageService.DamageCharacterInRadiusFalloff",
		"Vector3"
	)
	if(not radiusCenterIsValid) then return end
	
	const maxDamageIsValid = AssertHelper.InvalidArgAssert(
		typeof(maxDamage) == "number",
		maxDamage,
		"maxDamage",
		"AreaDamageService.DamageCharacterInRadiusFalloff",
		"number"
	)
	if(not maxDamageIsValid) then return end
	
	const fullDamageMinRadiusIsValid, minRadiusInvalidityReason = t.number(fullDamageMinRadius)
	if(not fullDamageMinRadiusIsValid) then
		AssertHelper.Warn(minRadiusInvalidityReason)
		return
	end
	
	const maxRadiusIsValid = AssertHelper.InvalidArgAssert(
		typeof(maxRadius) == "number",
		maxRadius,
		"maxRadius",
		"AreaDamageService.DamageCharacterInRadiusFalloff",
		"number"
	)
	if(not maxRadiusIsValid) then return end
	
	const partsInRadius = workspace:GetPartBoundsInRadius(
		radiusCenter,
		maxRadius,
		areaDamageParams
	)
	const characters = {}
	
	for _, part in partsInRadius do
		const character = DataModelHelper.GetRootParentWithTag(part, CharacterConfig.CHARACTER_TAG_NAME)
		if(not character) then continue end
		
		local charInTableIndex = table.find(characters, character)
		if(charInTableIndex) then continue end
		
		table.insert(characters, character)		
	end
	for _, character in characters do
		const player = Players:GetPlayerFromCharacter(character)

		local magnitudeToCenter: number? = nil 

		if(player) then
			magnitudeToCenter = player:DistanceFromCharacter(radiusCenter)
		else
			const head = character.Head
			if(not head) then return end

			magnitudeToCenter = (head.Position - radiusCenter).Magnitude
		end
		
		const fallOffRange = maxRadius - fullDamageMinRadius
		const damageRatio = math.clamp((magnitudeToCenter - fullDamageMinRadius) / fallOffRange, 0, 1)
		const damage = maxDamage * (1 - damageRatio)
		CombatService.DamageCharacter(character, damage)
	end
end

return AreaDamageService
