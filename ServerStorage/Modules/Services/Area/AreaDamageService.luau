const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const Modules = ReplicatedStorage.Modules

const Helpers = Modules.Helpers

const Debug = Helpers.Debug

const AssertHelper = require(Debug.AssertHelper)

local AreaDamageService = {}

const areaDamageParams = OverlapParams.new()

function AreaDamageService.DamageCharacterInRadiusFalloff( 
	radiusCenter: Vector3,
	maxDamage: number,
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
		--TODO: insert characters
	end
	const player = Players:GetPlayerFromCharacter(character)
	
	local magnitudeToCenter: number? = nil 

	if(player) then
		magnitudeToCenter = player:DistanceFromCharacter(radiusCenter)
	else
		const head = character.Head
		if(not head) then return end
		
		magnitudeToCenter = (head.Position - radiusCenter).Magnitude
	end
	
	const damageRatio = math.clamp(magnitudeToCenter / maxRadius, 0, 1)
	const damage = maxDamage * (1 - damageRatio)
	
end

return AreaDamageService
