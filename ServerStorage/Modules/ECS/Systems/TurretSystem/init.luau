local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")


local TurretConfig = require(ReplicatedStorage.Modules.Shared.Constants.TurretConfig)
local TurretSystemConfig = require(script.Config)
local ModeConfig = require(ReplicatedStorage.Modules.Shared.Constants.ModeConfig)
local SpatialQueryConfig = require(ReplicatedStorage
	.Modules
	.Shared
	.Constants
	.SpatialQueryConfig)
local CombatServiceConfig = require(ReplicatedStorage.Modules.Services.Combat.CombatService.Config)


local FacilityModeSignals = require(ServerStorage.Modules.ECS.Systems.FacilityModeSystem.Signals)

local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local PlayerHelper = require(ReplicatedStorage.Modules.Helpers.Player.PlayerHelper)
local VectorHelper = require(ReplicatedStorage.Modules.Helpers.Vector.VectorHelper)
local CharacterHelper = require(ReplicatedStorage.Modules.Helpers.Character.CharacterHelper)

local SystemManagerModule = require(ReplicatedStorage.Modules.ECS.SystemManagerModule)

local CombatService = require(ReplicatedStorage
	.Modules
	.Services
	.Combat
	.CombatService
)
local VfxService = require(ReplicatedStorage
	.Modules
	.Services
	.VFX
	.VfxService
)

local CombatServiceSignals = require(ReplicatedStorage.Modules.Services.Combat.CombatService.Signals)

local replicateTurretRotationRE = ReplicatedStorage
	.Assets
	.Shared
	.Remotes
	.Events
	.ReplicateTurretRotation

local TURRET_RAY_LENGTH = 300
local TURRET_SPREAD_RADIUS = 4

local currentTeamsTargeted: {Team?} = {}


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

local function CanTargetPlayer(player: Player): boolean?
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
			and player:IsA("Player"),
		player,
		"player",
		"CanTargetPlayer",
		"Player"
	)
	if(not playerIsValid) then return nil end
	
	
	local playerInTargetedTeam: boolean = table.find(currentTeamsTargeted, player.Team)
	return playerInTargetedTeam ~= nil
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
		
		local playerCanBeTargeted: boolean? = CanTargetPlayer(player)
		
		if(not playerCanBeTargeted) then continue end
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
		print("player is in view of part ", playerIsInViewOfPart)
		if(not playerIsInViewOfPart) then continue end
		local players = Players:GetPlayers()
		
		local fireRayResult: RaycastResult? | Vector3? = FireTurretRay(player, firePoint, params)
		
		local resultIsRaycastResult = typeof(fireRayResult) == "RaycastResult"
		local resultIsVector3 = typeof(fireRayResult) == "Vector3"
		
		
		
		if(resultIsRaycastResult) then
			local resultInstance = fireRayResult.Instance
			local resultInstancePosition = resultInstance.Position
		
			CombatService.ReplicateRay(firePoint,
				fireRayResult.Position,
				players
			)
			
			replicateTurretRotationRE:FireAllClients(turret, fireRayResult.Position)
			
			local character = player.Character
			if(not character) then return end
			--TODO: switch to alive character
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
	local currentMode = SystemManagerModule.GetGlobalGameState("CurrentMode")
	if(currentMode ~= ModeConfig.modes.TurretOverride.Name) then return end
	
	local turrets: {Model?} = CollectionService:GetTagged(TurretConfig.TURRET_TAG_NAME)

	for _, turret in turrets do
		local health = turret:GetAttribute(CombatServiceConfig.HEALTH_ATTR_NAME)
		local healthIsValid = AssertHelper.ExpectedValAssert(
			typeof(health) == "number",
			health,
			"health",
			"number"
		)
		if(not healthIsValid) then continue end
		
		if(health <= 0) then continue end
		local barrel: BasePart? = turret:FindFirstChild("Barrel")
		local barrelIsValid = typeof(barrel) == "Instance"
			and barrel:IsA("BasePart")
		
		if(not barrelIsValid) then continue end
		ShootTurret(turret)
	end
end

local function SetTurretTargetFromMode(newMode: ModeConfig.Mode)
	local newModeIsValid = AssertHelper.InvalidArgAssert(
		ModeConfig.modes[newMode] ~= nil,
		newMode,
		"newMode",
		"SetTurretTargetFromMode",
		"ModeConfig.Mode"
		
	)
	if(not newModeIsValid) then return end
	
	local targetedTeams: {Team?}? = TurretSystemConfig.modeToTurretTargetedTeams[newMode]
	if(not targetedTeams) then return end
	currentTeamsTargeted = targetedTeams
end

local function ExplodeTurret(turret: Model)
	local turretIsValid = AssertHelper.InvalidArgAssert(
		typeof(turret) == "Instance"
			and turret:IsA("Model")
		and CollectionService:HasTag(turret, TurretConfig.TURRET_TAG_NAME),
		turret,
		"turret",
		"ExplodeTurret",
		"Model"
	)
	if(not turretIsValid) then return end
	
	local turretPosition = turret:GetPivot().Position
	
	VfxService.SpawnExplosion({
		BlastPressure = 0,
		BlastRadius = 0,
		DestroyJointRadiusPercent = 0,
		ExplosionType = Enum.ExplosionType.NoCraters,
		Position = turretPosition,
		TimeScale = 1,
		Visible = true
	})
end

local function SpawnFireOnTurret(turret: Model)
	local turretIsValid = AssertHelper.InvalidArgAssert(
		typeof(turret) == "Instance"
			and turret:IsA("Model"),
		turret,
		"turret",
		"SpawnFireOnTurret",
		"Model"
	)
	if(not turretIsValid) then return end
	
	local head = turret:FindFirstChild("Head")
	local headIsValid = AssertHelper.ExpectedValAssert(
		typeof(head) == "Instance"
			and head:IsA("BasePart"),
		head,
		"head",
		"BasePart"
	)
	if(not headIsValid) then return end
	VfxService.SpawnFire({
		Enabled = true,
		TimeScale = 1,
		Size = 8
	}, head)
end

local function HandleTurretDamageRequested(turret: Model,
	damageRequested: number
)
	local turretIsValid = AssertHelper.InvalidArgAssert(
		typeof(turret) == "Instance"
			and turret:IsA("Model"),
		turret,
		"turret",
		"HandleTurretDamageRequested",
		"Model"
	)
	if(not turretIsValid) then return end
	
	local damageRequestedIsValid = AssertHelper.InvalidArgAssert(
		type(damageRequested) == "number",
		damageRequested,
		"damageRequested",
		"HandleTurretDamageRequested",
		"number"
	)
	if(not damageRequestedIsValid) then return end
	
	local currentHealth = turret:GetAttribute(CombatServiceConfig.HEALTH_ATTR_NAME)
	local currentHealthIsValid = AssertHelper.ExpectedValAssert(
		type(currentHealth) == "number",
		currentHealth,
		"currentHealth",
		"number"
	)
	if(not currentHealthIsValid) then return end
	
	if(currentHealth == 0) then
		return
	end 
	local currentMode = SystemManagerModule.GetGlobalGameState("CurrentMode")
	if(not currentMode) then return end
	if(currentMode ~= ModeConfig.modes.TurretOverride.Name) then return end
	local health = CombatService.DamageDamageableObject(turret, damageRequested)
	local healthIsValid = AssertHelper.ExpectedValAssert(
		type(health) == "number",
		health,
		"health",
		"number"
	)
	if(not healthIsValid) then return end

	if(health == 0)	 then
		ExplodeTurret(turret)
		SpawnFireOnTurret(turret)
		task.delay(TurretSystemConfig.TURRET_DOWNTIME, function()
			VfxService.RemoveVfxOnInstance(turret)
			local maxHealth = turret:GetAttribute(CombatServiceConfig.MAX_HEALTH_ATTR_NAME)
			local maxHealthIsValid = AssertHelper.ExpectedValAssert(
				type(maxHealth) == "number",
				maxHealth,
				"maxHealth",
				"number"
			)
			if(not maxHealthIsValid) then return end
			turret:SetAttribute(CombatServiceConfig.HEALTH_ATTR_NAME, maxHealth)
		end)
	end
end


function TurretSystem.Initialize()
	FacilityModeSignals.ModeChanged:Connect(function(newMode: ModeConfig.Mode, oldMode: ModeConfig.Mode)
		SetTurretTargetFromMode(newMode)
	end)
	
	CombatServiceSignals.DamageableObjectDamageRequested:Connect(function(damageableObject: Instance, damageRequested: number)
		local damageableObjectHasTurretTag = CollectionService:HasTag(
			damageableObject,
			TurretConfig.TURRET_TAG_NAME
		)
		if(not damageableObjectHasTurretTag) then return end
		HandleTurretDamageRequested(damageableObject, damageRequested)
	end)
end

return TurretSystem
