local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

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

local replicateTurretRotationRE = ReplicatedStorage
	.Assets
	.Shared
	.Remotes
	.Events
	.ReplicateTurretRotation

local TURRET_RAY_LENGTH = 300
local TURRET_SPREAD_RADIUS = 4


local TurretSystem = {}

local function FireTurretRay(player: Player,
	firePoint: BasePart,
	params: RaycastParams): RaycastResult? | Vector3?
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
			and player:IsA("Player"),
		player,
		"player",
		"FireTurretRay",
		"Player"
	)
	if(not playerIsValid) then return nil end
	local firePointIsValid = AssertHelper.InvalidArgAssert(
		typeof(firePoint) == "Instance"
			and firePoint:IsA("BasePart"),
		firePoint,
		"firePoint",
		"FireTurretRay",
		"BasePart"
	)
	if(not firePointIsValid) then return nil end
	
	
	local character = player.Character
	if(not character) then return nil end

	local parts = character:QueryDescendants("#UpperTorso, #Torso")
	if(parts == 0) then return nil end
	local torso: BasePart = parts[1]
	
	local firePointPosition = firePoint.Position
	local torsoPosition = torso.Position
	local unitVectorToCharacter = (torsoPosition - firePointPosition).Unit
	local unitDirection = unitVectorToCharacter * TURRET_RAY_LENGTH
	local spreadCframe: CFrame? = CombatService.GetRandomSpreadCframe(TURRET_SPREAD_RADIUS)
	if(not spreadCframe) then return end
	local rayDirection = spreadCframe:VectorToWorldSpace(unitDirection)
	local raycastResult: RaycastResult? = CombatService.FireRay(
		firePointPosition,
		rayDirection,
		params
	)
	if(not raycastResult) then return firePointPosition + rayDirection end
	return raycastResult
end

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
	
	local firePointPosition = firePoint.Position
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

		local playerIsInViewOfPart = CombatService.IsPlayerInViewOfPart(
			firePoint,
			player,
			TURRET_RAY_LENGTH,
			params
		)
		if(not playerIsInViewOfPart) then continue end
		local players = Players:GetPlayers()
		
		local fireRayResult: RaycastResult? | Vector3? = FireTurretRay(player, firePoint, params)
		
		local resultIsRaycastResult = typeof(fireRayResult) == "RaycastResult"
		local resultIsVector3 = typeof(fireRayResult) == "Vector3"
		
		
		
		if(resultIsRaycastResult) then
			local resultInstance = fireRayResult.Instance
			local resultInstancePosition = resultInstance.Position

			CombatService.ReplicateRay(firePoint,
				resultInstancePosition,
				players
			)
			
			replicateTurretRotationRE:FireAllClients(turret, fireRayResult.Position)
			
			local character = player.Character
			if(not character) then return end
			local instanceIsInCharacter: boolean? = CharacterHelper.IsPartExistentInCharacter(character,
				resultInstance
			)
			if(not instanceIsInCharacter) then return end
			

			local damage = TurretSystemConfig.TURRET_DAMAGE

			CombatService.DamageCharacter(character, damage)
			
		elseif(resultIsVector3) then
			CombatService.ReplicateRay(firePoint,
				fireRayResult,
				players
			)
		else
			return nil
		end
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
