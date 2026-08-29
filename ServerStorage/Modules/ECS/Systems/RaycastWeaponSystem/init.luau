local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

const Modules = ReplicatedStorage.Modules
const Assets = ReplicatedStorage.Assets

const Utilities = Modules.Utilities
const Helpers = Modules.Helpers
const ECS = Modules.ECS

const Shared = Assets.Shared

const RaycastWeapon = Helpers.RaycastWeapon
const Time = Helpers.Time
const Tool = Helpers.Tool

const Systems = ECS.Systems

const Remotes = Shared.Remotes

const Events = Remotes.Events

const reloadWeaponRE = Events.ReloadWeapon

const ClientRaycastWeaponConfig = require(Systems.ClientRaycastWeaponSystem.Config)
local HostilitySystemSignals = require(ServerStorage.Modules.ECS.Systems.HostilitySystem.Signals)
local CombatServiceSignals = require(ReplicatedStorage.Modules.Services.Combat.CombatService.Signals)
local CombatServiceConfig = require(ReplicatedStorage.Modules.Services.Combat.CombatService.Config)
const RaycastWeaponHelper = require(RaycastWeapon.RaycastWeaponHelper)
local SpatialQueryConfig = require(ReplicatedStorage.Modules.Shared.Constants.SpatialQueryConfig)
local SpatialQueryHelper  = require(ReplicatedStorage.Modules.Helpers.SpatialQuery.SpatialQueryHelper)
const ClientSoundConfig = require(ReplicatedStorage.Modules.Shared.Constants.Sound.SoundConfig)
local WeaponDataConfig = require(ReplicatedStorage.Modules.Shared.Constants.WeaponDataConfig)
local CharacterConfig = require(ReplicatedStorage.Modules.Shared.Constants.CharacterConfig)
local CharacterHelper = require(ReplicatedStorage.Modules.Helpers.Character.CharacterHelper)
local DataModelHelper = require(ReplicatedStorage.Modules.Helpers.DataModel.DataModelHelper)
local CombatService = require(ReplicatedStorage.Modules.Services.Combat.CombatService)
local AssertHelper = require(ReplicatedStorage.Modules.Helpers.Debug.AssertHelper)
local CombatHelper = require(ServerStorage.Modules.Helpers.Combat.CombatHelper)
local TableHelper = require(ReplicatedStorage.Modules.Helpers.Table.TableHelper)
const TimeHelper = require(Time.TimeHelper)
const ToolHelper = require(Tool.ToolHelper)
const Promise = require(Utilities.Promise)
const t = require(Utilities.t)

local RaycastWeaponConfig = require(script.Config)

const SoundReplicationSystemConfig = require("./SoundReplicationSystem/Config")
const SoundReplicationService = require("../../Services/Sound/SoundReplicationService")
const FirerateService = require("../../Services/Firerate/FirerateService")

local subjectsTeam = Teams.Subjects

local fireRayRE = ReplicatedStorage.Assets.Shared.Remotes.Events.FireRay

local HIT_POSITION_MAGNITUDE_BUFFER = 12

local RaycastWeaponSystem = {}

local fireRateThreads: {[Model]: thread} = {}

local function GetServerRaycastParams(instanceHit: Instance?)
	local instanceHitIsValid = AssertHelper.InvalidArgAssert(
		typeof(instanceHit) == "Instance"
		or typeof(instanceHit) == "nil",
		instanceHit,
		"instanceHit",
		"GetServerOverlapParams",
		"Instance?"
	)
	if not instanceHitIsValid then return end
	
	local raycastParams = RaycastParams.new()
	local staticGeometry = SpatialQueryHelper.GetStaticGeometryInInstance(workspace)
	if(not staticGeometry) then return end
	local includeInstances: {Instance?} = nil
	if(not instanceHit) then
		includeInstances = staticGeometry
	else
		includeInstances = TableHelper.JoinTables({instanceHit}, staticGeometry)
	end
	if(not includeInstances) then return end
	raycastParams.IncludeInstances = includeInstances
	raycastParams.ExcludeInstances = {workspace}
	
	return raycastParams
end

local function GetServerOverlapParams(instanceHit: Instance)
	local instanceHitIsValid = AssertHelper.InvalidArgAssert(
		typeof(instanceHit) == "Instance",
		instanceHit,
		"instanceHit",
		"GetServerOverlapParams",
		"Instance"
	)
	if not instanceHitIsValid then return end
	
	local overlapParams = OverlapParams.new()
	overlapParams.IncludeInstances = {instanceHit}
	overlapParams.ExcludeInstances = {workspace}
	return overlapParams	
end

local function ValidateRay(player: Player, weaponDataConfig: WeaponDataConfig.RaycastPacket)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
			and player:IsA("Player"),
		player,
		"player",
		"ValidateRay",
		"Player"
	)
	if not playerIsValid then return false end
	
	local weaponDataConfigIsValid = type(weaponDataConfig) == "table"
	if not weaponDataConfigIsValid then return false end
	
	local playerCharacter = player.Character
	local playerFromCharacter = Players:GetPlayerFromCharacter(playerCharacter)
	local playerFromCharacterIsValid = typeof(playerFromCharacter) == "Instance"
		and playerFromCharacter:IsA("Player")
	if not playerFromCharacterIsValid then return false end
	
	local origin = weaponDataConfig.Origin
	local originIsValid = typeof(origin) == "Vector3"
	if not originIsValid then return false end
	
	local direction = weaponDataConfig.Direction
	local directionIsValid = typeof(direction) == "Vector3"
	if not directionIsValid then return false end
	
	local endPosition = weaponDataConfig.EndPosition
	local endPositionIsValid = typeof(endPosition) == "Vector3"
	if not endPositionIsValid then return false end
	
	
	local weapon = weaponDataConfig.Weapon
	local weaponIsValid = weapon:IsA("Model")
	if not weaponIsValid then return false end
	
	local instanceHit: Instance? = weaponDataConfig.InstanceHit
	
	local raycastParams = GetServerRaycastParams(instanceHit)
	
	local serverRaycast: RaycastResult? = CombatService.FireRay(
		origin,
		direction, 
		raycastParams
	)
	local serverEndPosition: Vector3? = nil
	local serverRaycastInstance: Instance? = nil
	if serverRaycast then
		serverEndPosition = serverRaycast.Position
		serverRaycastInstance = serverRaycast.Instance
	else
		serverEndPosition = origin + direction
	end
	
	
	local claimedToServerMagnitude = (serverEndPosition - endPosition).Magnitude
	if(claimedToServerMagnitude >= HIT_POSITION_MAGNITUDE_BUFFER)  then
		
		return false
	elseif(instanceHit
		and instanceHit:IsDescendantOf(workspace.DynamicGeometry)) then
		--[[
			Return true because the hit was within margin of error
			and the hit instance was a dynamic instance so the hit is plausible
		]]
		return true	
	
	elseif(serverRaycastInstance == instanceHit) then
		return true
	elseif(not serverRaycastInstance
		and instanceHit) then
		local instanceOverlapParams = GetServerOverlapParams(instanceHit)
		if(not instanceOverlapParams) then return end
		
		local serverInstanceHits: {Instance?} = workspace:GetPartBoundsInRadius(serverEndPosition, 
			HIT_POSITION_MAGNITUDE_BUFFER, 
			instanceOverlapParams
		)
		for _, hitPart in serverInstanceHits do
			if hitPart == instanceHit then
				return true
			end
		end
		return false
	elseif(serverRaycastInstance ~= instanceHit) then
		--[[
			Do not accept the hit 
			because the only case that a server raycast's claimed instance hit and
			a client's claimed instance hit differ and is valid is when
			the server overlaps the client's claimed instance according to 
			HIT_POSITION_MAGNITUDE_BUFFER as the radius.			
		]]
		return false
	else
		return false
	end
end



const function ValidateWeaponCanBeReloaded(weapon: Tool)
	const toolIsValidFn = t.instanceIsA("Tool")
	const weaponIsValid, weaponInvalidReason = toolIsValidFn(weapon)
	if(not weaponIsValid) then 
		AssertHelper.Warn(weaponInvalidReason)
		return
	end
	
	const weaponHasAmmoAttribute: boolean = RaycastWeaponHelper.HasAmmoAttribute(weapon)
	if(not weaponHasAmmoAttribute) then
		return false
	end

	const weaponAmmoAttribute: number? = weapon:GetAttribute("A_Ammo")
	const maxAmmoAttribute: number? = weapon:GetAttribute("A_MaxAmmo")
	const numberMin0Fn= t.numberMin(0)
	const maxAmmoAttributeIsValid, maxAmmoAttributeInvalidReason = numberMin0Fn(maxAmmoAttribute)
	if(not maxAmmoAttributeIsValid) then
		return false
	end
	const numberMaxAmmoFn = t.numberMaxExclusive(0, maxAmmoAttribute)
	const weaponAmmoAttributeConstrainedValid, ammoConstrainedInvalidReason = numberMaxAmmoFn(weaponAmmoAttribute)
	if(not weaponAmmoAttributeConstrainedValid) then
		return false
	end
	
	return true
	
end

local function DamageCharacter(instance: Instance)
	local instanceIsValid = AssertHelper.InvalidArgAssert(
		typeof(instance) == "Instance",
		instance,
		"instance",
		"DamagePlayer",
		"Instance"
	)
	if not instanceIsValid then return end
	
	
	local character = DataModelHelper.GetRootParentWithTag(instance, CharacterConfig.CHARACTER_TAG_NAME)
	local characterIsValid = AssertHelper.ExpectedValAssert(
		typeof(character) == "Instance"
			and character:IsA("Model"),
		character,
		"character",
		"Model"
	)
	if not characterIsValid then return end
	
	local humanoid = CharacterHelper.GetHumanoidFromCharacter(character)
	if(not humanoid) then return end
	
	humanoid:TakeDamage(7)
end

const function SetAmmoAmount(weapon: Tool, ammo: number)
	const toolIsValidFn = t.instanceIsA("Tool")
	const weaponIsValid, weaponInvalidReason = toolIsValidFn(weapon)
	if(not weaponIsValid) then 
		AssertHelper.Warn(weaponInvalidReason)
		return
	end

	weapon:SetAttribute("A_Ammo", ammo)
end

const function ValidateWeaponReload(playerFiring: Player, weapon: Tool)
	const playerIsValidFn = t.instanceIsA("Player")
	const playerIsValid, playerInvalidReason = playerIsValidFn(playerFiring)
	if(not playerIsValid) then 
		AssertHelper.Warn(playerInvalidReason)
		return false
	end
	
	const toolIsValidFn = t.instanceIsA("Tool")
	const weaponIsValid, weaponInvalidReason = toolIsValidFn(weapon)
	if(not weaponIsValid) then 
		AssertHelper.Warn(weaponInvalidReason)
		return false
	end
	
	const weaponCanBeReloaded = ValidateWeaponCanBeReloaded(weapon)
	if(not weaponCanBeReloaded) then
		return false
	end
	
	const playerCharacter = playerFiring.Character
	if(not playerCharacter) then return false end
	const toolBelongsToPlayer = ToolHelper.ToolBelongsToCharacter(weapon, playerCharacter)
	if(not toolBelongsToPlayer) then
		return false
	end
	
	return true
end

const function ReloadWeapon(weapon: Tool)
	const toolIsValidFn = t.instanceIsA("Tool")
	const weaponIsValid, weaponInvalidReason = toolIsValidFn(weapon)
	if(not weaponIsValid) then 
		AssertHelper.Warn(weaponInvalidReason)
		return
	end
	
	const maxAmmoAttribute = weapon:GetAttribute("A_MaxAmmo")
	const numberMin0Fn= t.numberMin(0)
	local maxAmmoAttributeIsValid, maxAmmoAttributeInvalidReason = numberMin0Fn(maxAmmoAttribute)
	if(not maxAmmoAttributeIsValid) then
		AssertHelper.Warn(maxAmmoAttributeInvalidReason)
		return
	end
	
	weapon:SetAttribute("A_Ammo", maxAmmoAttribute)
end


function RaycastWeaponSystem.Initialize()
	reloadWeaponRE.OnServerEvent:Connect(function(player: Player, weapon: Tool)
		const playerIsValidFn = t.instanceIsA("Player")
		local playerIsValid, playerInvalidReason = playerIsValidFn(player)
		if(not playerIsValid) then
			return
		end
		
		const toolIsValidFn = t.instanceIsA("Tool")
		const weaponIsValid, weaponInvalidReason = toolIsValidFn(weapon)
		if(not weaponIsValid) then
			return
		end		
		
		const reloadTime: number? = weapon:GetAttribute(ClientRaycastWeaponConfig.RELOAD_ATTR_NAME)
		const reloadTimeIsValid, reloadTimeInvalidReason = t.number(reloadTime)
		if(not reloadTimeIsValid) then
			AssertHelper.Warn(reloadTimeInvalidReason)
			return
		end
		
		Promise.try(function()
			TimeHelper.CreateCountdownInSeconds(reloadTime)
			ReloadWeapon(weapon)
		end)
			:catch(function(err)
				AssertHelper.Warn(tostring(err))
			end)
	end)
	
	
	fireRayRE.OnServerEvent:Connect(function(player: Player, weaponDataConfig: WeaponDataConfig.RaycastPacket)
		if(not weaponDataConfig) then return end
		local rayIsValid = ValidateRay(player, weaponDataConfig)
		local playerCharacter = player.Character
		if(not playerCharacter) then return end
		local playerCharacterIsDead = CharacterHelper.IsCharacterDead(playerCharacter)
		if(not rayIsValid
			or (playerCharacterIsDead)) then
			return
		end
		
			

		-- Check and deduct ammo
		local weapon = weaponDataConfig.Weapon
		if(typeof(weapon) == "Instance" and weapon:IsA("Model")) then
			
			
			local hasAmmo = RaycastWeaponHelper.HasAmmoAttribute(weapon)
			if(hasAmmo) then
				local currentAmmo = weapon:GetAttribute("A_Ammo")
				if(typeof(currentAmmo) == "number" and currentAmmo > 0) then
					weapon:SetAttribute("A_Ammo", currentAmmo - 1)
				else
					return -- No ammo left
				end
			end
		end
		local instanceHit = weaponDataConfig.InstanceHit
		local instanceHitIsValid = typeof(instanceHit) == "Instance"
			and instanceHit:IsA("BasePart")
		
		if(instanceHitIsValid) then
			local weapon = weaponDataConfig.Weapon
			local weaponIsValid = AssertHelper.ExpectedValAssert(
				typeof(weapon) == "Instance"
					and weapon:IsA("Model"),
				weapon,
				"weapon",
				"Model"
			)
			if(not weaponIsValid) then return end

			local firePoint: BasePart? = weapon.FirePoint
			local firePointIsValid = AssertHelper.ExpectedValAssert(
				typeof(firePoint) == "Instance"
					and firePoint:IsA("BasePart"),
				firePoint,
				"firePoint",
				"BasePart"
			)
			if(not firePointIsValid) then return end
			local endPosition = weaponDataConfig.EndPosition
			local endPositionIsValid = AssertHelper.ExpectedValAssert(
				typeof(endPosition) == "Vector3",
				endPosition,
				"endPosition",
				"Vector3"
			)
			if(not endPositionIsValid) then return end


			local otherPlayers = DataModelHelper.InvertSelection({player})
			if(not otherPlayers) then return end
			
			const weaponPivot = weapon:GetPivot()
			if(not weaponPivot) then return end

				
			local playerTeam = player.Team 
			
			const fireRate = weapon:GetAttribute(ClientRaycastWeaponConfig.FIRE_RATE_ATTR_NAME)
			const fireRateIsValid, fireRateInvalidReason = t.number(fireRate)
			if(not fireRateIsValid) then 
				AssertHelper.Warn(fireRateInvalidReason)
				return 
			end
			
			const fireStartTime = weaponDataConfig.ShootStartTime
			if(not fireStartTime) then return end
			const weaponInCooldown = FirerateService.IsWeaponInCooldown(weaponDataConfig.Weapon, fireRate)
			if(weaponInCooldown) then
				return
			else
				FirerateService.AddFirerateStartTime(weapon, fireStartTime, fireRate)
			end
			
			CombatService.ReplicateRay(firePoint, endPosition, otherPlayers, {
				Team = playerTeam
			})
			SoundReplicationService.ReplicateSound(otherPlayers, ClientSoundConfig.clientSoundConfigs.Gun.PistolGunshot)
			
			
			local instanceBelongsToCharacter = CharacterHelper.IsPartInCharacterModel(instanceHit)
			local instanceBelongsToDamageableObject = CombatService.IsInstancePartOfDamageableObject(instanceHit)
			
				
			if(instanceBelongsToCharacter) then
				local playerCanAttack = CombatHelper.PlayerCanAttackCharacter(player, instanceHit)
				if(not playerCanAttack) then return end
				DamageCharacter(instanceHit)
				if(player.Team == subjectsTeam) then
					HostilitySystemSignals.HostilityRequested:Fire(player)
				end
			elseif(instanceBelongsToDamageableObject) then
				local rootParent = DataModelHelper.GetRootParentWithTag(instanceHit, 
					CombatServiceConfig.DAMAGEABLE_TAG_NAME
				)
				local rootParentIsValid = AssertHelper.ExpectedValAssert(
					typeof(rootParent) == "Instance",
					rootParent,
					"rootParent",
					"Instance"
				)
				if(not rootParentIsValid) then return end
				CombatServiceSignals.DamageableObjectDamageRequested:Fire(rootParent, 7)				
			end
		end
	end)
end

return RaycastWeaponSystem
