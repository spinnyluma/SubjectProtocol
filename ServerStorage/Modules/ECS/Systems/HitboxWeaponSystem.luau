const CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local damageHitboxRE = ReplicatedStorage.Assets.Shared.Remotes.Events.DamageHitbox
const Modules = ReplicatedStorage.Modules

const Services = Modules.Services
const Helpers = Modules.Helpers
const Shared = Modules.Shared

const Combat = Services.Combat

const Tool = Helpers.Tool

const Constants = Shared.Constants

const CharacterConfig = require(Constants.CharacterConfig)
const CombatService = require(Combat.CombatService)
const ToolConfig = require(Constants.ToolConfig)
const ToolHelper = require(Tool.ToolHelper)

const HostilitySystemSignals = require("./HostilitySystem/Signals")

const Character = Helpers.Character

const Debug = Helpers.Debug

const Constants = Shared.Constants

const WeaponDataConfig = require(Constants.WeaponDataConfig)
const CharacterHelper = require(Character.CharacterHelper)
const AssertHelper = require(Debug.AssertHelper)

local HitboxWeaponSystem = {}

local MAX_MELEE_DISTANCE = 25

local function ValidateHitboxPacket(player: Player,
	hitboxPacket: WeaponDataConfig.HitboxPacket
)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
			and player:IsA("Player"),
		player,
		"player",
		"ValidateHitboxPacket",
		"Player"
	)
	if(not playerIsValid) then return false end
	local hitboxPacketIsValid = AssertHelper.InvalidArgAssert(
		typeof(hitboxPacket) == "table",
		hitboxPacket,
		"hitboxPacket",
		"ValidateHitboxPacket",
		"table"
	)
	if(not hitboxPacketIsValid) then return false end
	
	
	local objectHit = hitboxPacket.DamageableObjectHit
	if(not objectHit) then return false end
	
	local objectHitIsDamageable = CombatService.IsInstancePartOfDamageableObject(objectHit)
	local objectHitIsCharacter = CollectionService:HasTag(objectHit, CharacterConfig.CHARACTER_TAG_NAME)
	if(not objectHitIsDamageable
		and (not objectHitIsCharacter)) then return false end
	
	local objectHitPrimPart = objectHit.PrimaryPart
	local objectHitPrimPartIsValid = AssertHelper.ExpectedValAssert(
		typeof(objectHitPrimPart) == "Instance"
			and objectHitPrimPart:IsA("BasePart"),
		objectHitPrimPart,
		"objectHitPrimPart",
		"ValidateHitboxPacket",
		"BasePart"
	)
	if(not objectHitPrimPartIsValid) then return false end
	local distanceBetweenInvolvedObjects = player:DistanceFromCharacter(objectHitPrimPart.Position)
	if(distanceBetweenInvolvedObjects > MAX_MELEE_DISTANCE) then return false end
	
	return true
end

local function ValidatePlayer(player: Player)
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
			and player:IsA("Player"),
		player,
		"player",
		"ValidatePlayer",
		"Player"
	)
	if(not playerIsValid) then return false end
	local character = player.Character
	if(not character) then return false end
	local playerIsDead = CharacterHelper.IsCharacterDead(character)
	if(playerIsDead) then return false end
	return true
end

local function ValidateWeapon(tool: Tool, player: Player)
	local toolIsValid = AssertHelper.InvalidArgAssert(
		typeof(tool) == "Instance"
			and tool:IsA("Tool"),
		tool,
		"tool",
		"ValidateWeapon",
		"Tool"
	)
	if(not toolIsValid) then return false end
	local playerIsValid = AssertHelper.InvalidArgAssert(
		typeof(player) == "Instance"
			and player:IsA("Player"),
		player,
		"player",
		"ValidateWeapon",
		"Player"
	)
	if(not playerIsValid) then return false end
	
	local toolType = ToolHelper.GetToolType(tool)
	if(not toolType) then return false end
	
	local toolTypeIsWeapon = ToolConfig.toolTypes[toolType]
	if(not toolTypeIsWeapon) then return false end
	
	local character = player.Character
	if(not character) then return false end
	local toolBelongsToCharacter = ToolHelper.ToolBelongsToCharacter(tool, character)
	if(not toolBelongsToCharacter) then return false end
	
	return true
end

function HitboxWeaponSystem.Initialize()
	damageHitboxRE.OnServerEvent:Connect(function(player: Player, 
		hitboxPacket: WeaponDataConfig.HitboxPacket?
	)
		local hitboxPacketIsValid = type(hitboxPacket) == "table"
		if(not hitboxPacketIsValid) then return end

		local hitboxPacketAllowsDamage = ValidateHitboxPacket(player, hitboxPacket)
		local playerIsValid = ValidatePlayer(player)
		
		if(not hitboxPacketAllowsDamage
			or (not playerIsValid)) then return end
		
		const weapon = hitboxPacket.Weapon
		if(not weapon) then
			return
		end
		const weaponValidated = ValidateWeapon(weapon, player) 
		if(not weaponValidated) then return end
		
		local damageableObjectHit = hitboxPacket.DamageableObjectHit
		local damageableObjectHitIsValid = AssertHelper.ExpectedValAssert(
			typeof(damageableObjectHit) == "Instance"
			and damageableObjectHit:IsA("Model"),
			damageableObjectHit,
			"damageableObjectHit",
			"Model"
		)
		local isDamageable = CombatService.IsInstancePartOfDamageableObject(hitboxPacket.DamageableObjectHit)
		local isCharacter = CollectionService:HasTag(damageableObjectHit, CharacterConfig.CHARACTER_TAG_NAME)
		const toolCombatConfig = ToolConfig.toolCombatConfigs[weapon.Name]
		if(not toolCombatConfig) then return end
		local damage = toolCombatConfig.DamageValue
		if(not damage) then return end
		HostilitySystemSignals.HostilityRequested:Fire(player)
		if(isDamageable) then
			
			CombatService.DamageDamageableObject(damageableObjectHit, damage)
		elseif(isCharacter) then
			CombatService.DamageCharacter(damageableObjectHit, damage)
		end
	end)
end

return HitboxWeaponSystem
