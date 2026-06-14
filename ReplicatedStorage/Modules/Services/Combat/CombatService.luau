local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpatialQueryConfig = require(ReplicatedStorage
	.Modules
	.Shared
	.Constants
	.SpatialQueryConfig
)

local AssertHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Debug
	.AssertHelper)
local CharacterHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Character
	.CharacterHelper
)

local replicateRayRE = ReplicatedStorage.Assets.Shared.Remotes.Events.ReplicateRay


local CombatService = {}
--[[
	Performs a raycast from an origin in a given direction.
	
	@param Vector3 origin The origin of the raycast.
	@param Vector3 direction The direction of the raycast.
	@param RaycastParams params The parameters of the raycast.
	@return RaycastResult? The result of the raycast.
]]
function CombatService.FireRay(origin: Vector3,
	direction: Vector3,
	params: RaycastParams
)
	local originIsValid: boolean = AssertHelper.InvalidArgAssert(
		typeof(origin) == "Vector3",
		origin,
		"origin",
		"FireRay",
		"Vector3"
	)
	if(not originIsValid) then return end
	local directionIsValid: boolean = AssertHelper.InvalidArgAssert(
		typeof(direction) == "Vector3",
		direction,
		"direction",
		"FireRay",
		"Vector3"
	)
	if(not directionIsValid) then return end
	
	local raycastResult = workspace:Raycast(
		origin,
		direction,
		params
	)
	return raycastResult
end

function CombatService.ReplicateRay(
	origin: Vector3, 
	endPosition: Vector3,
	playersToReplicateTo: {Player?}?
)
	local originIsValid: boolean = AssertHelper.InvalidArgAssert(
		typeof(origin) == "Vector3",
		origin,
		"origin",
		"CombatService.ReplicateRay",
		"Vector3"
	)
	if(not originIsValid) then return end
	
	local endPositionIsValid: boolean = AssertHelper.InvalidArgAssert(
		typeof(endPosition) == "Vector3",
		endPosition,
		"endPosition",
		"CombatService.ReplicateRay",
		"Vector3"
	)
	if(not endPositionIsValid) then return end
	
	local playersToReplicateToIsValid: boolean = AssertHelper.InvalidArgAssert(
		typeof(playersToReplicateTo) == "table"
		or type(playersToReplicateTo) == "nil",
		playersToReplicateTo,
		"playersToReplicateTo",
		"CombatService.ReplicateRay",
		"table"
	)
	if(not playersToReplicateToIsValid) then return end
	
	for _, client in playersToReplicateTo do
		local clientIsValid: boolean? = AssertHelper.ExpectedValAssert(
			typeof(client) == "Instance"
				and client:IsA("Player"),
			client,
			"client",
			"CombatService.ReplicateRay",
			"Player"
		)
		if(not clientIsValid) then continue end
		replicateRayRE:FireClient(client, origin, endPosition)

	end
end

--[[
	Damages the humanoid of a character by a specified amount of damage.
	
	@param Model character The character to damage.
	@param number damage The amount of damage to deal.
]]
function CombatService.DamageCharacter(character: Model, damage: number)
	local characterIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(character) == "Instance"
		and character:IsA("Model"),
		character,
		"character",
		"DamageCharacter",
		"Model"
	)
	if(not characterIsValid) then return end
	
	local damageIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(damage) == "number",
		damage,
		"damage",
		"DamageCharacter",
		"number"
	)
	if(not damageIsValid) then return end
	
	local humanoid: Humanoid? = CharacterHelper.GetHumanoidFromCharacter(character)
	local humanoidIsValid: boolean = AssertHelper.ExpectedValAssert(
		typeof(humanoid) == "Instance"
		and humanoid:IsA("Humanoid"),
		humanoid,
		"humanoid",
		"Humanoid"
	)
	if(not humanoidIsValid) then return end
	
	humanoid:TakeDamage(damage)
end


return CombatService
