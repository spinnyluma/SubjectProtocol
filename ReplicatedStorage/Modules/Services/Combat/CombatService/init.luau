local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local CollectionService = game:GetService("CollectionService")

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
local DataModelHelper = require(ReplicatedStorage.Modules.Helpers.DataModel.DataModelHelper)

local CombatServiceConfig = require(script.Config)

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

local function MutateTracerFromConfigKeyValue(template: Model,
	configKey: string,
	configValue: any
)
	local templateIsValid = AssertHelper.InvalidArgAssert(
		typeof(template) == "Instance"
			and template:IsA("Model"),
		template,
		"template",
		"MutateRayFromParamsKeyValue",
		"Model"
	)
	if(not templateIsValid) then return end
	
	local configKeyIsValid = AssertHelper.InvalidArgAssert(
		typeof(configKey) == "string",
		configKey,
		"configKey",
		"MutateRayFromParamsKeyValue",
		"string"
	)
	if(not configKeyIsValid) then return end
	
	local configValueIsValid = AssertHelper.InvalidArgAssert(
		typeof(configValue) ~= "nil",
		configValue,
		"configValue",
		"MutateRayFromParamsKeyValue",
		"any"
	)
	if(not configValueIsValid) then return end
	
	local tracerPart: BasePart = template:FindFirstChild("Tracer")
	local tracerPartIsValid = AssertHelper.ExpectedValAssert(
		typeof(tracerPart) == "Instance"
			and tracerPart:IsA("BasePart"),
		tracerPart,
		"tracerPart",
		"MutateRayFromParamsKeyValue",
		"BasePart"
	)
	if(not tracerPartIsValid) then return end
	
	if(configKey == "Team") then
		local team: Team? = configValue
		local teamIsValid = AssertHelper.ExpectedValAssert(
			typeof(team) == "Instance"
			and team:IsA("Team"),
			team,
			"team",
			"Team"	
		)
		if(not teamIsValid) then
			return
		end
		local teamColor: BrickColor = team.TeamColor
		tracerPart.Color = teamColor.Color
		
	end
end

function CombatService.GenerateRay(
	template: Model,
	startPosition: Vector3,
	endPosition: Vector3,
	config: CombatServiceConfig.TracerParams?
)
	local templateIsValid = AssertHelper.InvalidArgAssert(
		typeof(template) == "Instance"
		and template:IsA("Model"),
		template,
		"template",
		"CombatService.GenerateRay",
		"Model"
	)
	if(not templateIsValid) then return end
	
	local startPositionIsValid = AssertHelper.InvalidArgAssert(
		typeof(startPosition) == "Vector3",
		startPosition,
		"startPosition",
		"CombatService.GenerateRay",
		"Vector3"
	)
	if(not startPositionIsValid) then return end
	
	local endPositionIsValid = AssertHelper.InvalidArgAssert(
		typeof(endPosition) == "Vector3",
		endPosition,
		"endPosition",
		"CombatService.GenerateRay",
		"Vector3"
	)
	if(not endPositionIsValid) then return end
	
	local configIsValid = AssertHelper.InvalidArgAssert(
		type(config) == "table"
		or type(config) == "nil",
		config,
		"config",
		"CombatService.GenerateRay",
		"table?"
	)
	if(not configIsValid) then return end
	
	local tracer = template:Clone()
	if(config) then
		for key, value in config do
			MutateTracerFromConfigKeyValue(tracer, key, value)
		end
	end
	
	
	
	local tracerPosition: Vector3 = (startPosition + endPosition) / 2
	local cframe = CFrame.lookAt(tracerPosition, endPosition)
	local raycastDistance = (startPosition - endPosition).Magnitude
	
	local tracerPart = tracer:FindFirstChild("Tracer")
	
	tracerPart.Size = Vector3.new(
		tracerPart.Size.X,
		tracerPart.Size.Y,
		raycastDistance
	)
	
	tracer:PivotTo(cframe)
	tracer.Parent = workspace
	task.delay(0.025, function()
		tracer:Destroy()
	end)
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
	rayStartPart: BasePart,
	endPosition: Vector3,
	playersToReplicateTo: {Player?}?,
	tracerParams: CombatServiceConfig.TracerParams?
)
	local rayStartPartIsValid = AssertHelper.InvalidArgAssert(
		typeof(rayStartPart) == "Instance"
			and rayStartPart:IsA("BasePart"),
		rayStartPart,
		"rayStartPart",
		"CombatService.ReplicateRay",
		"BasePart"
	)
	if(not rayStartPartIsValid) then return end
	
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
	
	local tracerParamsIsValid = AssertHelper.InvalidArgAssert(
		typeof(tracerParams) == "table"
		or type(tracerParams) == "nil",
		playersToReplicateTo,
		"tracerParams",
		"CombatService.ReplicateRay",
		"CombatServiceConfig.TracerParams"
	)
	if(not tracerParamsIsValid) then return end
	
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
		replicateRayRE:FireClient(client, rayStartPart, endPosition, tracerParams)

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

--[[
	Checks whether an instance is part of a damageable object (tagged with T_Damageable).
	
	@param Instance instance The instance to check.
	@returns boolean Whether the instance was part of a damageable object.
]]
function CombatService.IsInstancePartOfDamageableObject(instance: Instance): boolean
	local instanceIsValid = AssertHelper.InvalidArgAssert(
		typeof(instance) == "Instance",
		instance,
		"instance",
		"CombatService.IsInstancePartOfDamageableObject",
		"Instance"
	)
	if(not instanceIsValid) then return false end
	
	local parent = DataModelHelper.GetRootParentWithTag(instance, CombatServiceConfig.DAMAGEABLE_TAG_NAME)
	return parent ~= nil
end


--[[
	Damage a damageable object by a specified amount of damage.
	
	@param Instance instance The instance to damage.
	@param number damage The damage to deal.
	@returns number? The new health of the damageable object.
]]
function CombatService.DamageDamageableObject(instance: Instance, damage: number): number?
	local instanceIsValid = AssertHelper.InvalidArgAssert(
		typeof(instance) == "Instance",
		instance,
		"instance",
		"CombatService.DamageDamageableObject",
		"Instance"
	)
	if(not instanceIsValid) then return end
	
	local damageIsValid = AssertHelper.InvalidArgAssert(
		type(damage) == "number",
		damage,
		"damage",
		"CombatService.DamageDamageableObject",
		"number"
	)
	if(not damageIsValid) then return end
	
	local rootParent = DataModelHelper.GetRootParentWithTag(instance, CombatServiceConfig.DAMAGEABLE_TAG_NAME)
	local rootParentIsValid = typeof(rootParent) == "Instance"
	if(not rootParentIsValid) then return end
	local parentHasDamageableTag = CollectionService:HasTag(rootParent, CombatServiceConfig.DAMAGEABLE_TAG_NAME)
	local parentHasDamageableTagIsValid = AssertHelper.ExpectedValAssert(
		parentHasDamageableTag,
		parentHasDamageableTag,
		"parentHasDamageableTag",
		"true"
	)
	if(not parentHasDamageableTagIsValid) then return end
	
	local healthAttribute: number? = rootParent:GetAttribute(CombatServiceConfig.HEALTH_ATTR_NAME)
	local healthAttributeIsValid = AssertHelper.ExpectedValAssert(
		type(healthAttribute) == "number",
		healthAttribute,
		"healthAttribute",
		"number"
	)
	if(not healthAttributeIsValid) then return end
	
	
	if(damage > healthAttribute) then
		rootParent:SetAttribute(CombatServiceConfig.HEALTH_ATTR_NAME, 0)
	elseif(healthAttribute >= damage) then
		rootParent:SetAttribute(CombatServiceConfig.HEALTH_ATTR_NAME, healthAttribute - damage)
	end
	return rootParent:GetAttribute(CombatServiceConfig.HEALTH_ATTR_NAME)
end

return CombatService
