local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TurretConfig = require(ReplicatedStorage.Modules.Shared.Constants.TurretConfig)
local TurretSystemConfig = require(script.Config)

local SpatialQueryConfig = require(ReplicatedStorage
	.Modules
	.Shared
	.Constants
	.SpatialQueryConfig)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local PlayerHelper = require(ReplicatedStorage.Modules.Helpers.Player.PlayerHelper)
local VectorHelper = require(ReplicatedStorage.Modules.Helpers.Vector.VectorHelper)
local CharacterHelper = require(ReplicatedStorage.Modules.Helpers.Character.CharacterHelper)


local CombatService = require(ReplicatedStorage
	.Modules
	.Services
	.Combat
	.CombatService
)

local TURRET_RAY_LENGTH = 300

local TurretSystem = {}

local function ShootTurret(turret: Model)
	local turretIsValid = AssertHelper.InvalidArgAssert(
		typeof(turret) == "Instance"
		and turret:IsA("Model"),
		turret,
		"turret",
		"ShootTurret",
		"Model"
	)
	if(not turretIsValid) then return end
	
	local firePoint: BasePart? = turret:FindFirstChild("FirePoint")
	local firePointIsValid = AssertHelper.ExpectedValAssert(
		typeof(firePoint) == "Instance"
			and firePoint:IsA("BasePart"),
		firePoint,
		"firePoint",
		"ShootTurret",
		"BasePart"
	)
	if(not firePointIsValid) then return end
	
	local nearestPlayers = PlayerHelper.GetNearestPlayersFromPosition(firePoint.Position)
	if(not nearestPlayers or (#nearestPlayers < 1)) then return end
	
	for index, table in nearestPlayers do
		local nearestPlayer = nearestPlayers[index]
		local player: Player? = nearestPlayer["Player"]
		local playerIsValid = AssertHelper.ExpectedValAssert(
			typeof(player) == "Instance"
				and player:IsA("Player"),
			player,
			"player",
			"ShootTurret",
			"Player"
		)
		if(not playerIsValid) then continue end

		local character: Model? = player.Character
		if(not character) then continue end

		local bodyParts: {BasePart?} = character:QueryDescendants("#UpperTorso, #Torso")
		if(#bodyParts == 0) then continue end

		local aimedBodyPart = bodyParts[1]
		local aimedBodyPartIsValid = typeof(aimedBodyPart) == "Instance"
			and aimedBodyPart:IsA("BasePart")
		if(not aimedBodyPartIsValid) then continue end	
		local unitVector: Vector3? = VectorHelper.GetUnitVectorBetweenParts(firePoint,
			aimedBodyPart
		) 
		if(not unitVector) then continue end
		local direction = unitVector * TURRET_RAY_LENGTH
		
		local paramsFn: (string, {[string]: any}) -> RaycastParams? = SpatialQueryConfig.raycastParams[TurretConfig.TURRET_TAG_NAME]
		local paramsFnIsValid = AssertHelper.ExpectedValAssert(
			typeof(paramsFn) == "function",
			paramsFn,
			"paramsFn",
			"function"
		)
		if(not paramsFnIsValid) then return end

		local params: OverlapParams? = paramsFn(TurretConfig.TURRET_TAG_NAME, {
			["Self"] = turret
		})
		local paramsIsValid = AssertHelper.ExpectedValAssert(
			typeof(params) == "RaycastParams",
			params,
			"params",
			"RaycastParams"
		)
		if(not paramsIsValid) then return end

		local raycastResult: RaycastResult? = CombatService.FireRay(firePoint.Position,
			direction,
			params
		)
		if(not raycastResult) then continue end
		
		local instance = raycastResult.Instance
		local instanceExistsInCharacter: boolean = CharacterHelper.IsPartExistentInCharacter(
			character,
			instance
		)
		if(not instanceExistsInCharacter) then continue end
		
		local damage = TurretSystemConfig.TURRET_DAMAGE
		
		CombatService.DamageCharacter(character, damage)
	end
	
end

function TurretSystem.Update()
	local turrets: {Model?} = CollectionService:GetTagged(TurretConfig.TURRET_TAG_NAME)

	for _, turret in turrets do
		local barrel: BasePart? = turret:FindFirstChild("Barrel")
		local barrelIsValid = typeof(barrel) == "Instance"
			and barrel:IsA("BasePart")
		
		if(not barrelIsValid) then continue end
		ShootTurret(turret)
	end
end


function TurretSystem.Initialize()
	
end

return TurretSystem
