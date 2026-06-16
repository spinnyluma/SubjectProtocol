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
local VectorHelper = require(ReplicatedStorage
	.Modules
	.Helpers
	.Vector
	.VectorHelper)

local replicateRayRE = ReplicatedStorage.Assets.Shared.Remotes.Events.ReplicateRay

local RAYCAST_MAX_LENGTH = 15_000

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
): RaycastResult?
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

function CombatService.IsPlayerInViewOfPart(part: Vector3,
	player: Player,
	lengthOfRay: number,
	raycastParams: RaycastParams
)
	local playerIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
			and player:IsA("Player"),
		player,
		"player",
		"IsPlayerInViewOfPart",
		"Player"
	)
	if(not playerIsValid) then return false end
	local partIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(part) == "Instance"
		and part:IsA("BasePart"),
		part,
		"part",
		"CombatService.IsPlayerInViewOfPart",
		"BasePart"
	)
	if(not partIsValid) then return false end
	
	local lengthOfRayIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(part) == "Instance"
		and part:IsA("BasePart"),
		part,
		"part",
		"CombatService.IsPlayerInViewOfPart",
		"number"
	)
	if(not lengthOfRayIsValid) then return false end
	
	local raycastParamsIsValid: boolean? = AssertHelper.InvalidArgAssert(
		typeof(raycastParams) == "RaycastParams",
		raycastParams,
		"raycastParams",
		"CombatService.IsPlayerInViewOfPart",
		"RaycastParams"
	)
	if(not raycastParamsIsValid) then return false end
	local character: Model? = player.Character
	if(not character) then return false end

	local bodyParts: {BasePart?} = character:QueryDescendants("#UpperTorso, #Torso")
	if(#bodyParts == 0) then return false end

	local aimedBodyPart = bodyParts[1]
	local aimedBodyPartIsValid = typeof(aimedBodyPart) == "Instance"
		and aimedBodyPart:IsA("BasePart")
	if(not aimedBodyPartIsValid) then return false end	
	local unitVector: Vector3? = VectorHelper.GetUnitVectorBetweenParts(part,
		aimedBodyPart
	) 
	if(not unitVector) then return end

	
	local direction = unitVector * lengthOfRay

	

	local raycastResult: RaycastResult? = CombatService.FireRay(part.Position,
		direction,
		raycastParams
	)
	if(not raycastResult) then return false end
	local instance = raycastResult.Instance
	local instanceExistsInCharacter: boolean = CharacterHelper.IsPartExistentInCharacter(
		character,
		instance
	)
	if(not instanceExistsInCharacter) then return false end
	return true
end

function CombatService.ReplicateRay(
	originPart: BasePart, 
	endPosition: Vector3,
	playersToReplicateTo: {Player?}?
)
	local originPartIsValid: boolean = AssertHelper.InvalidArgAssert(
		typeof(originPart) == "Instance"
		and originPart:IsA("BasePart"),
		originPart,
		"originPart",
		"CombatService.ReplicateRay",
		"BasePart"
	)
	if(not originPartIsValid) then return end
	
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
		replicateRayRE:FireClient(client, originPart, endPosition)

	end
end

--[[
	Gets a random spread CFrame from a given spread in degrees.
	
	@param number spreadInDegrees The spread in degrees.
	@returns CFrame? The random spread CFrame.
]]
function CombatService.GetRandomSpreadCframe(spreadInDegrees: number): CFrame?
	local spreadInDegreesIsValid: boolean? = AssertHelper.InvalidArgAssert(
		type(spreadInDegrees) == "number",
		spreadInDegrees,
		"spreadInDegrees",
		"CombatService.GetRandomSpreadCframe",
		"number"
	)
	if(not spreadInDegreesIsValid) then return end
	
	--[[
		We do (math.random - 0.5) * 2
		because we want to get a range between -1 and 1
	]]
	local randomPitch = (math.random() - 0.5) * 2 * spreadInDegrees
	local randomYaw = (math.random() - 0.5) * 2 * spreadInDegrees
	
	
	return CFrame.Angles(
		math.rad(randomPitch),
		math.rad(randomYaw),
		0
	)
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
